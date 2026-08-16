package com.shibu.app.data

import org.json.JSONObject

/**
 * One entry from the bundled kanji deck.
 *
 * Field names are deliberately short because the same JSON is parsed on the
 * Dart side and shipped inside the APK; see assets/data/kanji.json.
 */
data class Kanji(
    val id: Int,
    /** The kanji character itself, e.g. 駅. */
    val character: String,
    /** JLPT level: 5 is easiest, 3 is hardest in the bundled deck. */
    val level: Int,
    val strokes: Int,
    /** Primary reading in romaji, e.g. "eki". */
    val romaji: String,
    /** Primary reading in kana, e.g. えき. */
    val kana: String,
    /** English meaning, e.g. "station". */
    val meaning: String,
    val onyomi: String,
    val kunyomi: String,
    /** Example compound, e.g. 駅前. */
    val example: String,
    val exampleKana: String,
    val exampleRomaji: String,
    val exampleMeaning: String,
) {
    /** The reading line as shown on the widget: "eki・えき". */
    val readingLine: String get() = "$romaji・$kana"

    /** The example line as shown on the widget: "駅前・in front of station". */
    val exampleLine: String get() = "$example・$exampleMeaning"

    companion object {
        fun fromJson(o: JSONObject): Kanji = Kanji(
            id = o.getInt("id"),
            character = o.getString("c"),
            level = o.getInt("l"),
            strokes = o.optInt("s", 0),
            romaji = o.getString("r"),
            kana = o.getString("k"),
            meaning = o.getString("m"),
            onyomi = o.optString("on", ""),
            kunyomi = o.optString("kun", ""),
            example = o.getString("ex"),
            exampleKana = o.optString("exk", ""),
            exampleRomaji = o.optString("exr", ""),
            exampleMeaning = o.getString("exm"),
        )
    }
}
