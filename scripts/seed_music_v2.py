#!/usr/bin/env python3
"""
THERE Music — Multi-Source Seeder v2
Sources: iTunes API + Deezer API + Last.fm API
Covers Russian/CIS artists that iTunes doesn't have.
"""

import os, sys, json, time, sqlite3, hashlib, threading, argparse
from pathlib import Path
from datetime import datetime
from urllib.request import urlretrieve, urlopen, Request
from urllib.parse import quote, quote_plus, urlencode
from urllib.error import URLError, HTTPError
from concurrent.futures import ThreadPoolExecutor, as_completed

# ─── 150+ Artists ─────────────────────────────────────────────────────────────

ARTISTS = [
    # Russian/CIS rap
    {"name": "MORGENSHTERN",    "deezer": "MORGENSHTERN",   "lastfm": "Morgenshtern"},
    {"name": "FACE",            "deezer": "FACE",            "lastfm": "FACE"},
    {"name": "Oxxxymiron",      "deezer": "Oxxxymiron",      "lastfm": "Oxxxymiron"},
    {"name": "Pharaoh",         "deezer": "Pharaoh",         "lastfm": "Pharaoh"},
    {"name": "IC3PEAK",         "deezer": "IC3PEAK",         "lastfm": "IC3PEAK"},
    {"name": "Скриптонит",      "deezer": "Scriptonite",     "lastfm": "Scriptonite"},
    {"name": "ЛСП",             "deezer": "LSP",             "lastfm": "LSP"},
    {"name": "Boulevard Depo",  "deezer": "Boulevard Depo",  "lastfm": "Boulevard Depo"},
    {"name": "Allj",            "deezer": "Allj",            "lastfm": "Allj"},
    {"name": "Yanix",           "deezer": "Yanix",           "lastfm": "Yanix"},
    {"name": "Thomas Mraz",     "deezer": "Thomas Mraz",     "lastfm": "Thomas Mraz"},
    {"name": "Мот",             "deezer": "Mot",             "lastfm": "Mot"},
    {"name": "Тимати",          "deezer": "Timati",          "lastfm": "Timati"},
    {"name": "Kizaru",          "deezer": "Kizaru",          "lastfm": "Kizaru"},
    {"name": "Хаски",           "deezer": "Husky",           "lastfm": "Husky"},
    {"name": "Элджей",          "deezer": "Eljay",           "lastfm": "Eljay"},
    {"name": "Гречка",          "deezer": "Grechka",         "lastfm": "Grechka"},
    {"name": "GONE.Fludd",      "deezer": "GONE.Fludd",      "lastfm": "GONE.Fludd"},
    {"name": "ATL",             "deezer": "ATL",             "lastfm": "ATL"},
    {"name": "Баста",           "deezer": "Basta",           "lastfm": "Basta"},
    {"name": "25/17",           "deezer": "25/17",           "lastfm": "25/17"},
    {"name": "Noize MC",        "deezer": "Noize MC",        "lastfm": "Noize MC"},
    {"name": "Нервы",           "deezer": "Nervy",           "lastfm": "Nervy"},
    {"name": "Порнофильмы",     "deezer": "Pornofilmy",      "lastfm": "Pornofilmy"},
    {"name": "Рем Дигга",       "deezer": "Rem Digga",       "lastfm": "Rem Digga"},
    {"name": "Mayot",           "deezer": "Mayot",           "lastfm": "Mayot"},
    {"name": "Dramma",          "deezer": "Dramma",          "lastfm": "Dramma"},
    {"name": "Tveth",           "deezer": "Tveth",           "lastfm": "Tveth"},
    {"name": "Gone.Fludd",      "deezer": "Gone.Fludd",      "lastfm": "Gone.Fludd"},
    {"name": "Obladaet",        "deezer": "Obladaet",        "lastfm": "Obladaet"},

    # International rap/trap
    {"name": "Lil Peep",        "deezer": "Lil Peep",        "lastfm": "Lil Peep"},
    {"name": "Juice WRLD",      "deezer": "Juice WRLD",      "lastfm": "Juice WRLD"},
    {"name": "XXXTentacion",    "deezer": "XXXTentacion",    "lastfm": "XXXTENTACION"},
    {"name": "Travis Scott",    "deezer": "Travis Scott",    "lastfm": "Travis Scott"},
    {"name": "Drake",           "deezer": "Drake",           "lastfm": "Drake"},
    {"name": "Post Malone",     "deezer": "Post Malone",     "lastfm": "Post Malone"},
    {"name": "Playboi Carti",   "deezer": "Playboi Carti",   "lastfm": "Playboi Carti"},
    {"name": "Lil Uzi Vert",    "deezer": "Lil Uzi Vert",    "lastfm": "Lil Uzi Vert"},
    {"name": "The Weeknd",      "deezer": "The Weeknd",      "lastfm": "The Weeknd"},
    {"name": "Kendrick Lamar",  "deezer": "Kendrick Lamar",  "lastfm": "Kendrick Lamar"},
    {"name": "Tyler the Creator","deezer": "Tyler, the Creator","lastfm": "Tyler, the Creator"},
    {"name": "Frank Ocean",     "deezer": "Frank Ocean",     "lastfm": "Frank Ocean"},
    {"name": "A$AP Rocky",      "deezer": "A$AP Rocky",      "lastfm": "A$AP Rocky"},
    {"name": "Bones",           "deezer": "Bones",           "lastfm": "Bones"},
    {"name": "Ghostemane",      "deezer": "Ghostemane",      "lastfm": "Ghostemane"},
    {"name": "Night Lovell",    "deezer": "Night Lovell",    "lastfm": "Night Lovell"},
    {"name": "Bladee",          "deezer": "Bladee",          "lastfm": "Bladee"},
    {"name": "Ecco2k",          "deezer": "Ecco2k",          "lastfm": "Ecco2k"},
    {"name": "Lil Tracy",       "deezer": "Lil Tracy",       "lastfm": "Lil Tracy"},
    {"name": "Cold Hart",       "deezer": "Cold Hart",       "lastfm": "Cold Hart"},
    {"name": "Pouya",           "deezer": "Pouya",           "lastfm": "Pouya"},
    {"name": "$uicideboy$",     "deezer": "$uicideboy$",     "lastfm": "$uicideboy$"},
    {"name": "Yung Lean",       "deezer": "Yung Lean",       "lastfm": "Yung Lean"},
    {"name": "Lil Baby",        "deezer": "Lil Baby",        "lastfm": "Lil Baby"},
    {"name": "Gunna",           "deezer": "Gunna",           "lastfm": "Gunna"},
    {"name": "Young Thug",      "deezer": "Young Thug",      "lastfm": "Young Thug"},
    {"name": "Future",          "deezer": "Future",          "lastfm": "Future"},
    {"name": "Roddy Ricch",     "deezer": "Roddy Ricch",     "lastfm": "Roddy Ricch"},
    {"name": "NBA YoungBoy",    "deezer": "NBA YoungBoy",    "lastfm": "NBA YoungBoy"},
    {"name": "Polo G",          "deezer": "Polo G",          "lastfm": "Polo G"},
    {"name": "Pop Smoke",       "deezer": "Pop Smoke",       "lastfm": "Pop Smoke"},
    {"name": "6ix9ine",         "deezer": "6ix9ine",         "lastfm": "6ix9ine"},
    {"name": "Trippie Redd",    "deezer": "Trippie Redd",    "lastfm": "Trippie Redd"},
    {"name": "Ski Mask",        "deezer": "Ski Mask the Slump God","lastfm": "Ski Mask the Slump God"},
    {"name": "Lil Durk",        "deezer": "Lil Durk",        "lastfm": "Lil Durk"},
    {"name": "Kodak Black",     "deezer": "Kodak Black",     "lastfm": "Kodak Black"},
    {"name": "Cardi B",         "deezer": "Cardi B",         "lastfm": "Cardi B"},
    {"name": "Nicki Minaj",     "deezer": "Nicki Minaj",     "lastfm": "Nicki Minaj"},
    {"name": "Megan Thee Stallion","deezer":"Megan Thee Stallion","lastfm":"Megan Thee Stallion"},
    {"name": "City Girls",      "deezer": "City Girls",      "lastfm": "City Girls"},
    {"name": "Eminem",          "deezer": "Eminem",          "lastfm": "Eminem"},
    {"name": "Kanye West",      "deezer": "Kanye West",      "lastfm": "Kanye West"},
    {"name": "Jay-Z",           "deezer": "Jay-Z",           "lastfm": "Jay-Z"},
    {"name": "2Pac",            "deezer": "2Pac",            "lastfm": "2Pac"},
    {"name": "Biggie",          "deezer": "The Notorious B.I.G.","lastfm":"The Notorious B.I.G."},
    {"name": "Snoop Dogg",      "deezer": "Snoop Dogg",      "lastfm": "Snoop Dogg"},
    {"name": "Dr. Dre",         "deezer": "Dr. Dre",         "lastfm": "Dr. Dre"},
    {"name": "Ice Cube",        "deezer": "Ice Cube",        "lastfm": "Ice Cube"},
    {"name": "DMX",             "deezer": "DMX",             "lastfm": "DMX"},
    {"name": "50 Cent",         "deezer": "50 Cent",         "lastfm": "50 Cent"},
    {"name": "Lil Wayne",       "deezer": "Lil Wayne",       "lastfm": "Lil Wayne"},
    {"name": "Nelly",           "deezer": "Nelly",           "lastfm": "Nelly"},
    {"name": "Childish Gambino","deezer": "Childish Gambino","lastfm": "Childish Gambino"},
    {"name": "J. Cole",         "deezer": "J. Cole",         "lastfm": "J. Cole"},
    {"name": "Mac Miller",      "deezer": "Mac Miller",      "lastfm": "Mac Miller"},
    {"name": "Logic",           "deezer": "Logic",           "lastfm": "Logic"},
    {"name": "NF",              "deezer": "NF",              "lastfm": "NF"},
    {"name": "Hopsin",          "deezer": "Hopsin",          "lastfm": "Hopsin"},
    {"name": "Tech N9ne",       "deezer": "Tech N9ne",       "lastfm": "Tech N9ne"},

    # Pop
    {"name": "Billie Eilish",   "deezer": "Billie Eilish",   "lastfm": "Billie Eilish"},
    {"name": "Dua Lipa",        "deezer": "Dua Lipa",        "lastfm": "Dua Lipa"},
    {"name": "Ariana Grande",   "deezer": "Ariana Grande",   "lastfm": "Ariana Grande"},
    {"name": "Taylor Swift",    "deezer": "Taylor Swift",    "lastfm": "Taylor Swift"},
    {"name": "Ed Sheeran",      "deezer": "Ed Sheeran",      "lastfm": "Ed Sheeran"},
    {"name": "Harry Styles",    "deezer": "Harry Styles",    "lastfm": "Harry Styles"},
    {"name": "The Kid LAROI",   "deezer": "The Kid LAROI",   "lastfm": "The Kid LAROI"},
    {"name": "Olivia Rodrigo",  "deezer": "Olivia Rodrigo",  "lastfm": "Olivia Rodrigo"},
    {"name": "Justin Bieber",   "deezer": "Justin Bieber",   "lastfm": "Justin Bieber"},
    {"name": "Selena Gomez",    "deezer": "Selena Gomez",    "lastfm": "Selena Gomez"},
    {"name": "Weeknd",          "deezer": "The Weeknd",      "lastfm": "The Weeknd"},
    {"name": "SZA",             "deezer": "SZA",             "lastfm": "SZA"},
    {"name": "Khalid",          "deezer": "Khalid",          "lastfm": "Khalid"},
    {"name": "Doja Cat",        "deezer": "Doja Cat",        "lastfm": "Doja Cat"},
    {"name": "Lizzo",           "deezer": "Lizzo",           "lastfm": "Lizzo"},
    {"name": "Sam Smith",       "deezer": "Sam Smith",       "lastfm": "Sam Smith"},

    # Electronic/Alternative
    {"name": "Gorillaz",        "deezer": "Gorillaz",        "lastfm": "Gorillaz"},
    {"name": "Radiohead",       "deezer": "Radiohead",       "lastfm": "Radiohead"},
    {"name": "Arctic Monkeys",  "deezer": "Arctic Monkeys",  "lastfm": "Arctic Monkeys"},
    {"name": "Tame Impala",     "deezer": "Tame Impala",     "lastfm": "Tame Impala"},
    {"name": "Glass Animals",   "deezer": "Glass Animals",   "lastfm": "Glass Animals"},
    {"name": "Cigarettes After Sex","deezer":"Cigarettes After Sex","lastfm":"Cigarettes After Sex"},
    {"name": "The 1975",        "deezer": "The 1975",        "lastfm": "The 1975"},
    {"name": "Lana Del Rey",    "deezer": "Lana Del Rey",    "lastfm": "Lana Del Rey"},
    {"name": "Halsey",          "deezer": "Halsey",          "lastfm": "Halsey"},
    {"name": "Melanie Martinez","deezer": "Melanie Martinez","lastfm": "Melanie Martinez"},
    {"name": "Grimes",          "deezer": "Grimes",          "lastfm": "Grimes"},
    {"name": "FKA Twigs",       "deezer": "FKA twigs",       "lastfm": "FKA twigs"},
    {"name": "Portishead",      "deezer": "Portishead",      "lastfm": "Portishead"},
    {"name": "Massive Attack",  "deezer": "Massive Attack",  "lastfm": "Massive Attack"},
    {"name": "Aphex Twin",      "deezer": "Aphex Twin",      "lastfm": "Aphex Twin"},
    {"name": "Boards of Canada","deezer": "Boards of Canada","lastfm": "Boards of Canada"},
    {"name": "Burial",          "deezer": "Burial",          "lastfm": "Burial"},
    {"name": "Four Tet",        "deezer": "Four Tet",        "lastfm": "Four Tet"},
    {"name": "Jamie xx",        "deezer": "Jamie xx",        "lastfm": "Jamie xx"},
    {"name": "Nicolas Jaar",    "deezer": "Nicolas Jaar",    "lastfm": "Nicolas Jaar"},
    {"name": "James Blake",     "deezer": "James Blake",     "lastfm": "James Blake"},
    {"name": "Bon Iver",        "deezer": "Bon Iver",        "lastfm": "Bon Iver"},

    # Rock/Metal
    {"name": "Nirvana",         "deezer": "Nirvana",         "lastfm": "Nirvana"},
    {"name": "Linkin Park",     "deezer": "Linkin Park",     "lastfm": "Linkin Park"},
    {"name": "Bring Me the Horizon","deezer":"Bring Me the Horizon","lastfm":"Bring Me the Horizon"},
    {"name": "Paramore",        "deezer": "Paramore",        "lastfm": "Paramore"},
    {"name": "My Chemical Romance","deezer":"My Chemical Romance","lastfm":"My Chemical Romance"},
    {"name": "Twenty One Pilots","deezer":"twenty one pilots","lastfm":"twenty one pilots"},
    {"name": "Imagine Dragons", "deezer": "Imagine Dragons", "lastfm": "Imagine Dragons"},
    {"name": "Foo Fighters",    "deezer": "Foo Fighters",    "lastfm": "Foo Fighters"},
    {"name": "Red Hot Chili Peppers","deezer":"Red Hot Chili Peppers","lastfm":"Red Hot Chili Peppers"},
    {"name": "Metallica",       "deezer": "Metallica",       "lastfm": "Metallica"},
    {"name": "Slipknot",        "deezer": "Slipknot",        "lastfm": "Slipknot"},
    {"name": "System of a Down","deezer": "System of a Down","lastfm": "System of a Down"},
    {"name": "Rammstein",       "deezer": "Rammstein",       "lastfm": "Rammstein"},
    {"name": "Кино",            "deezer": "Kino",            "lastfm": "Кино"},

    # K-Pop
    {"name": "BTS",             "deezer": "BTS",             "lastfm": "BTS"},
    {"name": "BLACKPINK",       "deezer": "BLACKPINK",       "lastfm": "BLACKPINK"},
    {"name": "Stray Kids",      "deezer": "Stray Kids",      "lastfm": "Stray Kids"},
    {"name": "aespa",           "deezer": "aespa",           "lastfm": "aespa"},
    {"name": "NewJeans",        "deezer": "NewJeans",        "lastfm": "NewJeans"},
]

