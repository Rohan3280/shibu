package com.shibu.app.data

import android.content.Context
import android.util.Log
import org.json.JSONObject

/**
 * Loads the bundled kanji deck and resolves which entry should be on screen
 * right now.
 *
 * The deck is small (a few hundred entries) so it is parsed once and cached for
 * the lifetime of the process. Both the wallpaper engine and the widget
 * provider read through here, which keeps them showing the same card.
 */
object KanjiStore {

    private const val TAG = "ShibuKanjiStore"
    private const val ASSET = "kanji.json"

    @Volatile
    private var cache: List<Kanji>? = null

    fun all(context: Context): List<Kanji> {
        cache?.let { return it }
        synchronized(this) {
            cache?.let { return it }
            val loaded = load(context)
            cache = loaded
            return loaded
        }
    }

    private fun load(context: Context): List<Kanji> = try {
        val raw = context.assets.open(ASSET).bufferedReader().use { it.readText() }
        val array = JSONObject(raw).getJSONArray("kanji")
        buildList(array.length()) {
            for (i in 0 until array.length()) {
                add(Kanji.fromJson(array.getJSONObject(i)))
            }
        }
    } catch (e: Exception) {
        Log.e(TAG, "could not read $ASSET", e)
        emptyList()
    }

    /**
     * The deck the user has actually selected: their chosen JLPT levels, or
     * only their favourites when the favourites deck is active.
     */
    fun deck(context: Context): List<Kanji> {
        val prefs = Prefs(context)
        val everything = all(context)
        if (everything.isEmpty()) return emptyList()

        val selected = when (prefs.deck) {
            Prefs.DECK_FAVORITES -> {
                val favorites = prefs.favorites
                everything.filter { it.id in favorites }
            }
            else -> {
                val levels = prefs.levels
                everything.filter { it.level in levels }
            }
        }

        // Never hand back an empty deck: an empty favourites list or a
        // level filter that matches nothing would otherwise blank the widget.
        return selected.ifEmpty { everything }
    }

    /**
     * Deterministically orders the deck for the current shuffle seed, so every
     * surface (wallpaper, widget, in-app preview) walks the same sequence.
     */
    fun orderedDeck(context: Context): List<Kanji> {
        val prefs = Prefs(context)
        val deck = deck(context)
        if (!prefs.shuffle || deck.size < 2) return deck
        return DeckOrder.shuffled(deck, prefs.shuffleSeed.toInt())
    }

    /** The card that should currently be displayed. */
    fun current(context: Context): Kanji? {
        val ordered = orderedDeck(context)
        if (ordered.isEmpty()) return null
        val prefs = Prefs(context)
        val index = Math.floorMod(prefs.currentIndex, ordered.size)
        return ordered[index]
    }

    fun byId(context: Context, id: Int): Kanji? = all(context).firstOrNull { it.id == id }

    /** Drops the parsed deck; used after tests or an asset change. */
    fun invalidate() {
        cache = null
    }
}
