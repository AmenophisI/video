package com.ryousuke.video_player

import android.app.Activity
import android.app.RecoverableSecurityException
import android.content.ContentUris
import android.content.ContentValues
import android.content.Intent
import android.content.IntentSender
import android.content.pm.PackageManager
import android.database.ContentObserver
import android.database.Cursor
import android.graphics.Bitmap
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.os.StatFs
import android.provider.MediaStore
import android.provider.Settings
import android.util.Size
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterFragmentActivity() {
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var pendingDeleteResult: MethodChannel.Result? = null
    private var pendingWriteResult: MethodChannel.Result? = null
    private var pendingWriteOperation: PendingWriteOperation? = null
    private var mediaStoreChannel: MethodChannel? = null
    private var mediaStoreObserver: ContentObserver? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val thumbnailExecutor = Executors.newFixedThreadPool(2)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        mediaStoreChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME
        )
        mediaStoreChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkVideoPermission" -> result.success(videoPermissionStatus())
                "requestVideoPermission" -> requestVideoPermission(result)
                "requestAdditionalVideoAccess" -> requestAdditionalVideoAccess(result)
                "openAppSettings" -> openAppSettings(result)
                "getAppInfo" -> result.success(appInfo())
                "queryVideos" -> result.success(queryVideos())
                "loadThumbnail" -> loadThumbnailAsync(call.arguments, result)
                "shareVideo" -> shareVideo(call.arguments, result)
                "shareVideos" -> shareVideos(call.arguments, result)
                "openEditor" -> openEditor(call.arguments, result)
                "openExternalPlayer" -> openExternalPlayer(call.arguments, result)
                "deleteVideo" -> deleteVideo(call.arguments, result)
                "deleteVideos" -> deleteVideos(call.arguments, result)
                "renameVideo" -> renameVideo(call.arguments, result)
                "moveVideo" -> moveVideo(call.arguments, result)
                "copyVideo" -> copyVideo(call.arguments, result)
                "createFolder" -> createFolder(call.arguments, result)
                else -> result.notImplemented()
            }
        }
        registerMediaStoreObserver()

        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory(
                ANDROID_VIDEO_VIEW_TYPE,
                AndroidVideoViewFactory(flutterEngine.dartExecutor.binaryMessenger)
            )
    }

    override fun onDestroy() {
        mediaStoreObserver?.let { contentResolver.unregisterContentObserver(it) }
        mediaStoreObserver = null
        mediaStoreChannel?.setMethodCallHandler(null)
        mediaStoreChannel = null
        thumbnailExecutor.shutdownNow()
        super.onDestroy()
    }

    private fun requestVideoPermission(result: MethodChannel.Result) {
        val currentStatus = videoPermissionStatus()
        if (currentStatus == PERMISSION_GRANTED || currentStatus == PERMISSION_LIMITED) {
            result.success(currentStatus)
            return
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            result.success(PERMISSION_GRANTED)
            return
        }

        if (pendingPermissionResult != null) {
            result.error(
                "permission_request_in_progress",
                "A media permission request is already in progress.",
                null
            )
            return
        }

        pendingPermissionResult = result
        requestPermissions(videoPermissionsForCurrentSdk(), VIDEO_PERMISSION_REQUEST_CODE)
    }

    private fun requestAdditionalVideoAccess(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < 34) {
            result.success(videoPermissionStatus())
            return
        }

        if (pendingPermissionResult != null) {
            result.error(
                "permission_request_in_progress",
                "A media permission request is already in progress.",
                null
            )
            return
        }

        pendingPermissionResult = result
        requestPermissions(
            arrayOf(READ_MEDIA_VIDEO, READ_MEDIA_VISUAL_USER_SELECTED),
            VIDEO_PERMISSION_REQUEST_CODE
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode == VIDEO_PERMISSION_REQUEST_CODE) {
            pendingPermissionResult?.success(videoPermissionStatus())
            pendingPermissionResult = null
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == DELETE_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                pendingDeleteResult?.success(null)
            } else {
                pendingDeleteResult?.error("delete_cancelled", "Delete was cancelled.", null)
            }
            pendingDeleteResult = null
        } else if (requestCode == WRITE_REQUEST_CODE) {
            val operation = pendingWriteOperation
            val result = pendingWriteResult
            pendingWriteOperation = null
            pendingWriteResult = null

            if (result == null || operation == null) {
                return
            }

            if (resultCode != Activity.RESULT_OK) {
                result.error("write_cancelled", "Write access was cancelled.", null)
                return
            }

            try {
                when (operation) {
                    is PendingWriteOperation.Rename -> performRename(
                        uri = operation.uri,
                        displayName = operation.displayName,
                        result = result,
                        requestAccessOnFailure = false
                    )
                    is PendingWriteOperation.Move -> performMove(
                        uri = operation.uri,
                        relativePath = operation.relativePath,
                        result = result,
                        requestAccessOnFailure = false
                    )
                }
            } catch (error: Exception) {
                result.error(operation.errorCode, error.message, null)
            }
        }
    }

    private fun videoPermissionStatus(): String {
        return when {
            canReadAllVideos() -> PERMISSION_GRANTED
            canReadSelectedVideos() -> PERMISSION_LIMITED
            else -> PERMISSION_DENIED
        }
    }

    private fun openAppSettings(result: MethodChannel.Result) {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
            }
            startActivity(intent)
            result.success(null)
        } catch (error: Exception) {
            result.error("open_settings_failed", error.message, null)
        }
    }

    private fun appInfo(): Map<String, Any?> {
        val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getPackageInfo(
                packageName,
                PackageManager.PackageInfoFlags.of(0)
            )
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageInfo(packageName, 0)
        }
        val appName = packageManager.getApplicationLabel(applicationInfo).toString()
        val buildNumber = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            packageInfo.longVersionCode.toString()
        } else {
            @Suppress("DEPRECATION")
            packageInfo.versionCode.toString()
        }

        return mapOf(
            "appName" to appName,
            "packageName" to packageName,
            "versionName" to (packageInfo.versionName ?: "unknown"),
            "buildNumber" to buildNumber
        )
    }

    private fun canReadAllVideos(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return true
        }

        val permission = if (Build.VERSION.SDK_INT >= 33) {
            READ_MEDIA_VIDEO
        } else {
            READ_EXTERNAL_STORAGE
        }

        return checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
    }

    private fun canReadSelectedVideos(): Boolean {
        if (Build.VERSION.SDK_INT < 34) {
            return false
        }

        return checkSelfPermission(READ_MEDIA_VISUAL_USER_SELECTED) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun videoPermissionsForCurrentSdk(): Array<String> {
        return when {
            Build.VERSION.SDK_INT >= 34 -> arrayOf(
                READ_MEDIA_VIDEO,
                READ_MEDIA_VISUAL_USER_SELECTED
            )
            Build.VERSION.SDK_INT >= 33 -> arrayOf(READ_MEDIA_VIDEO)
            else -> arrayOf(READ_EXTERNAL_STORAGE)
        }
    }

    private fun queryVideos(): List<Map<String, Any?>> {
        if (videoPermissionStatus() == PERMISSION_DENIED) {
            return emptyList()
        }

        val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL)
        } else {
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        }
        val projection = mutableListOf(
            MediaStore.Video.Media._ID,
            MediaStore.Video.Media.DISPLAY_NAME,
            MediaStore.Video.Media.BUCKET_ID,
            MediaStore.Video.Media.BUCKET_DISPLAY_NAME,
            MediaStore.Video.Media.MIME_TYPE,
            MediaStore.Video.Media.DURATION,
            MediaStore.Video.Media.SIZE,
            MediaStore.Video.Media.DATE_ADDED,
            MediaStore.Video.Media.DATE_MODIFIED
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            projection.add(MediaStore.Video.Media.RELATIVE_PATH)
        }
        val sortOrder = "${MediaStore.Video.Media.DATE_MODIFIED} DESC"
        val videos = mutableListOf<Map<String, Any?>>()
        val subtitlesByKey = querySubtitleFiles()

        return try {
            contentResolver.query(
                collection,
                projection.toTypedArray(),
                null,
                null,
                sortOrder
            )?.use { cursor ->
                val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Video.Media._ID)
                val displayNameColumn =
                    cursor.getColumnIndexOrThrow(MediaStore.Video.Media.DISPLAY_NAME)
                val bucketIdColumn =
                    cursor.getColumnIndexOrThrow(MediaStore.Video.Media.BUCKET_ID)
                val bucketNameColumn =
                    cursor.getColumnIndexOrThrow(MediaStore.Video.Media.BUCKET_DISPLAY_NAME)
                val mimeTypeColumn = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.MIME_TYPE)
                val durationColumn =
                    cursor.getColumnIndexOrThrow(MediaStore.Video.Media.DURATION)
                val sizeColumn = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.SIZE)
                val dateAddedColumn =
                    cursor.getColumnIndexOrThrow(MediaStore.Video.Media.DATE_ADDED)
                val dateModifiedColumn =
                    cursor.getColumnIndexOrThrow(MediaStore.Video.Media.DATE_MODIFIED)
                val relativePathColumn = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    cursor.getColumnIndex(MediaStore.Video.Media.RELATIVE_PATH)
                } else {
                    -1
                }

                while (cursor.moveToNext()) {
                    val id = cursor.getLong(idColumn)
                    val uri = ContentUris.withAppendedId(collection, id)
                    val displayName = cursor.getStringOrNull(displayNameColumn)
                        ?: uri.lastPathSegment
                        ?: "video-$id"
                    val folderId = cursor.getStringOrNull(bucketIdColumn) ?: "unknown"
                    val folderName = cursor.getStringOrNull(bucketNameColumn) ?: "Unknown"
                    val relativePath = cursor.getStringOrNull(relativePathColumn)
                    val dateAddedSeconds = cursor.getLongOrNull(dateAddedColumn)
                    val dateModifiedSeconds = cursor.getLongOrNull(dateModifiedColumn)
                    val metadata = readVideoMetadata(uri)
                    val subtitleUri = subtitlesByKey[subtitleKey(relativePath, displayName)]

                    videos.add(
                        mapOf(
                            "mediaStoreId" to id,
                            "uri" to uri.toString(),
                            "displayName" to displayName,
                            "folderId" to folderId,
                            "folderName" to folderName,
                            "relativePath" to relativePath,
                            "mimeType" to cursor.getStringOrNull(mimeTypeColumn),
                            "durationMs" to cursor.getLongOrNull(durationColumn),
                            "sizeBytes" to cursor.getLongOrNull(sizeColumn),
                            "dateAddedAtMs" to dateAddedSeconds?.times(1000),
                            "modifiedAtMs" to dateModifiedSeconds?.times(1000),
                            "width" to metadata.width,
                            "height" to metadata.height,
                            "rotationDegrees" to metadata.rotationDegrees,
                            "bitrate" to metadata.bitrate,
                            "frameRate" to metadata.frameRate,
                            "metadataText" to metadata.metadataText,
                            "subtitleUri" to subtitleUri?.toString(),
                            "isHdr" to metadata.isHdr,
                            "isDrm" to metadata.isDrm,
                            "isPlayable" to metadata.isPlayable
                        )
                    )
                }
            }

            videos
        } catch (_: SecurityException) {
            emptyList()
        }
    }

    private fun querySubtitleFiles(): Map<String, Uri> {
        val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL)
        } else {
            MediaStore.Files.getContentUri("external")
        }
        val projection = mutableListOf(
            MediaStore.Files.FileColumns._ID,
            MediaStore.Files.FileColumns.DISPLAY_NAME
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            projection.add(MediaStore.Files.FileColumns.RELATIVE_PATH)
        } else {
            projection.add(MediaStore.Files.FileColumns.DATA)
        }
        val selection = "${MediaStore.Files.FileColumns.DISPLAY_NAME} LIKE ? OR " +
            "${MediaStore.Files.FileColumns.DISPLAY_NAME} LIKE ?"
        val selectionArgs = arrayOf("%.srt", "%.vtt")
        val subtitles = mutableMapOf<String, Uri>()

        return try {
            contentResolver.query(
                collection,
                projection.toTypedArray(),
                selection,
                selectionArgs,
                null
            )?.use { cursor ->
                val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID)
                val displayNameColumn =
                    cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DISPLAY_NAME)
                val pathColumn = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    cursor.getColumnIndex(MediaStore.Files.FileColumns.RELATIVE_PATH)
                } else {
                    cursor.getColumnIndex(MediaStore.Files.FileColumns.DATA)
                }

                while (cursor.moveToNext()) {
                    val id = cursor.getLong(idColumn)
                    val displayName = cursor.getStringOrNull(displayNameColumn) ?: continue
                    val rawPath = cursor.getStringOrNull(pathColumn)
                    val relativePath = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        rawPath
                    } else {
                        rawPath?.substringBeforeLast('/', missingDelimiterValue = "")
                    }
                    subtitles[subtitleKey(relativePath, displayName)] =
                        ContentUris.withAppendedId(collection, id)
                }
            }

            subtitles
        } catch (_: Exception) {
            emptyMap()
        }
    }

    private fun subtitleKey(relativePath: String?, displayName: String): String {
        val pathKey = relativePath
            ?.trim()
            ?.trim('/')
            ?.lowercase()
            ?: ""
        val baseName = displayName
            .substringBeforeLast('.', missingDelimiterValue = displayName)
            .lowercase()

        return "$pathKey/$baseName"
    }

    private fun registerMediaStoreObserver() {
        if (mediaStoreObserver != null) {
            return
        }

        val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL)
        } else {
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        }
        mediaStoreObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean) {
                mediaStoreChannel?.invokeMethod("mediaStoreChanged", null)
            }

            override fun onChange(selfChange: Boolean, uri: Uri?) {
                mediaStoreChannel?.invokeMethod("mediaStoreChanged", uri?.toString())
            }
        }
        contentResolver.registerContentObserver(
            collection,
            true,
            mediaStoreObserver!!
        )
    }

    private fun loadThumbnail(arguments: Any?): ByteArray? {
        if (videoPermissionStatus() == PERMISSION_DENIED) {
            return null
        }

        val params = arguments as? Map<*, *> ?: return null
        val uriText = params["uri"] as? String ?: return null
        val mediaStoreId = (params["mediaStoreId"] as? Number)?.toLong()
        val width = (params["width"] as? Number)?.toInt() ?: 512
        val height = (params["height"] as? Number)?.toInt() ?: 288
        val videoUri = Uri.parse(uriText)
        val bitmap = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                contentResolver.loadThumbnail(
                    videoUri,
                    Size(width, height),
                    null
                )
            } else if (mediaStoreId != null) {
                @Suppress("DEPRECATION")
                MediaStore.Video.Thumbnails.getThumbnail(
                    contentResolver,
                    mediaStoreId,
                    MediaStore.Video.Thumbnails.MINI_KIND,
                    null
                )
            } else {
                null
            }
        } catch (_: Exception) {
            null
        } ?: extractVideoFrame(videoUri, width, height) ?: return null

        return bitmap.toJpegByteArray()
    }

    private fun loadThumbnailAsync(arguments: Any?, result: MethodChannel.Result) {
        thumbnailExecutor.execute {
            val bytes = loadThumbnail(arguments)
            mainHandler.post {
                result.success(bytes)
            }
        }
    }

    private fun extractVideoFrame(uri: Uri, width: Int, height: Int): Bitmap? {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(this, uri)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                retriever.getScaledFrameAtTime(
                    0,
                    MediaMetadataRetriever.OPTION_CLOSEST_SYNC,
                    width,
                    height
                )
            } else {
                @Suppress("DEPRECATION")
                retriever.getFrameAtTime(0, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
            }
        } catch (_: Exception) {
            null
        } finally {
            try {
                retriever.release()
            } catch (_: Exception) {
            }
        }
    }

    private fun shareVideo(arguments: Any?, result: MethodChannel.Result) {
        val uri = parseUriArgument(arguments, result) ?: return
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "video/*"
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        try {
            if (intent.resolveActivity(packageManager) == null) {
                result.error("share_failed", "No app can share this video.", null)
                return
            }
            startActivity(Intent.createChooser(intent, "動画を共有"))
            result.success(null)
        } catch (error: Exception) {
            result.error("share_failed", error.message, null)
        }
    }

    private fun shareVideos(arguments: Any?, result: MethodChannel.Result) {
        val params = arguments as? Map<*, *>
        val uriTexts = params?.get("uris") as? List<*>
        val uris = uriTexts
            ?.mapNotNull { (it as? String)?.let(Uri::parse) }
            ?.takeIf { it.isNotEmpty() }
        if (uris == null) {
            result.error("invalid_arguments", "uris are required.", null)
            return
        }

        val intent = if (uris.size == 1) {
            Intent(Intent.ACTION_SEND).apply {
                type = "video/*"
                putExtra(Intent.EXTRA_STREAM, uris.single())
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
        } else {
            Intent(Intent.ACTION_SEND_MULTIPLE).apply {
                type = "video/*"
                putParcelableArrayListExtra(Intent.EXTRA_STREAM, ArrayList(uris))
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
        }

        try {
            if (intent.resolveActivity(packageManager) == null) {
                result.error("share_failed", "No app can share these videos.", null)
                return
            }
            startActivity(Intent.createChooser(intent, "動画を共有"))
            result.success(null)
        } catch (error: Exception) {
            result.error("share_failed", error.message, null)
        }
    }

    private fun openEditor(arguments: Any?, result: MethodChannel.Result) {
        val uri = parseUriArgument(arguments, result) ?: return
        val intent = Intent(Intent.ACTION_EDIT).apply {
            setDataAndType(uri, "video/*")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        }

        try {
            if (intent.resolveActivity(packageManager) == null) {
                result.error("editor_not_found", "No editor app can open this video.", null)
                return
            }
            startActivity(Intent.createChooser(intent, "編集アプリで開く"))
            result.success(null)
        } catch (error: Exception) {
            result.error("editor_not_found", error.message, null)
        }
    }

    private fun openExternalPlayer(arguments: Any?, result: MethodChannel.Result) {
        val uri = parseUriArgument(arguments, result) ?: return
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "video/*")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        try {
            if (intent.resolveActivity(packageManager) == null) {
                result.error("player_not_found", "No player app can open this video.", null)
                return
            }
            startActivity(Intent.createChooser(intent, "外部プレイヤーで開く"))
            result.success(null)
        } catch (error: Exception) {
            result.error("player_not_found", error.message, null)
        }
    }

    private fun deleteVideo(arguments: Any?, result: MethodChannel.Result) {
        val uri = parseUriArgument(arguments, result) ?: return
        deleteUris(listOf(uri), result)
    }

    private fun deleteVideos(arguments: Any?, result: MethodChannel.Result) {
        val params = arguments as? Map<*, *>
        val uriTexts = params?.get("uris") as? List<*>
        val uris = uriTexts
            ?.mapNotNull { (it as? String)?.let(Uri::parse) }
            ?.takeIf { it.isNotEmpty() }
        if (uris == null) {
            result.error("invalid_arguments", "uris are required.", null)
            return
        }

        deleteUris(uris, result)
    }

    private fun deleteUris(uris: List<Uri>, result: MethodChannel.Result) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                if (pendingDeleteResult != null) {
                    result.error(
                        "delete_request_in_progress",
                        "A delete request is already in progress.",
                        null
                    )
                    return
                }

                pendingDeleteResult = result
                val request = MediaStore.createDeleteRequest(contentResolver, uris)
                try {
                    startIntentSenderForResult(
                        request.intentSender,
                        DELETE_REQUEST_CODE,
                        null,
                        0,
                        0,
                        0,
                        null
                    )
                } catch (error: IntentSender.SendIntentException) {
                    pendingDeleteResult = null
                    result.error("delete_failed", error.message, null)
                }
            } else {
                uris.forEach { uri -> contentResolver.delete(uri, null, null) }
                result.success(null)
            }
        } catch (error: Exception) {
            pendingDeleteResult = null
            result.error("delete_failed", error.message, null)
        }
    }

    private fun renameVideo(arguments: Any?, result: MethodChannel.Result) {
        val params = arguments as? Map<*, *>
        val uriText = params?.get("uri") as? String
        val displayName = params?.get("displayName") as? String
        if (uriText == null || displayName.isNullOrBlank()) {
            result.error("invalid_arguments", "uri and displayName are required.", null)
            return
        }

        performRename(
            uri = Uri.parse(uriText),
            displayName = displayName,
            result = result,
            requestAccessOnFailure = true
        )
    }

    private fun moveVideo(arguments: Any?, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.error("unsupported_version", "Move requires Android 10 or later.", null)
            return
        }

        val params = arguments as? Map<*, *>
        val uriText = params?.get("uri") as? String
        val relativePath = normalizeRelativePath(params?.get("relativePath") as? String)
        if (uriText == null || relativePath == null) {
            result.error("invalid_arguments", "uri and relativePath are required.", null)
            return
        }

        performMove(
            uri = Uri.parse(uriText),
            relativePath = relativePath,
            result = result,
            requestAccessOnFailure = true
        )
    }

    private fun copyVideo(arguments: Any?, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.error("unsupported_version", "Copy requires Android 10 or later.", null)
            return
        }

        val params = arguments as? Map<*, *>
        val uriText = params?.get("uri") as? String
        val displayName = params?.get("displayName") as? String
        val relativePath = normalizeRelativePath(params?.get("relativePath") as? String)
        val mimeType = params?.get("mimeType") as? String ?: "video/*"
        if (uriText == null || displayName.isNullOrBlank() || relativePath == null) {
            result.error(
                "invalid_arguments",
                "uri, displayName and relativePath are required.",
                null
            )
            return
        }

        val collection = MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL)
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }

        var createdUri: Uri? = null
        try {
            val sourceUri = Uri.parse(uriText)
            val sourceSize = sourceSizeBytes(sourceUri)
            val availableBytes = availableStorageBytes()
            if (sourceSize != null && availableBytes != null && sourceSize > availableBytes) {
                result.error(
                    "insufficient_storage",
                    "Not enough free storage to copy this video.",
                    null
                )
                return
            }

            createdUri = contentResolver.insert(collection, values)
            if (createdUri == null) {
                result.error("copy_failed", "Could not create destination media item.", null)
                return
            }

            contentResolver.openInputStream(sourceUri).use { input ->
                contentResolver.openOutputStream(createdUri).use { output ->
                    if (input == null || output == null) {
                        throw IllegalStateException("Could not open media streams.")
                    }
                    input.copyTo(output)
                }
            }

            val publishedValues = ContentValues().apply {
                put(MediaStore.MediaColumns.IS_PENDING, 0)
            }
            contentResolver.update(createdUri, publishedValues, null, null)
            result.success(null)
        } catch (error: Exception) {
            createdUri?.let { contentResolver.delete(it, null, null) }
            result.error("copy_failed", error.message, null)
        }
    }

    private fun createFolder(arguments: Any?, result: MethodChannel.Result) {
        val relativePath = normalizeRelativePath(
            (arguments as? Map<*, *>)?.get("relativePath") as? String
        )
        if (relativePath == null) {
            result.error("invalid_arguments", "relativePath is required.", null)
            return
        }
        if (hasInvalidRelativePath(relativePath)) {
            result.error("invalid_relative_path", "Relative path contains invalid characters.", null)
            return
        }

        try {
            val root = Environment.getExternalStorageDirectory()
            val directory = File(root, relativePath)
            if (directory.exists()) {
                result.error("folder_already_exists", "Folder already exists.", null)
            } else if (directory.mkdirs()) {
                result.success(null)
            } else {
                result.error("folder_create_failed", "Could not create folder.", null)
            }
        } catch (error: Exception) {
            result.error("folder_create_failed", error.message, null)
        }
    }

    private fun hasInvalidRelativePath(relativePath: String): Boolean {
        return relativePath.trim('/').split('/').any { segment ->
            segment.isBlank() ||
                segment == "." ||
                segment == ".." ||
                segment.any { char -> "\\:*?\"<>|".contains(char) }
        }
    }

    private fun sourceSizeBytes(uri: Uri): Long? {
        val projection = arrayOf(MediaStore.MediaColumns.SIZE)
        contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val sizeIndex = cursor.getColumnIndex(MediaStore.MediaColumns.SIZE)
                if (sizeIndex >= 0) {
                    return cursor.getLongOrNull(sizeIndex)
                }
            }
        }

        return contentResolver.openFileDescriptor(uri, "r")?.use { descriptor ->
            descriptor.statSize.takeIf { it >= 0 }
        }
    }

    private fun availableStorageBytes(): Long? {
        return try {
            val stat = StatFs(Environment.getExternalStorageDirectory().absolutePath)
            stat.availableBytes
        } catch (_: Exception) {
            null
        }
    }

    private fun parseUriArgument(arguments: Any?, result: MethodChannel.Result): Uri? {
        val uriText = (arguments as? Map<*, *>)?.get("uri") as? String
        if (uriText == null) {
            result.error("invalid_arguments", "uri is required.", null)
            return null
        }

        return Uri.parse(uriText)
    }

    private fun performRename(
        uri: Uri,
        displayName: String,
        result: MethodChannel.Result,
        requestAccessOnFailure: Boolean
    ) {
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
        }
        updateMedia(
            uri = uri,
            values = values,
            operation = PendingWriteOperation.Rename(uri, displayName),
            result = result,
            errorCode = "rename_failed",
            requestAccessOnFailure = requestAccessOnFailure
        )
    }

    private fun performMove(
        uri: Uri,
        relativePath: String,
        result: MethodChannel.Result,
        requestAccessOnFailure: Boolean
    ) {
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
        }
        updateMedia(
            uri = uri,
            values = values,
            operation = PendingWriteOperation.Move(uri, relativePath),
            result = result,
            errorCode = "move_failed",
            requestAccessOnFailure = requestAccessOnFailure
        )
    }

    private fun updateMedia(
        uri: Uri,
        values: ContentValues,
        operation: PendingWriteOperation,
        result: MethodChannel.Result,
        errorCode: String,
        requestAccessOnFailure: Boolean
    ) {
        try {
            val updatedRows = contentResolver.update(uri, values, null, null)
            if (updatedRows > 0) {
                result.success(null)
            } else {
                result.error(errorCode, "No media item was updated.", null)
            }
        } catch (error: RecoverableSecurityException) {
            if (requestAccessOnFailure && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                requestWriteAccess(
                    uri = uri,
                    operation = operation,
                    result = result,
                    fallbackIntentSender = error.userAction.actionIntent.intentSender
                )
            } else {
                result.error(errorCode, error.message, null)
            }
        } catch (error: SecurityException) {
            if (requestAccessOnFailure && Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                requestWriteAccess(
                    uri = uri,
                    operation = operation,
                    result = result,
                    fallbackIntentSender = null
                )
            } else {
                result.error(errorCode, error.message, null)
            }
        } catch (error: Exception) {
            result.error(errorCode, error.message, null)
        }
    }

    private fun requestWriteAccess(
        uri: Uri,
        operation: PendingWriteOperation,
        result: MethodChannel.Result,
        fallbackIntentSender: IntentSender?
    ) {
        if (pendingWriteResult != null) {
            result.error(
                "write_request_in_progress",
                "A write access request is already in progress.",
                null
            )
            return
        }

        pendingWriteResult = result
        pendingWriteOperation = operation
        val intentSender = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            MediaStore.createWriteRequest(contentResolver, listOf(uri)).intentSender
        } else {
            fallbackIntentSender
        }

        if (intentSender == null) {
            pendingWriteResult = null
            pendingWriteOperation = null
            result.error(operation.errorCode, "Write access cannot be requested.", null)
            return
        }

        try {
            startIntentSenderForResult(
                intentSender,
                WRITE_REQUEST_CODE,
                null,
                0,
                0,
                0,
                null
            )
        } catch (error: IntentSender.SendIntentException) {
            pendingWriteResult = null
            pendingWriteOperation = null
            result.error(operation.errorCode, error.message, null)
        }
    }

    private fun normalizeRelativePath(relativePath: String?): String? {
        val normalized = relativePath
            ?.trim()
            ?.trim('/')
            ?.takeIf { it.isNotBlank() }
            ?: return null

        return "$normalized/"
    }

    private fun Bitmap.toJpegByteArray(): ByteArray {
        val output = ByteArrayOutputStream()
        compress(Bitmap.CompressFormat.JPEG, THUMBNAIL_QUALITY, output)
        return output.toByteArray()
    }

    private fun readVideoMetadata(uri: Uri): VideoMetadata {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(this, uri)
            val duration = retriever.extractIntMetadata(
                MediaMetadataRetriever.METADATA_KEY_DURATION
            )
            val mimeType = retriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_MIMETYPE
            )
            val colorTransfer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                retriever.extractIntMetadata(
                    MediaMetadataRetriever.METADATA_KEY_COLOR_TRANSFER
                )
            } else {
                null
            }
            val metadataText = listOfNotNull(
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_TITLE),
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ALBUM),
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ARTIST),
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_GENRE),
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_MIMETYPE)
            ).joinToString(" ")
            VideoMetadata(
                width = retriever.extractIntMetadata(
                    MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH
                ),
                height = retriever.extractIntMetadata(
                    MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT
                ),
                rotationDegrees = retriever.extractIntMetadata(
                    MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION
                ),
                bitrate = retriever.extractIntMetadata(
                    MediaMetadataRetriever.METADATA_KEY_BITRATE
                ),
                frameRate = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    retriever
                        .extractMetadata(MediaMetadataRetriever.METADATA_KEY_CAPTURE_FRAMERATE)
                        ?.toDoubleOrNull()
                } else {
                    null
                },
                metadataText = metadataText,
                isHdr = colorTransfer == MediaFormat.COLOR_TRANSFER_ST2084 ||
                    colorTransfer == MediaFormat.COLOR_TRANSFER_HLG ||
                    mimeType?.contains("dolby-vision", ignoreCase = true) == true,
                isDrm = mimeType?.contains("drm", ignoreCase = true) == true ||
                    metadataText.contains("drm", ignoreCase = true),
                isPlayable = duration != null && duration > 0
            )
        } catch (_: Exception) {
            VideoMetadata(isPlayable = false)
        } finally {
            retriever.release()
        }
    }

    private fun MediaMetadataRetriever.extractIntMetadata(keyCode: Int): Int? {
        return extractMetadata(keyCode)?.toIntOrNull()
    }

    private fun Cursor.getStringOrNull(columnIndex: Int): String? {
        if (columnIndex < 0 || isNull(columnIndex)) {
            return null
        }

        return getString(columnIndex)
    }

    private fun Cursor.getLongOrNull(columnIndex: Int): Long? {
        if (columnIndex < 0 || isNull(columnIndex)) {
            return null
        }

        return getLong(columnIndex)
    }

    private companion object {
        const val CHANNEL_NAME = "video_player/media_store"
        const val ANDROID_VIDEO_VIEW_TYPE = "video_player/android_video_view"
        const val VIDEO_PERMISSION_REQUEST_CODE = 3711
        const val DELETE_REQUEST_CODE = 3712
        const val WRITE_REQUEST_CODE = 3713
        const val THUMBNAIL_QUALITY = 85

        const val READ_EXTERNAL_STORAGE = "android.permission.READ_EXTERNAL_STORAGE"
        const val READ_MEDIA_VIDEO = "android.permission.READ_MEDIA_VIDEO"
        const val READ_MEDIA_VISUAL_USER_SELECTED =
            "android.permission.READ_MEDIA_VISUAL_USER_SELECTED"

        const val PERMISSION_GRANTED = "granted"
        const val PERMISSION_LIMITED = "limited"
        const val PERMISSION_DENIED = "denied"
    }
}

private sealed class PendingWriteOperation(
    val uri: Uri,
    val errorCode: String
) {
    class Rename(uri: Uri, val displayName: String) :
        PendingWriteOperation(uri, "rename_failed")

    class Move(uri: Uri, val relativePath: String) :
        PendingWriteOperation(uri, "move_failed")
}

private data class VideoMetadata(
    val width: Int? = null,
    val height: Int? = null,
    val rotationDegrees: Int? = null,
    val bitrate: Int? = null,
    val frameRate: Double? = null,
    val metadataText: String? = null,
    val isHdr: Boolean = false,
    val isDrm: Boolean = false,
    val isPlayable: Boolean = true
)