# ─── Config ───────────────────────────────────────────────────────────────────

BASE_DIR    = Path(__file__).parent.parent
DATA_DIR    = BASE_DIR / "scripts" / "data"
DB_PATH     = DATA_DIR / "theremusic.db"
PREVIEW_DIR = DATA_DIR / "previews"
JSON_DIR    = DATA_DIR / "json"

LASTFM_KEY      = "YOUR_LASTFM_KEY"   # get free at last.fm/api
MAX_WORKERS     = 8
DEEZER_DELAY    = 0.3
ITUNES_DELAY    = 0.4
TRACKS_PER_ARTIST = 50

SCHEMA = """
CREATE TABLE IF NOT EXISTS artists (
    id TEXT PRIMARY KEY, name TEXT NOT NULL, deezer_id INTEGER,
    itunes_id INTEGER, lastfm_url TEXT, genre TEXT, photo_url TEXT,
    header_url TEXT, bio TEXT, followers INTEGER DEFAULT 0,
    popularity INTEGER DEFAULT 0, fetched_at TEXT
);
CREATE TABLE IF NOT EXISTS albums (
    id TEXT PRIMARY KEY, title TEXT NOT NULL, artist_id TEXT,
    artist_name TEXT, deezer_id INTEGER, itunes_id INTEGER,
    artwork_url TEXT, artwork_large TEXT, release_date TEXT,
    track_count INTEGER DEFAULT 0, genre TEXT, label TEXT, source TEXT
);
CREATE TABLE IF NOT EXISTS tracks (
    id TEXT PRIMARY KEY, title TEXT NOT NULL, artist_id TEXT,
    artist_name TEXT NOT NULL, album_id TEXT, album_title TEXT,
    deezer_id INTEGER, itunes_track_id INTEGER, artwork_url TEXT,
    preview_url TEXT, preview_file TEXT, duration_ms INTEGER DEFAULT 0,
    track_number INTEGER, disc_number INTEGER, genre TEXT,
    release_date TEXT, is_explicit INTEGER DEFAULT 0,
    rank INTEGER DEFAULT 0, bpm REAL, source TEXT, fetched_at TEXT
);
CREATE TABLE IF NOT EXISTS similar_artists (
    artist_id TEXT, similar_id TEXT, weight REAL DEFAULT 1.0,
    PRIMARY KEY(artist_id, similar_id)
);
CREATE INDEX IF NOT EXISTS idx_tracks_artist ON tracks(artist_id);
CREATE INDEX IF NOT EXISTS idx_tracks_album  ON tracks(album_id);
CREATE INDEX IF NOT EXISTS idx_albums_artist ON albums(artist_id);
CREATE INDEX IF NOT EXISTS idx_tracks_genre  ON tracks(genre);
"""

