package org.safemyanmar.mobile.ai

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import java.io.File
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

class NativeAiBridge(context: Context) : MethodChannel.MethodCallHandler, AutoCloseable {
    private val modelDirectory = File(context.filesDir, "ai")
    private val onnx = OnnxIntentRuntime(modelDirectory)
    private val gemma = GemmaRewriteRuntime(context, modelDirectory)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val cleanupScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val runtimeLock = Mutex()
    private val activeOperation = AtomicReference<Job?>()
    private val disposed = AtomicBoolean(false)
    private var shutdownJob: Job? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "capabilities" -> launchOperation(result) {
                success(mapOf("tier2" to onnx.capability(), "tier3" to gemma.capability()))
            }
            "classifyIntent" -> launchOperation(result) {
                val text = call.argument<String>("text") ?: return@launchOperation error(INVALID_REQUEST)
                runtimeLock.withLock { onnx.classify(text) }
            }
            "initializeGemma" -> launchOperation(result) {
                runtimeLock.withLock { gemma.initialize() }
            }
            "rewriteVerifiedContent" -> launchOperation(result) {
                runtimeLock.withLock { gemma.rewrite(call.arguments as? Map<*, *>) }
            }
            "answerQuestion" -> launchOperation(result) {
                runtimeLock.withLock { gemma.answer(call.arguments as? Map<*, *>) }
            }
            "cancel" -> launchUntracked(result) {
                val nativeCancelled = onnx.cancel() or gemma.cancel()
                success(mapOf("cancelled" to nativeCancelled))
            }
            "dispose" -> launchShutdown(result)
            else -> result.notImplemented()
        }
    }

    override fun close() {
        shutdownAsync()
    }

    @Synchronized
    fun shutdownAsync(): Job {
        shutdownJob?.let { return it }
        disposed.set(true)
        onnx.cancel()
        gemma.cancel()
        activeOperation.getAndSet(null)?.cancel()
        scope.cancel()
        return cleanupScope.launch {
            runtimeLock.withLock {
                gemma.close()
                onnx.close()
            }
        }.also { shutdownJob = it }
    }

    private fun launchOperation(
        result: MethodChannel.Result,
        block: suspend () -> Map<String, Any?>,
    ) {
        if (disposed.get()) {
            result.success(unavailable(UNSUPPORTED))
            return
        }
        val job = scope.launch(start = CoroutineStart.LAZY) {
            val response = try {
                block()
            } catch (_: Throwable) {
                error(RUNTIME_ERROR)
            }
            reply(result, response)
        }
        if (!activeOperation.compareAndSet(null, job)) {
            job.cancel()
            result.success(error(RUNTIME_ERROR))
            return
        }
        job.invokeOnCompletion { activeOperation.compareAndSet(job, null) }
        job.start()
    }

    private fun launchUntracked(
        result: MethodChannel.Result,
        block: suspend () -> Map<String, Any?>,
    ) {
        scope.launch {
            val response = try {
                block()
            } catch (_: Throwable) {
                error(RUNTIME_ERROR)
            }
            reply(result, response)
        }
    }

    private fun launchShutdown(result: MethodChannel.Result) {
        val shutdown = shutdownAsync()
        cleanupScope.launch {
            shutdown.join()
            reply(result, success())
        }
    }

    private suspend fun reply(result: MethodChannel.Result, value: Map<String, Any?>) {
        withContext(Dispatchers.Main.immediate) { result.success(value) }
    }

    companion object {
        const val CHANNEL_NAME = "org.safemyanmar.mobile/ai"
    }
}
