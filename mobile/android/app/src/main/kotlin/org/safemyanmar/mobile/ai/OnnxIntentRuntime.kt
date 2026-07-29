package org.safemyanmar.mobile.ai

import ai.onnxruntime.OnnxJavaType
import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtLoggingLevel
import ai.onnxruntime.OrtSession
import ai.onnxruntime.TensorInfo
import android.os.Build
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.Locale
import java.util.concurrent.atomic.AtomicReference

internal class OnnxIntentRuntime(private val directory: File) : AutoCloseable {
    private val model = File(directory, MODEL_FILE)
    private val manifest = File(directory, MANIFEST_FILE)
    private val activeRunOptions = AtomicReference<OrtSession.RunOptions?>()
    private var environment: OrtEnvironment? = null
    private var loaded: LoadedSession? = null

    fun capability(): Map<String, Any?> =
        when (val validation = ModelArtifactValidator.validateOnnx(model, manifest)) {
            is ArtifactValidation.Invalid -> capability(false, validation.reason)
            is ArtifactValidation.Valid -> capability(
                true,
                modelVersion = validation.metadata.base.modelVersion,
            )
        }

    fun classify(text: String): Map<String, Any?> {
        if (text.isBlank() || text.length > MAX_INPUT_CHARACTERS) {
            return error(INVALID_REQUEST)
        }
        val runtime = loaded ?: when (val validation = ModelArtifactValidator.validateOnnx(model, manifest)) {
            is ArtifactValidation.Invalid -> return unavailable(validation.reason)
            is ArtifactValidation.Valid -> try {
                createSession(validation.metadata).also { loaded = it }
            } catch (_: InvalidModelException) {
                return unavailable(MODEL_INVALID)
            } catch (_: Exception) {
                return error(RUNTIME_ERROR)
            }
        }

        return try {
            val features = encode(text, runtime.metadata.vocabulary)
            val bytes = ByteBuffer.allocateDirect(features.size * Float.SIZE_BYTES)
                .order(ByteOrder.nativeOrder())
            val buffer = bytes.asFloatBuffer()
            buffer.put(features)
            buffer.flip()
            OnnxTensor.createTensor(
                requireNotNull(environment),
                buffer,
                longArrayOf(1, features.size.toLong()),
            ).use { tensor ->
                OrtSession.RunOptions().use { runOptions ->
                    runOptions.setLogLevel(OrtLoggingLevel.ORT_LOGGING_LEVEL_FATAL)
                    activeRunOptions.set(runOptions)
                    try {
                        runtime.session.run(
                            mapOf(runtime.metadata.inputName to tensor),
                            setOf(runtime.metadata.outputName),
                            runOptions,
                        ).use { result ->
                            val output = result.get(runtime.metadata.outputName).orElse(null)
                                as? OnnxTensor ?: throw InvalidModelException()
                            val scores = output.floatBuffer
                            if (scores == null || scores.remaining() != runtime.metadata.labels.size) {
                                throw InvalidModelException()
                            }
                            val values = FloatArray(scores.remaining())
                            scores.get(values)
                            if (values.any { !it.isFinite() || it < 0f || it > 1f }) {
                                throw InvalidModelException()
                            }
                            if (values.sum() !in 0.99f..1.01f) throw InvalidModelException()
                            val index = values.indices.maxBy { values[it] }
                            success(
                                mapOf(
                                    "intent" to runtime.metadata.labels[index],
                                    "confidence" to values[index].toDouble(),
                                    "tier" to 2,
                                ),
                            )
                        }
                    } finally {
                        activeRunOptions.compareAndSet(runOptions, null)
                    }
                }
            }
        } catch (_: InvalidModelException) {
            unavailable(MODEL_INVALID)
        } catch (_: Exception) {
            error(RUNTIME_ERROR)
        }
    }

    fun cancel(): Boolean {
        val runOptions = activeRunOptions.get() ?: return false
        return try {
            runOptions.setTerminate(true)
            true
        } catch (_: Exception) {
            false
        }
    }

    override fun close() {
        cancel()
        loaded?.let { runtime ->
            try {
                runtime.session.close()
            } catch (_: Exception) {
                // Resource is already unusable; never expose native details.
            }
            try {
                runtime.options.close()
            } catch (_: Exception) {
                // Resource is already unusable; never expose native details.
            }
        }
        loaded = null
        try {
            environment?.close()
        } catch (_: Exception) {
            // The bridge is being disposed and cannot safely reuse the environment.
        }
        environment = null
    }

