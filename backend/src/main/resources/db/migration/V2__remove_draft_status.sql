UPDATE notes SET status = 'active' WHERE status = 'draft';
ALTER TABLE notes DROP CONSTRAINT chk_notes_status;
ALTER TABLE notes ADD CONSTRAINT chk_notes_status CHECK (status IN ('active', 'trashed'));
