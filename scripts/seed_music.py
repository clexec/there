#!/usr/bin/env python3
"""
THERE Music — Database Seeder
Fetches artists, albums, tracks metadata + 30s previews from iTunes API.
Stores everything in SQLite + exports JSON for iOS CoreData import.
"""

import os
import sys
import json
import time
import sqlite3
import hashlib
import argparse
import threading
from pathlib import Path
from datetime import datetime
from urllib.request import urlretrieve, urlopen, Request
from urllib.parse import quote_plus, urlencode
from urllib.error import URLError, HTTPError
from concurrent.futures import ThreadPoolExecutor, as_completed

# ─── Config ───────────────────────────────────────────────────────────────────

ARTISTS = [
    "Morgenshtern",
    "FACE",
    "Lil Peep",
    "Juice WRLD",
    "XXXTentacion",
    "Travis Scott",
    "Drake",
    "Post Malone",
    "Playboi Carti",
    "Lil Uzi Vert",
    "The Weeknd",
    "Kendrick Lamar",
    "Tyler the Creator",
    "Frank Ocean",
    "A$AP Rocky",
    "Oxxxymiron",
    "Скриптонит",
    "Pharaoh",
    "IC3PEAK",
    "ЛСП",
    "Bones",
    "Ghostemane",
    "Night Lovell",
    "Bladee",
    "Ecco2k",
]

BASE_DIR    = Path(__file__).parent.parent
DATA_DIR    = BASE_DIR / "scripts" / "data"
DB_PATH     = DATA_DIR / "theremusic.db"
PREVIEW_DIR = DATA_DIR / "previews"
JSON_DIR    = DATA_DIR / "json"
TRACKS_PER_ARTIST = 50   # iTunes max per request
MAX_WORKERS       = 6    # parallel downloads
ITUNES_DELAY      = 0.4  # seconds between API calls (rate limit)

HEADERS = {
    "User-Agent": "THERE-Music-Seeder/1.0",
    "Accept":     "application/json",
}

# ─── DB Schema ────────────────────────────────────────────────────────────────

SCHEMA = """
CREATE TABLE IF NOT EXISTS artists (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    itunes_id       INTEGER,
    genre           TEXT,
    photo_url       TEXT,
    followers       INTEGER DEFAULT 0,
    popularity      INTEGER DEFAULT 0,
    fetched_at      TEXT
);

CREATE TABLE IF NOT EXISTS albums (
    id              TEXT PRIMARY KEY,
    title           TEXT NOT NULL,
    artist_id       TEXT,
    artist_name     TEXT,
    itunes_id       INTEGER,
    artwork_url     TEXT,
    artwork_large   TEXT,
    release_date    TEXT,
    track_count     INTEGER DEFAULT 0,
    genre           TEXT,
    FOREIGN KEY(artist_id) REFERENCES artists(id)
);

CREATE TABLE IF NOT EXISTS tracks (
    id              TEXT PRIMARY KEY,
    title           TEXT NOT NULL,
    artist_id       TEXT,
    artist_name     TEXT NOT NULL,
    album_id        TEXT,
    album_title     TEXT,
    itunes_track_id INTEGER,
    artwork_url     TEXT,
    preview_url     TEXT,
    preview_file    TEXT,
    duration_ms     INTEGER DEFAULT 0,
    track_number    INTEGER,
    disc_number     INTEGER,
    genre           TEXT,
    release_date    TEXT,
    is_explicit     INTEGER DEFAULT 0,
    popularity      INTEGER DEFAULT 0,
    fetched_at      TEXT,
    FOREIGN KEY(artist_id) REFERENCES artists(id),
    FOREIGN KEY(album_id)  REFERENCES albums(id)
);

CREATE INDEX IF NOT EXISTS idx_tracks_artist ON tracks(artist_id);
CREATE INDEX IF NOT EXISTS idx_tracks_album  ON tracks(album_id);
CREATE INDEX IF NOT EXISTS idx_albums_artist ON albums(artist_id);
"""

# ─── Helpers ──────────────────────────────────────────────────────────────────

lock = threading.Lock()
stats = {"artists": 0, "albums": 0, "tracks": 0, "previews": 0, "errors": 0}

