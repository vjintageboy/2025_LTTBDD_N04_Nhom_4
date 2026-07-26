-- Swipe-to-delete and "delete all" need a DELETE policy: `notifications` had
-- only SELECT and UPDATE for regular users, so a delete would have been denied
-- by RLS and silently deleted nothing. Own rows only, the same shape as
-- posts_user_delete.
DROP POLICY IF EXISTS "notifications_user_delete" ON public.notifications;
CREATE POLICY "notifications_user_delete" ON public.notifications
  FOR DELETE TO authenticated USING ((user_id = auth.uid()));

-- Realtime: the app subscribes to `notifications` filtered by user_id, so the
-- table has to be in the publication for any event to reach the client at all.
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Under the default replica identity a DELETE event carries only the primary
-- key, so the user_id filter has nothing to match on and the deletion never
-- reaches the subscriber. FULL sends the whole old row.
ALTER TABLE public.notifications REPLICA IDENTITY FULL;