lock  = threading.Lock()
stats = {"artists": 0, "albums": 0, "tracks": 0, "previews": 0, "errors": 0}

def log(msg, lvl="INFO"):
    ts = datetime.now().strftime("%H:%M:%S")
    icons = {"INFO": "✅", "WARN": "⚠️ ", "ERR": "❌", "DL": "⬇️ ", "API": "🔍"}
    print(f"[{ts}] {icons.get(lvl,'•')} {msg}", flush=True)

def fetch_json(url, retries=3, delay=0.3):
    for attempt in range(retries):
        try:
            req = Request(url, headers={"User-Agent": "THERE-Music/2.0"})
            with urlopen(req, timeout=20) as r:
                return json.loads(r.read().decode("utf-8"))
        except Exception as e:
            if attempt < retries - 1:
                time.sleep(2 ** attempt)
            else:
                log(f"Fetch failed: {url[:70]} — {e}", "ERR")
    return None

def make_id(prefix, val):
    return f"{prefix}_{hashlib.md5(str(val).encode()).hexdigest()[:10]}"

def artwork_hq(url):
    if not url:
        return None
    return (url.replace("100x100bb", "600x600bb")
               .replace("100x100", "600x600")
               .replace("/56x56-", "/500x500-")
               .replace("/250x250-", "/500x500-"))

