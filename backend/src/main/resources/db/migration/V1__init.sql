-- V1: MVP schema. Naming per database-design skill:
-- tables plural snake_case, columns singular, FK {table}_id, uq_/idx_ prefixes.
-- UUID PKs (gen_random_uuid), TIMESTAMPTZ, constraints over code.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  name VARCHAR(100) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_users_email UNIQUE (email),
  CONSTRAINT chk_users_email CHECK (email LIKE '%@%'),
  CONSTRAINT chk_users_name CHECK (char_length(name) >= 2)
);

CREATE TABLE notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  folder VARCHAR(80) NOT NULL DEFAULT 'Inbox',
  title VARCHAR(200) NOT NULL DEFAULT 'Untitled',
  body TEXT NOT NULL DEFAULT '',
  is_favorite BOOLEAN NOT NULL DEFAULT FALSE,
  status VARCHAR(16) NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_notes_status CHECK (status IN ('active', 'draft', 'trashed'))
);

-- 1NF for tags: one row per tag (frontend Note.tags is List<String>, lowercase, no '#').
CREATE TABLE note_tags (
  note_id UUID NOT NULL REFERENCES notes (id) ON DELETE CASCADE,
  tag VARCHAR(50) NOT NULL,
  CONSTRAINT pk_note_tags PRIMARY KEY (note_id, tag)
);

CREATE INDEX idx_notes_owner ON notes (owner_id);
CREATE INDEX idx_notes_owner_updated ON notes (owner_id, updated_at DESC);
CREATE INDEX idx_note_tags_note ON note_tags (note_id);
