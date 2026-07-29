package org.safemyanmar.mobile.ai

import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileInputStream
import java.security.MessageDigest

internal const val MODEL_MISSING = "model_missing"
internal const val MODEL_INVALID = "model_invalid"
internal const val RUNTIME_ERROR = "runtime_error"
internal const val UNSUPPORTED = "unsupported"
internal const val INSUFFICIENT_RESOURCES = "insufficient_resources"
internal const val INVALID_REQUEST = "invalid_request"
internal const val CRITICAL_INTENT = "critical_intent"

internal data class BaseModelMetadata(
    val modelVersion: String,
    val sha256: String,
)

internal data class OnnxModelMetadata(
    val base: BaseModelMetadata,
    val inputName: String,
    val outputName: String,
    val vocabulary: List<String>,
    val labels: List<String>,
    val executionProvider: String,
    val acceleratorValidated: Boolean,
)

internal sealed interface ArtifactValidation<out T> {
    data class Valid<T>(val metadata: T) : ArtifactValidation<T>
    data class Invalid(val reason: String) : ArtifactValidation<Nothing>
}

internal object ModelArtifactValidator {
    private val sha256Pattern = Regex("^[a-fA-F0-9]{64}$")
    private val versionPattern = Regex("^[A-Za-z0-9._-]{1,64}$")
    private val nodeNamePattern = Regex("^[A-Za-z0-9._/-]{1,128}$")

    /**
     * Schema 1 requires modelVersion, sha256, node names, unique labels/vocabulary,
     * normalized_bag_of_words_v1 features, and probabilities_v1 output.
     */
    fun validateOnnx(model: File, manifest: File): ArtifactValidation<OnnxModelMetadata> {
        if (!model.isFile || !manifest.isFile) return ArtifactValidation.Invalid(MODEL_MISSING)
        return try {
            if (!hasFixedParent(model, manifest)) return ArtifactValidation.Invalid(MODEL_INVALID)
            val json = readManifest(manifest)
            val base = parseBase(json)
            if (json.getString("featureContract") != "normalized_bag_of_words_v1") {
                return ArtifactValidation.Invalid(MODEL_INVALID)
            }
            if (json.getString("outputContract") != "probabilities_v1") {
                return ArtifactValidation.Invalid(MODEL_INVALID)
            }
            val inputName = json.getString("inputName")
            val outputName = json.getString("outputName")
            val vocabulary = json.getJSONArray("vocabulary").strings(1, 16_384)
            val labels = json.getJSONArray("labels").strings(2, 128)
            val provider = json.optString("executionProvider", "cpu").lowercase()
            if (!nodeNamePattern.matches(inputName) || !nodeNamePattern.matches(outputName)) {
                return ArtifactValidation.Invalid(MODEL_INVALID)
            }
            if (vocabulary.toSet().size != vocabulary.size || labels.toSet().size != labels.size) {
                return ArtifactValidation.Invalid(MODEL_INVALID)
            }
            if (vocabulary.any { it != it.lowercase() || it.length > 80 } ||
                labels.any { !versionPattern.matches(it) }
            ) {
                return ArtifactValidation.Invalid(MODEL_INVALID)
            }
            if (provider !in setOf("cpu", "nnapi", "xnnpack")) {
                return ArtifactValidation.Invalid(MODEL_INVALID)
            }
            if (!checksumMatches(model, base.sha256)) {
                return ArtifactValidation.Invalid(MODEL_INVALID)
            }
            ArtifactValidation.Valid(
                OnnxModelMetadata(
                    base,
                    inputName,
                    outputName,
                    vocabulary,
                    labels,
                    provider,
                    json.optBoolean("acceleratorValidated", false),
                ),
            )
        } catch (_: Exception) {
            ArtifactValidation.Invalid(MODEL_INVALID)
        }
    }

    /** Schema 1 requires modelId, modelVersion, and the exact model SHA-256. */
    fun validateLiteRt(model: File, manifest: File): ArtifactValidation<BaseModelMetadata> {
        if (!model.isFile || !manifest.isFile) return ArtifactValidation.Invalid(MODEL_MISSING)
        return try {
            if (!hasFixedParent(model, manifest)) return ArtifactValidation.Invalid(MODEL_INVALID)
            val json = readManifest(manifest)
            val base = parseBase(json)
            if (json.getString("modelId") != "gemma3-1b-it-int4.litertlm") {
                return ArtifactValidation.Invalid(MODEL_INVALID)
            }
            if (!checksumMatches(model, base.sha256)) {
                return ArtifactValidation.Invalid(MODEL_INVALID)
            }
            ArtifactValidation.Valid(base)
        } catch (_: Exception) {
            ArtifactValidation.Invalid(MODEL_INVALID)
        }
    }

    private fun hasFixedParent(model: File, manifest: File): Boolean {
        val parent = model.parentFile?.canonicalFile ?: return false
        return model.canonicalFile.parentFile == parent && manifest.canonicalFile.parentFile == parent
    }

    private fun readManifest(file: File): JSONObject {
        if (file.length() !in 2..1_000_000) throw IllegalArgumentException()
        return JSONObject(file.readText(Charsets.UTF_8))
    }

    private fun parseBase(json: JSONObject): BaseModelMetadata {
        if (json.getInt("schemaVersion") != 1) throw IllegalArgumentException()
        val version = json.getString("modelVersion")
        val sha256 = json.getString("sha256")
        if (!versionPattern.matches(version) || !sha256Pattern.matches(sha256)) {
            throw IllegalArgumentException()
        }
        return BaseModelMetadata(version, sha256.lowercase())
    }

    private fun checksumMatches(file: File, expected: String): Boolean {
        val digest = MessageDigest.getInstance("SHA-256")
        FileInputStream(file).buffered().use { input ->
            val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
            while (true) {
                val read = input.read(buffer)
                if (read < 0) break
                digest.update(buffer, 0, read)
            }
        }
        return MessageDigest.isEqual(digest.digest(), expected.hexToBytes())
    }

    private fun String.hexToBytes(): ByteArray =
        chunked(2).map { it.toInt(16).toByte() }.toByteArray()

    private fun JSONArray.strings(minimum: Int, maximum: Int): List<String> {
        if (length() !in minimum..maximum) throw IllegalArgumentException()
        return List(length()) { index -> getString(index) }
    }
}