# ─── Deezer API ───────────────────────────────────────────────────────────────

def deezer_search_artist(name):
    url = f"https://api.deezer.com/search/artist?q={quote(name)}&limit=5"
    data = fetch_json(url)
    time.sleep(DEEZER_DELAY)
    if not data or "data" not in data:
        return None
    for r in data["data"]:
        if name.lower() in r.get("name", "").lower():
            return r
    return data["data"][0] if data["data"] else None

def deezer_artist_top(artist_id, limit=50):
    url = f"https://api.deezer.com/artist/{artist_id}/top?limit={limit}"
    data = fetch_json(url)
    time.sleep(DEEZER_DELAY)
    return data.get("data", []) if data else []

def deezer_artist_albums(artist_id, limit=50):
    url = f"https://api.deezer.com/artist/{artist_id}/albums?limit={limit}"
    data = fetch_json(url)
    time.sleep(DEEZER_DELAY)
    return data.get("data", []) if data else []

def deezer_album_tracks(album_id):
    url = f"https://api.deezer.com/album/{album_id}/tracks?limit=50"
    data = fetch_json(url)
    time.sleep(DEEZER_DELAY)
    return data.get("data", []) if data else []

def deezer_related_artists(artist_id):
    url = f"https://api.deezer.com/artist/{artist_id}/related?limit=10"
    data = fetch_json(url)
    time.sleep(DEEZER_DELAY)
    return data.get("data", []) if data else []

