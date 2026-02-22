-- Enable Realtime on usage_log so the dashboard can receive live updates
-- when the Mac App inserts new transcription records.

ALTER publication supabase_realtime ADD TABLE public.usage_log;
