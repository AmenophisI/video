package com.ryousuke.video_player

import android.content.Context
import android.graphics.Color
import android.net.Uri
import android.view.Gravity
import android.view.View
import android.widget.FrameLayout
import android.widget.TextView
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.C
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.session.MediaSession
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class AndroidVideoViewFactory(
    private val messenger: BinaryMessenger
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return AndroidVideoPlatformView(
            context = context,
            messenger = messenger,
            viewId = viewId,
            params = args as? Map<*, *>
        )
    }
}

private class AndroidVideoPlatformView(
    context: Context,
    messenger: BinaryMessenger,
    viewId: Int,
    params: Map<*, *>?
) : PlatformView {
    private val container = FrameLayout(context)
    private val playerView = PlayerView(context)
    private val errorText = TextView(context)
    private val player = ExoPlayer.Builder(context).build()
    private val mediaSession = MediaSession.Builder(context, player).build()
    private var isMuted = false
    private var subtitleEnabled = true
    private var initialPositionMs = 0L
    private var hasAppliedInitialSeek = false
    private val channel = MethodChannel(
        messenger,
        "video_player/android_video_view_$viewId"
    )

    init {
        container.setBackgroundColor(Color.BLACK)

        playerView.layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT,
            Gravity.CENTER
        )
        playerView.setBackgroundColor(Color.BLACK)
        playerView.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT
        playerView.setKeepContentOnPlayerReset(true)
        playerView.useController = false
        playerView.controllerShowTimeoutMs = CONTROLLER_SHOW_MS
        playerView.player = player
        container.addView(playerView)
        container.addOnLayoutChangeListener { _, _, _, _, _, _, _, _, _ ->
            playerView.requestLayout()
            playerView.invalidate()
        }

        errorText.layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT,
            Gravity.CENTER
        )
        errorText.setTextColor(Color.WHITE)
        errorText.text = "動画を再生できません"
        errorText.visibility = View.GONE
        container.addView(errorText)

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> {
                    player.play()
                    result.success(null)
                }
                "pause" -> {
                    player.pause()
                    result.success(null)
                }
                "seekTo" -> {
                    val positionMs = (call.argument<Number>("positionMs"))?.toLong() ?: 0L
                    player.seekTo(positionMs.coerceAtLeast(0L))
                    result.success(null)
                }
                "setMuted" -> {
                    isMuted = call.argument<Boolean>("muted") ?: false
                    applyVolume()
                    result.success(null)
                }
                "setSubtitleEnabled" -> {
                    subtitleEnabled = call.argument<Boolean>("enabled") ?: true
                    applySubtitleSelection()
                    result.success(null)
                }
                "setPlaybackSpeed" -> {
                    val speed = (call.argument<Number>("speed"))?.toFloat() ?: 1f
                    player.setPlaybackSpeed(speed.coerceIn(0.25f, 2f))
                    result.success(null)
                }
                "setResizeMode" -> {
                    playerView.resizeMode = when (call.argument<String>("mode")) {
                        "zoom" -> AspectRatioFrameLayout.RESIZE_MODE_ZOOM
                        else -> AspectRatioFrameLayout.RESIZE_MODE_FIT
                    }
                    result.success(null)
                }
                "position" -> result.success(player.currentPosition.coerceAtLeast(0L).toInt())
                "duration" -> {
                    val duration = player.duration
                    result.success(if (duration > 0) duration.toInt() else 0)
                }
                "isPlaying" -> result.success(player.isPlaying)
                else -> result.notImplemented()
            }
        }

        player.addListener(object : Player.Listener {
            override fun onPlaybackStateChanged(playbackState: Int) {
                if (playbackState == Player.STATE_READY) {
                    applyInitialSeek()
                }
                if (playbackState == Player.STATE_ENDED) {
                    channel.invokeMethod("completed", null)
                }
            }

            override fun onPlayerError(error: PlaybackException) {
                showError()
            }
        })

        val uriText = params?.get("uri") as? String
        val subtitleUriText = params?.get("subtitleUri") as? String
        initialPositionMs =
            ((params?.get("initialPositionMs") as? Number)?.toLong() ?: 0L).coerceAtLeast(0L)
        if (uriText.isNullOrBlank()) {
            showError()
        } else {
            val mediaItem = buildMediaItem(uriText, subtitleUriText)
            player.setMediaItem(mediaItem, initialPositionMs)
            applyVolume()
            applySubtitleSelection()
            player.prepare()
            player.playWhenReady = true
        }
    }

    override fun getView(): View {
        return container
    }

    override fun dispose() {
        channel.setMethodCallHandler(null)
        playerView.player = null
        mediaSession.release()
        player.release()
    }

    private fun applyInitialSeek() {
        if (hasAppliedInitialSeek || initialPositionMs <= 0L) {
            return
        }

        hasAppliedInitialSeek = true
        player.seekTo(initialPositionMs)
    }

    private fun buildMediaItem(uriText: String, subtitleUriText: String?): MediaItem {
        val builder = MediaItem.Builder().setUri(Uri.parse(uriText))
        val subtitleConfiguration = buildSubtitleConfiguration(subtitleUriText)
        if (subtitleConfiguration != null) {
            builder.setSubtitleConfigurations(listOf(subtitleConfiguration))
        }

        return builder.build()
    }

    private fun buildSubtitleConfiguration(subtitleUriText: String?): MediaItem.SubtitleConfiguration? {
        if (subtitleUriText.isNullOrBlank()) {
            return null
        }

        val subtitleUri = Uri.parse(subtitleUriText)
        val mimeType = when (subtitleUri.lastPathSegment?.substringAfterLast('.')?.lowercase()) {
            "srt" -> MimeTypes.APPLICATION_SUBRIP
            "vtt" -> MimeTypes.TEXT_VTT
            else -> return null
        }

        return MediaItem.SubtitleConfiguration.Builder(subtitleUri)
            .setMimeType(mimeType)
            .setLanguage("ja")
            .setSelectionFlags(0)
            .build()
    }

    private fun showError() {
        playerView.visibility = View.GONE
        errorText.visibility = View.VISIBLE
    }

    private fun applyVolume() {
        player.volume = if (isMuted) 0f else 1f
    }

    private fun applySubtitleSelection() {
        player.trackSelectionParameters = player.trackSelectionParameters
            .buildUpon()
            .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, !subtitleEnabled)
            .build()
    }

    private companion object {
        const val CONTROLLER_SHOW_MS = 1500
    }
}
