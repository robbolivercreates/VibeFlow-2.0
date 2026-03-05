-- Migration: add monthly_text_transcription_count + last_reset_date to profiles
-- Purpose: track Grátis (free) tier monthly local transcription counter server-side.
-- This enables the dashboard web to show accurate usage in real-time.

-- Add new columns to profiles
alter table public.profiles
  add column if not exists monthly_text_transcription_count integer not null default 0,
  add column if not exists last_reset_date date not null default date_trunc('month', now())::date;

-- Comment columns
comment on column public.profiles.monthly_text_transcription_count is
  'Count of local (Whisper) text-mode transcriptions used this month. Reset by pg_cron on 1st of each month.';
comment on column public.profiles.last_reset_date is
  'Date when monthly_text_transcription_count was last reset to 0.';

-- Update the existing monthly reset cron job to also reset the new counter.
-- We unschedule the old job and reschedule with the updated query.
select cron.unschedule('reset-free-transcriptions-monthly');

select cron.schedule(
  'reset-free-transcriptions-monthly',
  '0 0 1 * *',  -- At midnight on the 1st of each month
  $$update public.profiles
    set free_transcriptions_used = 0,
        monthly_text_transcription_count = 0,
        last_reset_date = date_trunc('month', now())::date,
        free_transcriptions_reset_at = date_trunc('month', now()) + interval '1 month',
        updated_at = now()
    where plan = 'free' or subscription_status != 'active'$$
);