# ─── iTunes API ───────────────────────────────────────────────────────────────

def itunes_search(term, entity="song", limit=50):
    params = urlencode({"term": term, "entity": entity, "limit": min(limit, 200), "media": "music"})
    data = fetch_json(f"https://itunes.apple.com/search?{params}")
    time.sleep(ITUNES_DELAY)
    return (data or {}).get("results", [])

# ─── Last.fm API ──────────────────────────────────────────────────────────────

def lastfm_artist_info(name):
    if LASTFM_KEY == "YOUR_LASTFM_KEY":
        return None
    params = urlencode({"method": "artist.getinfo", "artist": name,
                        "api_key": LASTFM_KEY, "format": "json"})
    data = fetch_json(f"https://ws.audioscrobbler.com/2.0/?{params}")
    time.sleep(0.3)
    return (data or {}).get("artist")

# ─── Process Artist ───────────────────────────────────────────────────────────

def process_artist(entry, conn):
    name       = entry["name"]
    dz_name    = entry.get("deezer", name)
    lfm_name   = entry.get("lastfm", name)

    log(f"Processing: {name}", "API")

    artist_id  = make_id("artist", name)
    deezer_id  = None
    photo_url  = None
    followers  = 0
    popularity = 0
    bio        = None
    genre      = None

    # Deezer artist search
    dz_artist = deezer_search_artist(dz_name)
    if dz_artist:
        deezer_id  = dz_artist.get("id")
        photo_url  = dz_artist.get("picture_xl") or dz_artist.get("picture_big") or dz_artist.get("picture_medium")
        followers  = dz_artist.get("nb_fan", 0)
        popularity = dz_artist.get("nb_fan", 0) // 10000

    # Last.fm bio
    lfm = lastfm_artist_info(lfm_name)
    if lfm:
        raw_bio = lfm.get("bio", {}).get("summary", "")
        bio = raw_bio.split("<a href")[0].strip() if raw_bio else None
        tags = lfm.get("tags", {}).get("tag", [])
        if tags:
            genre = tags[0].get("name") if isinstance(tags[0], dict) else None

    with lock:
        conn.execute("""
            INSERT OR REPLACE INTO artists
            (id,name,deezer_id,genre,photo_url,bio,followers,popularity,fetched_at)
            VALUES(?,?,?,?,?,?,?,?,?)
        """, (artist_id, name, deezer_id, genre, photo_url, bio, followers, popularity,
              datetime.now().isoformat()))
        conn.commit()
        stats["artists"] += 1

    tracks_added = 0
    albums_seen  = set()

    # ── Deezer top tracks ────────────────────────────────────────────────────
    if deezer_id:
        dz_tracks = deezer_artist_top(deezer_id, limit=TRACKS_PER_ARTIST)
        for rank, t in enumerate(dz_tracks, 1):
            album_dz  = t.get("album", {})
            album_title = album_dz.get("title", "Unknown Album")
            album_id  = make_id("album", f"dz_{album_dz.get('id', album_title)}_{name}")
            artwork   = artwork_hq(album_dz.get("cover_xl") or album_dz.get("cover_big") or album_dz.get("cover_medium"))

            if album_id not in albums_seen:
                albums_seen.add(album_id)
                with lock:
                    conn.execute("""
                        INSERT OR IGNORE INTO albums
                        (id,title,artist_id,artist_name,deezer_id,artwork_url,artwork_large,source)
                        VALUES(?,?,?,?,?,?,?,'deezer')
                    """, (album_id, album_title, artist_id, name,
                          album_dz.get("id"), artwork, artwork))
                    conn.commit()
                    stats["albums"] += 1

            track_id = make_id("track", f"dz_{t.get('id', t.get('title', '')+'_'+name)}")
            with lock:
                conn.execute("""
                    INSERT OR REPLACE INTO tracks
                    (id,title,artist_id,artist_name,album_id,album_title,deezer_id,
                     artwork_url,preview_url,duration_ms,is_explicit,rank,source,fetched_at)
                    VALUES(?,?,?,?,?,?,?,?,?,?,?,?,'deezer',?)
                """, (track_id, t.get("title","Unknown"), artist_id, name,
                      album_id, album_title, t.get("id"),
                      artwork, t.get("preview",""),
                      (t.get("duration",0))*1000,
                      1 if t.get("explicit_lyrics") else 0,
                      rank, datetime.now().isoformat()))
                conn.commit()
                stats["tracks"] += 1
                tracks_added += 1

        # Deezer albums → fetch all tracks
        dz_albums = deezer_artist_albums(deezer_id, limit=20)
        for alb in dz_albums:
            alb_tracks = deezer_album_tracks(alb["id"])
            artwork = artwork_hq(alb.get("cover_xl") or alb.get("cover_big"))
            album_id = make_id("album", f"dz_full_{alb['id']}_{name}")
            if album_id not in albums_seen:
                albums_seen.add(album_id)
                with lock:
                    conn.execute("""
                        INSERT OR IGNORE INTO albums
                        (id,title,artist_id,artist_name,deezer_id,artwork_url,artwork_large,
                         release_date,track_count,genre,label,source)
                        VALUES(?,?,?,?,?,?,?,?,?,?,?,'deezer')
                    """, (album_id, alb.get("title","Unknown"), artist_id, name,
                          alb["id"], artwork, artwork,
                          alb.get("release_date",""),
                          alb.get("nb_tracks",0),
                          alb.get("genre_id",""), alb.get("label","")))
                    conn.commit()
                    stats["albums"] += 1

            for tn, t in enumerate(alb_tracks, 1):
                track_id = make_id("track", f"dz_alb_{t.get('id','')}")
                with lock:
                    conn.execute("""
                        INSERT OR IGNORE INTO tracks
                        (id,title,artist_id,artist_name,album_id,album_title,deezer_id,
                         artwork_url,preview_url,duration_ms,track_number,is_explicit,source,fetched_at)
                        VALUES(?,?,?,?,?,?,?,?,?,?,?,?,'deezer',?)
                    """, (track_id, t.get("title","Unknown"), artist_id, name,
                          album_id, alb.get("title",""), t.get("id"),
                          artwork, t.get("preview",""),
                          (t.get("duration",0))*1000, tn,
                          1 if t.get("explicit_lyrics") else 0,
                          datetime.now().isoformat()))
                    conn.commit()
                    stats["tracks"] += 1
                    tracks_added += 1

    # ── iTunes fallback (for artists not found on Deezer) ────────────────────
    if tracks_added < 5:
        it_results = itunes_search(name, entity="song", limit=TRACKS_PER_ARTIST)
        for r in it_results:
            if r.get("wrapperType") != "track" and r.get("kind") != "song":
                continue
            alb_title = r.get("collectionName","Unknown Album")
            album_id  = make_id("album", f"it_{r.get('collectionId',alb_title)}_{name}")
            artwork   = artwork_hq(r.get("artworkUrl100",""))

            if album_id not in albums_seen:
                albums_seen.add(album_id)
                with lock:
                    conn.execute("""
                        INSERT OR IGNORE INTO albums
                        (id,title,artist_id,artist_name,itunes_id,artwork_url,artwork_large,
                         release_date,track_count,genre,source)
                        VALUES(?,?,?,?,?,?,?,?,?,?,'itunes')
                    """, (album_id, alb_title, artist_id, r.get("artistName",name),
                          r.get("collectionId"), artwork, artwork,
                          r.get("releaseDate",""), r.get("trackCount",0),
                          r.get("primaryGenreName","")))
                    conn.commit()
                    stats["albums"] += 1

            track_id = make_id("track", f"it_{r.get('trackId',r.get('trackName','')+'_'+name)}")
            with lock:
                conn.execute("""
                    INSERT OR IGNORE INTO tracks
                    (id,title,artist_id,artist_name,album_id,album_title,itunes_track_id,
                     artwork_url,preview_url,duration_ms,track_number,disc_number,genre,
                     release_date,is_explicit,source,fetched_at)
                    VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,'itunes',?)
                """, (track_id, r.get("trackName","Unknown"), artist_id,
                      r.get("artistName",name), album_id, alb_title,
                      r.get("trackId"), artwork, r.get("previewUrl",""),
                      r.get("trackTimeMillis",0),
                      r.get("trackNumber"), r.get("discNumber"),
                      r.get("primaryGenreName",""),
                      r.get("releaseDate",""),
                      1 if r.get("trackExplicitness")=="explicit" else 0,
                      datetime.now().isoformat()))
                conn.commit()
                stats["tracks"] += 1
                tracks_added += 1

    log(f"  ✓ {name}: {tracks_added} tracks, {len(albums_seen)} albums")
    return artist_id

