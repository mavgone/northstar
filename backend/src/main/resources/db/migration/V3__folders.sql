-- V3: real folders (id, owner, name, nesting). Migrate legacy folder strings,
-- then point notes at folder ids.
CREATE TABLE folders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  parent_id UUID REFERENCES folders (id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_folders_owner ON folders (owner_id);

INSERT INTO folders (owner_id, name)
SELECT DISTINCT n.owner_id, n.folder FROM notes n
WHERE n.folder IS NOT NULL AND btrim(n.folder) <> '';
INSERT INTO folders (owner_id, name)
SELECT DISTINCT u.id, 'Inbox' FROM users u
WHERE NOT EXISTS (
  SELECT 1 FROM folders f WHERE f.owner_id = u.id AND f.name = 'Inbox'
);
ALTER TABLE notes ADD COLUMN folder_id UUID REFERENCES folders (id);
UPDATE notes n SET folder_id = f.id FROM folders f
WHERE f.owner_id = n.owner_id AND f.name = n.folder;
UPDATE notes SET folder_id = (
  SELECT f.id FROM folders f
  WHERE f.owner_id = notes.owner_id AND f.name = 'Inbox'
  LIMIT 1
)
WHERE folder_id IS NULL;
ALTER TABLE notes ALTER COLUMN folder_id SET NOT NULL;
ALTER TABLE notes DROP COLUMN folder;
CREATE INDEX idx_notes_folder ON notes (folder_id);
