package com.example.mix_music

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import java.io.File

class LocalFiles(private val context: Context, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "mixmusic/local_files")
    private val executor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    init {
        channel.setMethodCallHandler { call, result ->
            if (call.method != "listDirectory" && call.method != "retainDirectory" && call.method != "saveDownload" && call.method != "checkDownloadDirectory" && call.method != "createDownloadFolder") {
                result.notImplemented()
            } else {
                val uri = Uri.parse(call.argument<String>("uri")!!)
                executor.execute {
                    try {
                        val value = if (call.method == "retainDirectory") {
                            val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                (if (call.argument<Boolean>("write") == true) Intent.FLAG_GRANT_WRITE_URI_PERMISSION else 0)
                            context.contentResolver.takePersistableUriPermission(uri, flags)
                            list(uri)
                            null
                        } else if (call.method == "checkDownloadDirectory") {
                            check(context.contentResolver.persistedUriPermissions.any {
                                it.uri == uri && it.isReadPermission && it.isWritePermission
                            }) { "目录授权已失效，请重新选择文件夹" }
                            list(uri)
                            null
                        } else if (call.method == "createDownloadFolder") {
                            val name = call.argument<String>("name")!!
                            val existing = list(uri).find { it["name"] == name && it["directory"] == true }
                            existing?.get("uri") ?: DocumentsContract.createDocument(
                                context.contentResolver, document(uri), DocumentsContract.Document.MIME_TYPE_DIR, name
                            )?.toString() ?: throw IllegalStateException("无法创建分类目录")
                        } else if (call.method == "saveDownload") {
                            saveDownload(uri, call.argument<String>("path")!!,
                                call.argument<String>("name")!!, call.argument<String>("mime")!!)
                        } else list(uri)
                        main.post { result.success(value) }
                    } catch (error: Exception) {
                        Log.e("MixMusic.LocalFiles", "${call.method} failed for $uri", error)
                        val message = if (error is SecurityException) "目录授权已失效，请重新选择文件夹" else error.message
                        main.post { result.error("directory_operation_failed", message, null) }
                    }
                }
            }
        }
    }

    private fun saveDownload(tree: Uri, path: String, name: String, mime: String): String {
        check(list(tree).none { it["name"] == name }) { "目标文件已存在" }
        val parent = document(tree)
        val resolver = context.contentResolver
        var target = DocumentsContract.createDocument(resolver, parent, "application/octet-stream", "$name.part")
            ?: throw IllegalStateException("无法创建下载文件")
        try {
            val output = resolver.openOutputStream(target, "w")
                ?: throw IllegalStateException("无法写入下载文件")
            val source = File(path)
            val expected = source.length()
            val copied = output.use { stream -> source.inputStream().use { it.copyTo(stream) } }
            check(expected > 0 && copied == expected) { "音频文件未复制完整" }
            check(list(tree).none { it["name"] == name }) { "目标文件已存在" }
            target = DocumentsContract.renameDocument(resolver, target, name)
                ?: throw IllegalStateException("无法完成下载文件命名")
            val names = arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
            resolver.query(target, names, null, null, null).use { cursor ->
                check(cursor != null && cursor.moveToFirst() && cursor.getString(0) == name) {
                    "下载文件名称不匹配"
                }
            }
            return target.toString()
        } catch (error: Exception) {
            DocumentsContract.deleteDocument(resolver, target)
            throw error
        }
    }

    private fun list(uri: Uri): List<Map<String, Any>> {
        val id = if (DocumentsContract.isDocumentUri(context, uri)) {
            DocumentsContract.getDocumentId(uri)
        } else DocumentsContract.getTreeDocumentId(uri)
        val children = DocumentsContract.buildChildDocumentsUriUsingTree(uri, id)
        val columns = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_SIZE,
        )
        val entries = mutableListOf<Map<String, Any>>()
        val cursor = context.contentResolver.query(children, columns, null, null, null)
            ?: throw IllegalStateException("目录未返回内容")
        cursor.use {
            while (it.moveToNext()) {
                entries.add(mapOf(
                    "uri" to DocumentsContract.buildDocumentUriUsingTree(uri, it.getString(0)).toString(),
                    "name" to it.getString(1),
                    "directory" to (it.getString(2) == DocumentsContract.Document.MIME_TYPE_DIR),
                    "size" to it.getLong(3),
                ))
            }
        }
        return entries
    }

    private fun document(uri: Uri): Uri = DocumentsContract.buildDocumentUriUsingTree(uri,
        if (DocumentsContract.isDocumentUri(context, uri)) DocumentsContract.getDocumentId(uri)
        else DocumentsContract.getTreeDocumentId(uri))

    fun dispose() {
        channel.setMethodCallHandler(null)
        executor.shutdown()
    }
}
