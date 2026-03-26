-- Haven Database Schema
-- SQLite with FTS5 for full-text search

PRAGMA journal_mode = WAL;
PRAGMA foreign_keys = ON;

-- Notes
CREATE TABLE IF NOT EXISTS notes (
    id              TEXT PRIMARY KEY NOT NULL,
    title           TEXT NOT NULL DEFAULT '',
    body_html       TEXT NOT NULL DEFAULT '',
    body_plaintext  TEXT NOT NULL DEFAULT '',
    is_pinned       INTEGER NOT NULL DEFAULT 0,
    is_deleted      INTEGER NOT NULL DEFAULT 0,
    created_at      TEXT NOT NULL,
    updated_at      TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_notes_updated_at ON notes(updated_at);
CREATE INDEX IF NOT EXISTS idx_notes_is_deleted ON notes(is_deleted);
CREATE INDEX IF NOT EXISTS idx_notes_is_pinned ON notes(is_pinned);

-- Full-Text Search
CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(
    title,
    body_plaintext,
    content='notes',
    content_rowid='rowid'
);

CREATE TRIGGER IF NOT EXISTS notes_ai AFTER INSERT ON notes BEGIN
    INSERT INTO notes_fts(rowid, title, body_plaintext)
    VALUES (new.rowid, new.title, new.body_plaintext);
END;

CREATE TRIGGER IF NOT EXISTS notes_ad AFTER DELETE ON notes BEGIN
    INSERT INTO notes_fts(notes_fts, rowid, title, body_plaintext)
    VALUES ('delete', old.rowid, old.title, old.body_plaintext);
END;

CREATE TRIGGER IF NOT EXISTS notes_au AFTER UPDATE ON notes BEGIN
    INSERT INTO notes_fts(notes_fts, rowid, title, body_plaintext)
    VALUES ('delete', old.rowid, old.title, old.body_plaintext);
    INSERT INTO notes_fts(rowid, title, body_plaintext)
    VALUES (new.rowid, new.title, new.body_plaintext);
END;

-- Tasks
CREATE TABLE IF NOT EXISTS tasks (
    id              TEXT PRIMARY KEY NOT NULL,
    note_id         TEXT NOT NULL,
    text            TEXT NOT NULL DEFAULT '',
    is_completed    INTEGER NOT NULL DEFAULT 0,
    position        INTEGER NOT NULL DEFAULT 0,
    created_at      TEXT NOT NULL,
    updated_at      TEXT NOT NULL,
    FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_tasks_note_id ON tasks(note_id);
CREATE INDEX IF NOT EXISTS idx_tasks_position ON tasks(note_id, position);

-- Wiki Links
CREATE TABLE IF NOT EXISTS links (
    source_note_id  TEXT NOT NULL,
    target_note_id  TEXT NOT NULL,
    link_text       TEXT NOT NULL,
    PRIMARY KEY (source_note_id, target_note_id, link_text),
    FOREIGN KEY (source_note_id) REFERENCES notes(id) ON DELETE CASCADE,
    FOREIGN KEY (target_note_id) REFERENCES notes(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_links_target ON links(target_note_id);

-- Sync Log
CREATE TABLE IF NOT EXISTS sync_log (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    entity_type     TEXT NOT NULL,
    entity_id       TEXT NOT NULL,
    operation       TEXT NOT NULL,
    timestamp       TEXT NOT NULL,
    synced_at       TEXT
);

CREATE INDEX IF NOT EXISTS idx_sync_log_unsynced ON sync_log(synced_at) WHERE synced_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_sync_log_entity ON sync_log(entity_type, entity_id);

-- App Settings
CREATE TABLE IF NOT EXISTS app_settings (
    key             TEXT PRIMARY KEY NOT NULL,
    value           TEXT NOT NULL
);

INSERT OR IGNORE INTO app_settings (key, value) VALUES ('sync_enabled', 'false');
INSERT OR IGNORE INTO app_settings (key, value) VALUES ('sync_server_url', '');
INSERT OR IGNORE INTO app_settings (key, value) VALUES ('last_sync_timestamp', '');
INSERT OR IGNORE INTO app_settings (key, value) VALUES ('theme_mode', 'system');
