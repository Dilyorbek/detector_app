package uz.msit.detector_app

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executor
import java.util.concurrent.Executors


class MainActivity : FlutterActivity() {
    private val TAG = MainActivity::class.java.name

    private val executor: Executor = Executors.newSingleThreadExecutor()
    private var classifier: Classifier? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "loadModel" -> {
                    initTensorFlowAndLoadModel(result)
                }
                "closeModel" -> {
                    closeModel(result)
                    result.success("Model closed!");
                }
                "detectObject" -> {
                    val imagePath = call.argument<String>("image")
                    detectObject(imagePath!!, result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }


    private fun initTensorFlowAndLoadModel(result: MethodChannel.Result) {
        try {
            classifier = TensorFlowImageClassifier.create(
                    assets,
                    MODEL,
                    LABEL,
                    INPUT_SIZE, QUANT)
            result.success("Modal Loaded!")
        } catch (e: java.lang.Exception) {
            result.error("Modal failed to loaded", e.message, null)
        }
    }

    private fun closeModel(result: MethodChannel.Result) {
        classifier?.close()
        result.success("Modal Closed!")
    }

    fun detectObject(imagePath: String, result: MethodChannel.Result) {
        Log.e(TAG, "c = $imagePath")
        try {
            var bitmap: Bitmap = BitmapFactory.decodeFile(imagePath)
            bitmap = Bitmap.createScaledBitmap(bitmap, INPUT_SIZE, INPUT_SIZE, true)
            Log.e(TAG, "ISBitmapOk = ${bitmap!=null}")
            val results = classifier?.recognizeImage(bitmap)
//
//            val topResult = results[0].title
//            Log.e(TAG, "Highest = $topResult")
//
//            val topPrecision = results[0].confidence
//
//            if (topPrecision > 0.5) {
//
//            }
            result.success("Everything is ok")
        } catch (e: Exception) {
            Log.e(TAG, "Error = $e")
            result.error(e.message, e.localizedMessage, null)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        executor.execute { classifier?.close() }
    }

    companion object {
        private const val CHANNEL = "francium.tech/tensorflow"
        private const val MODEL = "ssd_mobilenet.tflite"
        private const val LABEL = "ssd_mobilenet.txt"
        private const val QUANT = true
        private const val INPUT_SIZE = 224
        private var modalLoaded = false
    }
}