def log(msg, level="INFO"):
    ts = datetime.now().strftime("%H:%M:%S")
    prefix = {"INFO": "✅", "WARN": "⚠️ ", "ERR": "❌", "DL": "⬇️ "}.get(level, "•")
    print(f"[{ts}] {prefix} {msg}", flush=True)

def fetch_json(url, retries=3):
    for attempt in range(retries):
        try:
            req = Request(url, headers=HEADERS)
            with urlopen(req, timeout=15) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except (URLError, HTTPError) as e:
            if attempt < retries - 1:
                time.sleep(2 ** attempt)
                continue
            log(f"Fetch failed: {url[:80]} — {e}", "ERR")
            return None
    return None

def make_id(prefix, name):
    h = hashlib.md5(name.encode()).hexdigest()[:8]
    return f"{prefix}_{h}"

def artwork_large(url100):
    if not url100:
        return None
    return url100.replace("100x100bb", "600x600bb").replace("100x100", "600x600")

def safe_filename(s):
    return "".join(c if c.isalnum() or c in " -_." else "_" for c in s).strip()[:80]

# ─── iTunes API ───────────────────────────────────────────────────────────────

def itunes_search(term, entity="song", limit=50, country="us"):
    params = urlencode({
        "term":    term,
        "entity":  entity,
        "limit":   min(limit, 200),
        "country": country,
        "media":   "music",
    })
    url = f"https://itunes.apple.com/search?{params}"
    data = fetch_json(url)
    time.sleep(ITUNES_DELAY)
    if data:
        return data.get("results", [])
    return []

def itunes_lookup(itunes_id, entity="song", limit=50):
    url = f"https://itunes.apple.com/lookup?id={itunes_id}&entity={entity}&limit={limit}"
    data = fetch_json(url)
    time.sleep(ITUNES_DELAY)
    if data:
        return data.get("results", [])
    return []

# ─── Processors ───────────────────────────────────────────────────────────────

