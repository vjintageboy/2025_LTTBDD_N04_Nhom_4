-- Add an optional photo to mood entries (base64 string or remote URL),
-- mirroring posts.image_url. Nullable so existing rows and photo-less logs
-- are unaffected.
ALTER TABLE "mood_entries" ADD COLUMN "image_url" TEXT;
