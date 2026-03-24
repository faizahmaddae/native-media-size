package com.faizdae.nativemediasize

import android.content.ContentUris
import android.content.Context
import android.provider.MediaStore
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class NativeMediaSizePlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "native_media_size")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getFileSize" -> {
                val assetId = call.argument<String>("assetId")
                if (assetId == null) {
                    result.error("INVALID_ARG", "assetId is required", null)
                    return
                }
                val size = querySize(assetId)
                result.success(size)
            }

            "getFileSizes" -> {
                val assetIds = call.argument<List<String>>("assetIds")
                if (assetIds == null || assetIds.isEmpty()) {
                    result.success(emptyMap<String, Long>())
                    return
                }
                val sizes = querySizes(assetIds)
                result.success(sizes)
            }

            else -> result.notImplemented()
        }
    }

    /// Query a single asset's file size from MediaStore.
    private fun querySize(assetId: String): Long? {
        val id = assetId.toLongOrNull() ?: return null
        val uri = ContentUris.withAppendedId(
            MediaStore.Files.getContentUri("external"), id
        )
        val projection = arrayOf(MediaStore.MediaColumns.SIZE)
        context.contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val sizeIndex = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.SIZE)
                val size = cursor.getLong(sizeIndex)
                if (size > 0) return size
            }
        }
        return null
    }

    /// Batch query file sizes from MediaStore using IN clause.
    /// Chunks into batches of 500 to stay within SQLite parameter limits.
    private fun querySizes(assetIds: List<String>): Map<String, Long> {
        val result = mutableMapOf<String, Long>()
        val numericIds = assetIds.mapNotNull { it.toLongOrNull() }
        if (numericIds.isEmpty()) return result

        // SQLite has a limit of ~999 bind parameters; chunk to stay safe
        val chunkSize = 500
        val uri = MediaStore.Files.getContentUri("external")
        val projection = arrayOf(MediaStore.MediaColumns._ID, MediaStore.MediaColumns.SIZE)

        for (chunk in numericIds.chunked(chunkSize)) {
            val placeholders = chunk.joinToString(",") { "?" }
            val selection = "${MediaStore.MediaColumns._ID} IN ($placeholders)"
            val selectionArgs = chunk.map { it.toString() }.toTypedArray()

            context.contentResolver.query(
                uri, projection, selection, selectionArgs, null
            )?.use { cursor ->
                val idIndex = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
                val sizeIndex = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.SIZE)
                while (cursor.moveToNext()) {
                    val id = cursor.getLong(idIndex)
                    val size = cursor.getLong(sizeIndex)
                    if (size > 0) {
                        result[id.toString()] = size
                    }
                }
            }
        }
        return result
    }
}