def process_artist(name, conn):
    log(f"Processing artist: {name}")

    # Search for artist
    results = itunes_search(name, entity="musicArtist", limit=5)
    artist_itunes_id = None
    for r in results:
        if r.get("wrapperType") == "artist" and name.lower() in r.get("artistName", "").lower():
            artist_itunes_id = r.get("artistId")
            break
    if not artist_itunes_id and results:
        artist_itunes_id = results[0].get("artistId")

    artist_id = make_id("artist", name)
    artist_record = {
        "id":         artist_id,
        "name":       name,
        "itunes_id":  artist_itunes_id,
        "genre":      None,
        "photo_url":  None,
        "followers":  0,
        "popularity": 0,
        "fetched_at": datetime.now().isoformat(),
    }

    with lock:
        conn.execute("""
            INSERT OR REPLACE INTO artists
            (id, name, itunes_id, genre, photo_url, followers, popularity, fetched_at)
            VALUES (:id,:name,:itunes_id,:genre,:photo_url,:followers,:popularity,:fetched_at)
        """, artist_record)
        conn.commit()
        stats["artists"] += 1

    # Fetch tracks for this artist
    track_results = itunes_search(f"{name}", entity="song", limit=TRACKS_PER_ARTIST)

    # Also try with explicit search for Cyrillic names
    if len(track_results) < 5 and artist_itunes_id:
        extra = itunes_lookup(artist_itunes_id, entity="song", limit=TRACKS_PER_ARTIST)
        extra = [r for r in extra if r.get("wrapperType") == "track"]
        track_results = (track_results + extra)[:TRACKS_PER_ARTIST * 2]

    log(f"  Found {len(track_results)} tracks for {name}")

    albums_seen = {}
    tracks_added = 0

    for r in track_results:
        if r.get("wrapperType") != "track" and r.get("kind") != "song":
            continue

        # Album
        album_itunes_id = r.get("collectionId")
        album_title     = r.get("collectionName", "Unknown Album")
        album_id        = make_id("album", f"{album_itunes_id or album_title}_{name}")

        if album_id not in albums_seen:
            albums_seen[album_id] = True
            artwork = r.get("artworkUrl100", "")
            album_record = {
                "id":           album_id,
                "title":        album_title,
                "artist_id":    artist_id,
                "artist_name":  r.get("artistName", name),
                "itunes_id":    album_itunes_id,
                "artwork_url":  artwork,
                "artwork_large": artwork_large(artwork),
                "release_date": r.get("releaseDate", ""),
                "track_count":  r.get("trackCount", 0),
                "genre":        r.get("primaryGenreName", ""),
            }
            with lock:
                conn.execute("""
                    INSERT OR IGNORE INTO albums
                    (id,title,artist_id,artist_name,itunes_id,artwork_url,artwork_large,release_date,track_count,genre)
                    VALUES(:id,:title,:artist_id,:artist_name,:itunes_id,:artwork_url,:artwork_large,:release_date,:track_count,:genre)
                """, album_record)
                conn.commit()
                stats["albums"] += 1

        # Track
        track_itunes_id = r.get("trackId")
        track_id = make_id("track", str(track_itunes_id or r.get("trackName", "")))
        artwork  = r.get("artworkUrl100", "")
        track_record = {
            "id":              track_id,
            "title":           r.get("trackName", "Unknown"),
            "artist_id":       artist_id,
            "artist_name":     r.get("artistName", name),
            "album_id":        album_id,
            "album_title":     album_title,
            "itunes_track_id": track_itunes_id,
            "artwork_url":     artwork_large(artwork) or artwork,
            "preview_url":     r.get("previewUrl", ""),
            "preview_file":    None,
            "duration_ms":     r.get("trackTimeMillis", 0),
            "track_number":    r.get("trackNumber"),
            "disc_number":     r.get("discNumber"),
            "genre":           r.get("primaryGenreName", ""),
            "release_date":    r.get("releaseDate", ""),
            "is_explicit":     1 if r.get("trackExplicitness") == "explicit" else 0,
            "popularity":      r.get("trackNumber", 0),
            "fetched_at":      datetime.now().isoformat(),
        }
        with lock:
            conn.execute("""
                INSERT OR REPLACE INTO tracks
                (id,title,artist_id,artist_name,album_id,album_title,itunes_track_id,
                 artwork_url,preview_url,preview_file,duration_ms,track_number,disc_number,
                 genre,release_date,is_explicit,popularity,fetched_at)
                VALUES(:id,:title,:artist_id,:artist_name,:album_id,:album_title,:itunes_track_id,
                       :artwork_url,:preview_url,:preview_file,:duration_ms,:track_number,:disc_number,
                       :genre,:release_date,:is_explicit,:popularity,:fetched_at)
            """, track_record)
            conn.commit()
            stats["tracks"] += 1
            tracks_added += 1

    log(f"  ✓ {name}: {tracks_added} tracks, {len(albums_seen)} albums")
    return artist_id

# ─── Preview Downloader ───────────────────────────────────────────────────────

def download_preview(row):
    track_id, title, artist_name, preview_url = row
    if not preview_url:
        return None

    safe_name = safe_filename(f"{artist_name} - {title}")
    filename  = PREVIEW_DIR / f"{safe_name}.m4a"

    if filename.exists():
        return str(filename)

    try:
        urlretrieve(preview_url, filename)
        with lock:
            stats["previews"] += 1
        log(f"  {artist_name} — {title[:40]}", "DL")
        return str(filename)
    except Exception as e:
        with lock:
            stats["errors"] += 1
        return None

def download_all_previews(conn):
    log("Downloading 30s previews...")
    rows = conn.execute(
        "SELECT id, title, artist_name, preview_url FROM tracks WHERE preview_url != '' AND preview_file IS NULL"
    ).fetchall()

    log(f"  {len(rows)} previews to download")

    results = {}
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        futures = {executor.submit(download_preview, row): row[0] for row in rows}
        for future in as_completed(futures):
            track_id = futures[future]
            filepath = future.result()
            if filepath:
                results[track_id] = filepath

    # Update DB with file paths
    for track_id, filepath in results.items():
        conn.execute(
            "UPDATE tracks SET preview_file = ? WHERE id = ?",
            (filepath, track_id)
        )
    conn.commit()
    log(f"  Downloaded {len(results)} previews")

# ─── JSON Export ──────────────────────────────────────────────────────────────

