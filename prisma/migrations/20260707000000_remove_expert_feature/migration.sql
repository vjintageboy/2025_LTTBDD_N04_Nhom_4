-- Remove expert / appointment feature (feature removed from the app)

-- Reassign expert users to plain users (the 'expert' enum value is kept, just unused).
-- The prevent_self_role_change trigger blocks role edits for non-admins, so disable
-- it just for this one-off reassignment, then re-enable it within the same transaction.
ALTER TABLE "users" DISABLE TRIGGER "trg_prevent_self_role_change";
UPDATE "users" SET "role" = 'user' WHERE "role" = 'expert';
ALTER TABLE "users" ENABLE TRIGGER "trg_prevent_self_role_change";

-- Drop RLS policies on `users` that reference the expert/appointment tables
-- (otherwise the DROP TABLE statements below fail).
DROP POLICY IF EXISTS "users_read_appointment_counterpart" ON "users";
DROP POLICY IF EXISTS "users_read_approved_expert_profile" ON "users";

-- Drop views depending on the expert/appointment tables (none are used by the app).
DROP VIEW IF EXISTS "appointments_by_status";
DROP VIEW IF EXISTS "top_experts";
DROP VIEW IF EXISTS "experts_by_specialization";
DROP VIEW IF EXISTS "dashboard_stats";

-- Drop the orphaned appointment link from chat rooms (rooms + messages are preserved).
ALTER TABLE "chat_rooms" DROP COLUMN "appointment_id";

-- Drop expert/appointment tables (their own RLS policies drop automatically).
DROP TABLE "appointments";
DROP TABLE "expert_availability";
DROP TABLE "experts";

-- Drop enums used only by the appointments table.
DROP TYPE "appointment_status";
DROP TYPE "call_type";
