package org.safemyanmar.mobile.ai

import java.io.File
import java.io.FileOutputStream
import java.io.InputStream

internal interface BundledAiAssetSource {
    fun list(path: String): Set<String>

    fun open(path: String): InputStream
}

internal enum class BundledAiArtifactKind {
    ONNX,
    LITERTLM,
}

/** Copies build-time Android assets into the private paths consumed by the runtimes. */
internal class BundledAiModelProvisioner(
    private val assets: BundledAiAssetSource,
    private val targetDirectory: File,
    private val validator: (File, File, BundledAiArtifactKind) -> Boolean = { model, manifest, kind ->
        when (kind) {
            BundledAiArtifactKind.ONNX -> ModelArtifactValidator.validateOnnx(model, manifest)
            BundledAiArtifactKind.LITERTLM -> ModelArtifactValidator.validateLiteRt(model, manifest)
        } is ArtifactValidation.Valid
    },
) {
    fun provision() {
        val assetNames = try {
            assets.list(ASSET_DIRECTORY)
        } catch (_: Exception) {
            return
        }
        if (assetNames.isEmpty()) return
        if (!targetDirectory.exists() && !targetDirectory.mkdirs()) return
        if (!targetDirectory.isDirectory) return

        MODEL_PAIRS.forEach { pair ->
            if (pair.modelFile !in assetNames || pair.manifestFile !in assetNames) return@forEach
            installIfRequired(pair)
        }
    }

    private fun installIfRequired(pair: ModelPair) {
        val destinationModel = File(targetDirectory, pair.modelFile)
        val destinationManifest = File(targetDirectory, pair.manifestFile)
        if (isCurrent(pair, destinationModel, destinationManifest)) return

        val stagingDirectory = File(targetDirectory, ".bundle-${pair.modelFile}")
        stagingDirectory.deleteRecursively()
        if (!stagingDirectory.mkdirs()) return

        val stagedModel = File(stagingDirectory, pair.modelFile)
        val stagedManifest = File(stagingDirectory, pair.manifestFile)
        try {
            copyAsset("$ASSET_DIRECTORY/${pair.modelFile}", stagedModel)
            copyAsset("$ASSET_DIRECTORY/${pair.manifestFile}", stagedManifest)
            if (!isValid(pair, stagedModel, stagedManifest)) return

            replace(stagedModel, destinationModel)
            replace(stagedManifest, destinationManifest)
            if (!isValid(pair, destinationModel, destinationManifest)) {
                destinationModel.delete()
                destinationManifest.delete()
            }
        } catch (_: Exception) {
            // The next app start can retry. Invalid or partial pairs remain unusable.
            destinationModel.delete()
            destinationManifest.delete()
        } finally {
            stagingDirectory.deleteRecursively()
        }
    }

    private fun isCurrent(
        pair: ModelPair,
        model: File,
        manifest: File,
    ): Boolean {
        if (!isValid(pair, model, manifest)) return false
        return try {
            val assetManifest = assets.open("$ASSET_DIRECTORY/${pair.manifestFile}").use {
                it.readBytes()
            }
            assetManifest.contentEquals(manifest.readBytes())
        } catch (_: Exception) {
            false
        }
    }

    private fun isValid(pair: ModelPair, model: File, manifest: File): Boolean =
        validator(model, manifest, pair.kind)

    private fun copyAsset(assetPath: String, destination: File) {
        assets.open(assetPath).use { input ->
            FileOutputStream(destination).use { output ->
                input.copyTo(output, COPY_BUFFER_SIZE)
            }
        }
    }

    private fun replace(source: File, destination: File) {
        if (destination.exists() && !destination.delete()) {
            error("Unable to replace bundled AI artifact")
        }
        if (!source.renameTo(destination)) {
            error("Unable to install bundled AI artifact")
        }
    }

    private data class ModelPair(
        val modelFile: String,
        val manifestFile: String,
        val kind: BundledAiArtifactKind,
    )

    companion object {
        private const val ASSET_DIRECTORY = "ai"
        private const val COPY_BUFFER_SIZE = 1024 * 1024
        private val MODEL_PAIRS =
            listOf(
                ModelPair(
                    OnnxIntentRuntime.MODEL_FILE,
                    OnnxIntentRuntime.MANIFEST_FILE,
                    BundledAiArtifactKind.ONNX,
                ),
                ModelPair(
                    GemmaRewriteRuntime.MODEL_FILE,
                    GemmaRewriteRuntime.MANIFEST_FILE,
                    BundledAiArtifactKind.LITERTLM,
                ),
            )
    }
}