# ─── Preview Downloader ───────────────────────────────────────────────────────

def safe_name(s):
    return "".join(c if c.isalnum() or c in " -_." else "_" for c in str(s))[:70]

def download_one(row):
    track_id, title, artist, preview_url = row
    if not preview_url:
        return None
    fname = PREVIEW_DIR / f"{safe_name(artist)} - {safe_name(title)}.m4a"
    if fname.exists() and fname.stat().st_size > 1000:
        return str(fname)
    try:
        urlretrieve(preview_url, fname)
        if fname.stat().st_size < 500:
            fname.unlink()
            return None
        with lock:
            stats["previews"] += 1
        return str(fname)
    except Exception:
        with lock:
            stats["errors"] += 1
        return None

def download_previews(conn):
    log("Downloading 30s previews (parallel)...")
    rows = conn.execute(
        "SELECT id,title,artist_name,preview_url FROM tracks "
        "WHERE preview_url!='' AND preview_url IS NOT NULL "
        "AND (preview_file IS NULL OR preview_file='')"
    ).fetchall()
    log(f"  {len(rows)} previews queued")
    results = {}
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as ex:
        futures = {ex.submit(download_one, r): r[0] for r in rows}
        for f in as_completed(futures):
            tid = futures[f]
            path = f.result()
            if path:
                results[tid] = path
    for tid, path in results.items():
        conn.execute("UPDATE tracks SET preview_file=? WHERE id=?", (path, tid))
    conn.commit()
    log(f"  ✓ {len(results)} previews downloaded")

