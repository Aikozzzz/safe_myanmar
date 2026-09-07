package org.safemyanmar.mobile.ai

import java.io.ByteArrayInputStream
import java.io.File
import java.io.InputStream
import java.security.MessageDigest
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class BundledAiModelProvisionerTest {
    private val temporaryDirectories = mutableListOf<File>()

    @After
    fun removeTemporaryDirectories() {
        temporaryDirectories.forEach(File::deleteRecursively)
    }

    @Test
    fun installsValidatedModelPairsIntoPrivateDirectory() {
        val onnx = byteArrayOf(1, 2, 3)
        val gemma = byteArrayOf(4, 5, 6)
        val target = temporaryDirectory()

        BundledAiModelProvisioner(
            TestAssetSource(
                mapOf(
                    "ai/intent_classifier.onnx" to onnx,
                    "ai/intent_classifier.json" to onnxManifest(onnx),
                    "ai/gemma3-1b-it-int4.litertlm" to gemma,
                    "ai/gemma3-1b-it-int4.json" to gemmaManifest(gemma),
                ),
            ),
            target,
            ::validTestArtifact,
        ).provision()

        assertArrayEquals(onnx, File(target, "intent_classifier.onnx").readBytes())
        assertArrayEquals(gemma, File(target, "gemma3-1b-it-int4.litertlm").readBytes())
        assertTrue(File(target, "intent_classifier.json").isFile)
        assertTrue(File(target, "gemma3-1b-it-int4.json").isFile)
        assertFalse(File(target, ".bundle-intent_classifier.onnx").exists())
        assertFalse(File(target, ".bundle-gemma3-1b-it-int4.litertlm").exists())
    }

    @Test
    fun keepsAnExistingCurrentPairWithoutReinstallingIt() {
        val onnx = byteArrayOf(7, 8, 9)
        val target = temporaryDirectory()
        target.mkdirs()
        File(target, "intent_classifier.onnx").writeBytes(onnx)
        File(target, "intent_classifier.json").writeBytes(onnxManifest(onnx))

        BundledAiModelProvisioner(
            TestAssetSource(
                mapOf(
                    "ai/intent_classifier.onnx" to onnx,
                    "ai/intent_classifier.json" to onnxManifest(onnx),
                ),
            ),
            target,
            ::validTestArtifact,
        ).provision()

        assertArrayEquals(onnx, File(target, "intent_classifier.onnx").readBytes())
        assertTrue(File(target, "intent_classifier.json").isFile)
    }

    @Test
    fun ignoresPartialOrInvalidAssetPairs() {
        val target = temporaryDirectory()
        val partialSource = TestAssetSource(
            mapOf("ai/intent_classifier.onnx" to byteArrayOf(1)),
        )
        BundledAiModelProvisioner(partialSource, target, ::validTestArtifact).provision()
        assertFalse(File(target, "intent_classifier.onnx").exists())

        val invalidSource = TestAssetSource(
            mapOf(
                "ai/intent_classifier.onnx" to byteArrayOf(1, 2),
                "ai/intent_classifier.json" to onnxManifest(byteArrayOf(9, 9)),
            ),
        )
        BundledAiModelProvisioner(invalidSource, target, ::validTestArtifact).provision()
        assertFalse(File(target, "intent_classifier.onnx").exists())
        assertFalse(File(target, "intent_classifier.json").exists())
    }

    private fun temporaryDirectory(): File =
        File(
            System.getProperty("java.io.tmpdir"),
            "safemyanmar-ai-${System.nanoTime()}-${temporaryDirectories.size}",
        ).also {
            temporaryDirectories += it
        }

    private fun onnxManifest(model: ByteArray): ByteArray =
        """
        {
          "schemaVersion": 1,
          "modelVersion": "test-onnx-v1",
          "sha256": "${sha256(model)}",
          "featureContract": "normalized_bag_of_words_v1",
          "outputContract": "probabilities_v1",
          "inputName": "input",
          "outputName": "output",
          "vocabulary": ["earthquake"],
          "labels": ["unknown", "fire"],
          "executionProvider": "cpu"
        }
        """.trimIndent().toByteArray()

    private fun gemmaManifest(model: ByteArray): ByteArray =
        """
        {
          "schemaVersion": 1,
          "modelVersion": "test-gemma-v1",
          "sha256": "${sha256(model)}",
          "modelId": "gemma3-1b-it-int4.litertlm"
        }
        """.trimIndent().toByteArray()

    private fun sha256(bytes: ByteArray): String =
        MessageDigest.getInstance("SHA-256").digest(bytes).joinToString("") {
            "%02x".format(it)
        }

    @Suppress("UNUSED_PARAMETER")
    private fun validTestArtifact(
        model: File,
        manifest: File,
        kind: BundledAiArtifactKind,
    ): Boolean {
        if (!model.isFile || !manifest.isFile) return false
        return manifest.readText().contains(
            "\"sha256\": \"${sha256(model.readBytes())}\"",
        )
    }

    private class TestAssetSource(
        private val values: Map<String, ByteArray>,
    ) : BundledAiAssetSource {
        override fun list(path: String): Set<String> =
            values.keys
                .filter { it.startsWith("$path/") }
                .map { it.removePrefix("$path/") }
                .toSet()

        override fun open(path: String): InputStream {
            val bytes = values[path] ?: throw IllegalArgumentException("Missing test asset: $path")
            return ByteArrayInputStream(bytes)
        }
    }
}