def export_json(conn):
    log("Exporting JSON for iOS app...")

    artists = [dict(row) for row in conn.execute("SELECT * FROM artists ORDER BY name").fetchall()]
    albums  = [dict(row) for row in conn.execute("SELECT * FROM albums  ORDER BY artist_name, release_date").fetchall()]
    tracks  = [dict(row) for row in conn.execute("SELECT * FROM tracks  ORDER BY artist_name, track_number").fetchall()]

    def write(name, data):
        path = JSON_DIR / f"{name}.json"
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        log(f"  Wrote {path.name} ({len(data)} items, {path.stat().st_size // 1024} KB)")

    write("artists", artists)
    write("albums",  albums)
    write("tracks",  tracks)

    # Combined seed file for iOS
    seed = {"artists": artists, "albums": albums, "tracks": tracks}
    seed_path = JSON_DIR / "seed.json"
    with open(seed_path, "w", encoding="utf-8") as f:
        json.dump(seed, f, ensure_ascii=False, separators=(",", ":"))
    log(f"  Wrote seed.json ({seed_path.stat().st_size // 1024} KB)")

    # Stats
    with open(JSON_DIR / "stats.json", "w") as f:
        json.dump({
            "artists": len(artists),
            "albums":  len(albums),
            "tracks":  len(tracks),
            "generated_at": datetime.now().isoformat(),
        }, f, indent=2)

# ─── Print Report ─────────────────────────────────────────────────────────────

def print_report(conn):
    print("\n" + "═" * 60)
    print("  THERE Music — Database Report")
    print("═" * 60)

    total_tracks = conn.execute("SELECT COUNT(*) FROM tracks").fetchone()[0]
    total_albums = conn.execute("SELECT COUNT(*) FROM albums").fetchone()[0]
    total_artists = conn.execute("SELECT COUNT(*) FROM artists").fetchone()[0]
    with_preview = conn.execute("SELECT COUNT(*) FROM tracks WHERE preview_url != ''").fetchone()[0]
    downloaded   = conn.execute("SELECT COUNT(*) FROM tracks WHERE preview_file IS NOT NULL").fetchone()[0]

    print(f"  Artists:          {total_artists}")
    print(f"  Albums:           {total_albums}")
    print(f"  Tracks total:     {total_tracks}")
    print(f"  With preview URL: {with_preview}")
    print(f"  Downloaded:       {downloaded}")
    print()
    print("  Top artists by track count:")
    for row in conn.execute("""
        SELECT artist_name, COUNT(*) as cnt
        FROM tracks GROUP BY artist_name
        ORDER BY cnt DESC LIMIT 10
    """).fetchall():
        print(f"    {row[0]:<25} {row[1]:>4} tracks")

    print("═" * 60)
    db_size = DB_PATH.stat().st_size // 1024
    print(f"  DB size: {db_size} KB  |  {DB_PATH}")
    print("═" * 60 + "\n")

# ─── Main ─────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="THERE Music DB Seeder")
    parser.add_argument("--no-download", action="store_true", help="Skip preview download")
    parser.add_argument("--artists",     nargs="+", help="Override artist list")
    parser.add_argument("--limit",       type=int, default=50, help="Tracks per artist")
    args = parser.parse_args()

    artist_list = args.artists or ARTISTS
    global TRACKS_PER_ARTIST
    TRACKS_PER_ARTIST = args.limit

    # Setup dirs
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    JSON_DIR.mkdir(parents=True, exist_ok=True)

    # Init DB
    conn = sqlite3.connect(str(DB_PATH), check_same_thread=False)
    conn.row_factory = sqlite3.Row
    conn.executescript(SCHEMA)
    conn.commit()

    log(f"Starting seeder — {len(artist_list)} artists, {TRACKS_PER_ARTIST} tracks each")
    log(f"DB: {DB_PATH}")

    # Fetch artists sequentially (iTunes rate limit)
    for name in artist_list:
        try:
            process_artist(name, conn)
        except Exception as e:
            log(f"Failed artist {name}: {e}", "ERR")
            stats["errors"] += 1

    # Download previews
    if not args.no_download:
        download_all_previews(conn)
    else:
        log("Skipping preview download (--no-download)")

    # Export JSON
    export_json(conn)

    # Report
    print_report(conn)
    conn.close()

    log(f"Done! Artists:{stats['artists']} Albums:{stats['albums']} "
        f"Tracks:{stats['tracks']} Previews:{stats['previews']} Errors:{stats['errors']}")

if __name__ == "__main__":
    main()