# ─── JSON Export ──────────────────────────────────────────────────────────────

def export_json(conn):
    log("Exporting JSON...")
    JSON_DIR.mkdir(exist_ok=True)

    def rows_to_list(sql):
        cur = conn.execute(sql)
        cols = [d[0] for d in cur.description]
        return [dict(zip(cols, row)) for row in cur.fetchall()]

    artists = rows_to_list("SELECT * FROM artists ORDER BY name")
    albums  = rows_to_list("SELECT * FROM albums  ORDER BY artist_name, release_date DESC")
    tracks  = rows_to_list("SELECT * FROM tracks  ORDER BY artist_name, rank, track_number")

    for name, data in [("artists", artists), ("albums", albums), ("tracks", tracks)]:
        p = JSON_DIR / f"{name}.json"
        with open(p, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        log(f"  {p.name}: {len(data)} items ({p.stat().st_size//1024} KB)")

    seed = {"artists": artists, "albums": albums, "tracks": tracks,
            "generated_at": datetime.now().isoformat(),
            "stats": {"artists": len(artists), "albums": len(albums), "tracks": len(tracks)}}
    sp = JSON_DIR / "seed.json"
    with open(sp, "w", encoding="utf-8") as f:
        json.dump(seed, f, ensure_ascii=False, separators=(",", ":"))
    log(f"  seed.json: {sp.stat().st_size//1024} KB")

    with open(JSON_DIR / "stats.json", "w") as f:
        json.dump(seed["stats"], f, indent=2)

# ─── Report ───────────────────────────────────────────────────────────────────

def report(conn):
    print("\n" + "═"*60)
    print("  THERE Music v2 — Final Report")
    print("═"*60)
    for label, sql in [
        ("Artists",         "SELECT COUNT(*) FROM artists"),
        ("Albums",          "SELECT COUNT(*) FROM albums"),
        ("Tracks total",    "SELECT COUNT(*) FROM tracks"),
        ("With preview URL","SELECT COUNT(*) FROM tracks WHERE preview_url!=''"),
        ("Preview files",   "SELECT COUNT(*) FROM tracks WHERE preview_file IS NOT NULL AND preview_file!=''"),
        ("Deezer tracks",   "SELECT COUNT(*) FROM tracks WHERE source='deezer'"),
        ("iTunes tracks",   "SELECT COUNT(*) FROM tracks WHERE source='itunes'"),
    ]:
        val = conn.execute(sql).fetchone()[0]
        print(f"  {label:<22} {val:>6}")
    print()
    print("  Top 15 artists by track count:")
    for r in conn.execute("""
        SELECT artist_name, COUNT(*) c FROM tracks
        GROUP BY artist_name ORDER BY c DESC LIMIT 15
    """).fetchall():
        print(f"    {r[0]:<30} {r[1]:>4} tracks")
    print("═"*60)
    print(f"  DB: {DB_PATH} ({DB_PATH.stat().st_size//1024} KB)")
    print("═"*60 + "\n")

# ─── Main ─────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--no-download",  action="store_true")
    parser.add_argument("--artists",      nargs="+")
    parser.add_argument("--limit",        type=int, default=50)
    parser.add_argument("--lastfm-key",   default=LASTFM_KEY)
    args = parser.parse_args()

    global TRACKS_PER_ARTIST, LASTFM_KEY
    TRACKS_PER_ARTIST = args.limit
    if args.lastfm_key != "YOUR_LASTFM_KEY":
        LASTFM_KEY = args.lastfm_key

    artist_list = ARTISTS
    if args.artists:
        names = [a.lower() for a in args.artists]
        artist_list = [e for e in ARTISTS if e["name"].lower() in names]

    DATA_DIR.mkdir(parents=True, exist_ok=True)
    PREVIEW_DIR.mkdir(exist_ok=True)
    JSON_DIR.mkdir(exist_ok=True)

    conn = sqlite3.connect(str(DB_PATH), check_same_thread=False)
    conn.row_factory = sqlite3.Row
    conn.executescript(SCHEMA)
    conn.commit()

    log(f"THERE Music Seeder v2")
    log(f"Artists: {len(artist_list)} | Tracks/artist: {TRACKS_PER_ARTIST}")
    log(f"Sources: Deezer + iTunes | DB: {DB_PATH}")

    for entry in artist_list:
        try:
            process_artist(entry, conn)
        except Exception as e:
            log(f"Failed: {entry['name']} — {e}", "ERR")
            stats["errors"] += 1

    if not args.no_download:
        download_previews(conn)

    export_json(conn)
    report(conn)
    conn.close()

    log(f"DONE — Artists:{stats['artists']} Albums:{stats['albums']} "
        f"Tracks:{stats['tracks']} Previews:{stats['previews']} Errors:{stats['errors']}")

if __name__ == "__main__":
    main()
