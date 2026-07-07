-- Remove the chat feature (was built for user<->expert; no room-creation entry
-- point remains after the expert feature was removed).

-- Drop all chat RLS policies first. Some chat_rooms policies cross-reference
-- chat_participants, which otherwise blocks dropping the tables.
DROP POLICY IF EXISTS "chat_participants_admin_all" ON "chat_participants";
DROP POLICY IF EXISTS "chat_participants_delete_own" ON "chat_participants";
DROP POLICY IF EXISTS "chat_participants_insert_own" ON "chat_participants";
DROP POLICY IF EXISTS "chat_participants_read" ON "chat_participants";
DROP POLICY IF EXISTS "chat_participants_select_own" ON "chat_participants";
DROP POLICY IF EXISTS "chat_participants_update_own" ON "chat_participants";
DROP POLICY IF EXISTS "chat_rooms_admin_all" ON "chat_rooms";
DROP POLICY IF EXISTS "chat_rooms_delete_auth" ON "chat_rooms";
DROP POLICY IF EXISTS "chat_rooms_delete_participant" ON "chat_rooms";
DROP POLICY IF EXISTS "chat_rooms_insert_auth" ON "chat_rooms";
DROP POLICY IF EXISTS "chat_rooms_insert_authenticated" ON "chat_rooms";
DROP POLICY IF EXISTS "chat_rooms_participant_select" ON "chat_rooms";
DROP POLICY IF EXISTS "chat_rooms_participant_update" ON "chat_rooms";
DROP POLICY IF EXISTS "chat_rooms_select_auth" ON "chat_rooms";
DROP POLICY IF EXISTS "chat_rooms_select_participant" ON "chat_rooms";
DROP POLICY IF EXISTS "chat_rooms_update_auth" ON "chat_rooms";
DROP POLICY IF EXISTS "chat_rooms_update_participant" ON "chat_rooms";
DROP POLICY IF EXISTS "messages_admin_all" ON "messages";
DROP POLICY IF EXISTS "messages_insert_auth" ON "messages";
DROP POLICY IF EXISTS "messages_insert_sender" ON "messages";
DROP POLICY IF EXISTS "messages_participant_select" ON "messages";
DROP POLICY IF EXISTS "messages_select_auth" ON "messages";
DROP POLICY IF EXISTS "messages_select_participant" ON "messages";
DROP POLICY IF EXISTS "messages_sender_delete" ON "messages";
DROP POLICY IF EXISTS "messages_sender_insert" ON "messages";

-- Drop chat tables (FK-safe order; their triggers drop with them).
DROP TABLE "messages";
DROP TABLE "chat_participants";
DROP TABLE "chat_rooms";

-- Drop chat-only helper/RPC/trigger functions left behind.
DROP FUNCTION IF EXISTS public.chat_mark_room_read(p_room_id uuid, p_user_id uuid);
DROP FUNCTION IF EXISTS public.chat_on_message_insert();
DROP FUNCTION IF EXISTS public.check_user_in_room(p_room_id uuid, p_user_id uuid);