    private fun createSession(metadata: OnnxModelMetadata): LoadedSession {
        val env = environment ?: OrtEnvironment.getEnvironment().also { environment = it }
        val preferredProvider = safeProvider(metadata)
        val preferredOptions = sessionOptions(preferredProvider)
        val session = try {
            env.createSession(model.absolutePath, preferredOptions)
        } catch (failure: Exception) {
            preferredOptions.close()
            if (preferredProvider == "cpu") throw InvalidModelException(failure)
            val cpuOptions = sessionOptions("cpu")
            var cpuSession: OrtSession? = null
            try {
                cpuSession = env.createSession(model.absolutePath, cpuOptions)
                validateSession(cpuSession, metadata)
                return LoadedSession(cpuSession, cpuOptions, metadata)
            } catch (cpuFailure: Exception) {
                try {
                    cpuSession?.close()
                } catch (_: Exception) {
                    // Session construction failed and no reusable resource remains.
                }
                cpuOptions.close()
                throw InvalidModelException(cpuFailure)
            }
        }
        try {
            validateSession(session, metadata)
        } catch (failure: Exception) {
            session.close()
            preferredOptions.close()
            throw InvalidModelException(failure)
        }
        return LoadedSession(session, preferredOptions, metadata)
    }

    private fun sessionOptions(provider: String): OrtSession.SessionOptions =
        OrtSession.SessionOptions().apply {
            setSessionLogLevel(OrtLoggingLevel.ORT_LOGGING_LEVEL_FATAL)
            setOptimizationLevel(OrtSession.SessionOptions.OptLevel.ALL_OPT)
            setIntraOpNumThreads(Runtime.getRuntime().availableProcessors().coerceIn(1, 4))
            when (provider) {
                "nnapi" -> addNnapi()
                "xnnpack" -> addXnnpack(mapOf("intra_op_num_threads" to "2"))
            }
        }

    private fun safeProvider(metadata: OnnxModelMetadata): String {
        if (!metadata.acceleratorValidated) return "cpu"
        return when (metadata.executionProvider) {
            "nnapi" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) "nnapi" else "cpu"
            "xnnpack" -> if (Build.SUPPORTED_64_BIT_ABIS.isNotEmpty()) "xnnpack" else "cpu"
            else -> "cpu"
        }
    }

    private fun validateSession(session: OrtSession, metadata: OnnxModelMetadata) {
        if (session.numInputs != 1L || session.numOutputs != 1L) throw InvalidModelException()
        val input = session.inputInfo[metadata.inputName]?.info as? TensorInfo
            ?: throw InvalidModelException()
        val output = session.outputInfo[metadata.outputName]?.info as? TensorInfo
            ?: throw InvalidModelException()
        if (input.type != OnnxJavaType.FLOAT || output.type != OnnxJavaType.FLOAT) {
            throw InvalidModelException()
        }
        if (!input.shape.matches(metadata.vocabulary.size) ||
            !output.shape.matches(metadata.labels.size)
        ) {
            throw InvalidModelException()
        }
    }

    private fun encode(text: String, vocabulary: List<String>): FloatArray {
        val index = vocabulary.withIndex().associate { it.value to it.index }
        val features = FloatArray(vocabulary.size)
        val tokens = text.lowercase(Locale.ROOT)
            .split(TOKEN_SEPARATOR)
            .filter { it.isNotBlank() }
            .take(MAX_TOKENS)
        if (tokens.isEmpty()) return features
        tokens.forEach { token -> index[token]?.let { features[it] += 1f / tokens.size } }
        return features
    }

    private fun LongArray.matches(width: Int): Boolean =
        size == 2 && (this[0] == 1L || this[0] == -1L) && this[1] == width.toLong()

    private data class LoadedSession(
        val session: OrtSession,
        val options: OrtSession.SessionOptions,
        val metadata: OnnxModelMetadata,
    )

    private class InvalidModelException(cause: Throwable? = null) : Exception(cause)

    companion object {
        const val MODEL_FILE = "intent_classifier.onnx"
        const val MANIFEST_FILE = "intent_classifier.json"
        private const val MAX_INPUT_CHARACTERS = 1_000
        private const val MAX_TOKENS = 256
        private val TOKEN_SEPARATOR = Regex("[^\\p{L}\\p{N}_]+")
    }
}

internal fun capability(
    available: Boolean,
    reason: String? = null,
    modelVersion: String? = null,
): Map<String, Any?> = mapOf(
    "available" to available,
    "reason" to reason,
    "modelVersion" to modelVersion,
)

internal fun success(value: Map<String, Any?> = emptyMap()): Map<String, Any?> =
    mapOf("status" to "success") + value

internal fun unavailable(reason: String): Map<String, Any?> =
    mapOf("status" to "unavailable", "reason" to reason)

internal fun error(reason: String): Map<String, Any?> =
    mapOf("status" to "error", "reason" to reason)
