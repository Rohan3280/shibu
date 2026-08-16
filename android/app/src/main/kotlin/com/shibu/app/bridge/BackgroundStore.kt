package com.shibu.app.bridge

import android.content.Context
import android.net.Uri
import android.util.Log
import com.shibu.app.data.Prefs
import java.io.File
import java.io.FileOutputStream

/**
 * Owns the copy of the user's chosen backdrop.
 *
 * The file is copied into app-private storage rather than referenced by its
 * content URI, so the wallpaper engine needs no storage permission and keeps
 * working if the original is later moved or deleted from the gallery. The bytes
 * are copied verbatim — re-encoding would flatten an animated GIF to a still.
 */
object BackgroundStore {

    private const val TAG = "ShibuBackground"
    private const val DIRECTORY = "wallpaper"

    /** No extension: the decoders sniff the format from the content. */
    private const val FILENAME = "background.img"

    /** Result of storing a backdrop, reported back to the Dart side. */
    data class Stored(val path: String, val animated: Boolean)

    fun save(context: Context, uri: Uri): Stored? = try {
        val dir = File(context.filesDir, DIRECTORY).apply { mkdirs() }
        val target = File(dir, FILENAME)

        context.contentResolver.openInputStream(uri)?.use { input ->
            FileOutputStream(target).use { output -> input.copyTo(output) }
        } ?: return null

        val animated = isAnimated(target)
        Prefs(context).apply {
            wallpaperPath = target.absolutePath
            backgroundKind = Prefs.BACKGROUND_IMAGE
        }
        Stored(target.absolutePath, animated)
    } catch (e: Exception) {
        Log.e(TAG, "could not store background", e)
        null
    }

    fun clear(context: Context) {
        val prefs = Prefs(context)
        prefs.wallpaperPath?.let { runCatching { File(it).delete() } }
        prefs.wallpaperPath = null
        prefs.backgroundKind = Prefs.BACKGROUND_PRESET
    }

    /** True when the stored backdrop is a GIF or an animated WebP. */
    fun isStoredAnimated(context: Context): Boolean {
        val path = Prefs(context).wallpaperPath ?: return false
        val file = File(path)
        return file.exists() && isAnimated(file)
    }

    /**
     * Sniffs the header for a multi-frame format.
     *
     * Every GIF is treated as animated; a single-frame GIF simply never
     * advances, which costs one wasted redraw and nothing else. A WebP is only
     * animated if it carries an ANIM chunk.
     */
    private fun isAnimated(file: File): Boolean = try {
        val header = ByteArray(64)
        val read = file.inputStream().use { it.read(header) }
        when {
            read < 12 -> false
            header.startsWith("GIF8") -> true
            header.startsWith("RIFF") && header.copyOfRange(8, 12).decodeAscii() == "WEBP" ->
                String(header, 0, read, Charsets.ISO_8859_1).contains("ANIM")
            else -> false
        }
    } catch (e: Exception) {
        Log.w(TAG, "could not read background header", e)
        false
    }

    private fun ByteArray.startsWith(prefix: String): Boolean =
        size >= prefix.length && copyOfRange(0, prefix.length).decodeAscii() == prefix

    private fun ByteArray.decodeAscii(): String = String(this, Charsets.ISO_8859_1)
}
