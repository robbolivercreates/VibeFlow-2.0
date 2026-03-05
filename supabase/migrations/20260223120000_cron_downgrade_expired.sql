-- pg_cron job: auto-downgrade expired Pro subscriptions every 6 hours.
-- Safety net for: webhook failures, users who never transcribe, edge cases.

-- Enable pg_cron extension (available on Supabase by default)
create extension if not exists pg_cron;

-- Grant usage to postgres role (required for scheduling)
grant usage on schema cron to postgres;

-- Create the downgrade function
create or replace function public.downgrade_expired_subscriptions()
returns void
language plpgsql
security definer
as $$
declare
  v_count integer := 0;
begin
  -- Case 1: Pro users with expired subscriptions in subscriptions table
  update public.profiles p
  set plan = 'free',
      subscription_status = 'expired',
      updated_at = now()
  where p.plan = 'pro'
    and p.subscription_status = 'active'
    and not exists (
      select 1 from public.subscriptions s
      where s.user_id = p.id
        and s.status = 'active'
        and (s.expires_at is null or s.expires_at > now())
    );
  get diagnostics v_count = row_count;

  if v_count > 0 then
    raise notice '[cron] Downgraded % expired Pro users (no valid subscription)', v_count;
  end if;

  -- Case 2: Pro users with cancelled/expired status but plan still says 'pro'
  -- (should never happen, but safety net)
  update public.profiles
  set plan = 'free',
      updated_at = now()
  where plan = 'pro'
    and subscription_status in ('cancelled', 'expired', 'refunded');
  get diagnostics v_count = row_count;

  if v_count > 0 then
    raise notice '[cron] Fixed % inconsistent profiles (pro plan but cancelled/expired status)', v_count;
  end if;

  -- Case 3: Mark expired subscriptions in subscriptions table
  update public.subscriptions
  set status = 'expired'
  where status = 'active'
    and expires_at is not null
    and expires_at <= now();
  get diagnostics v_count = row_count;

  if v_count > 0 then
    raise notice '[cron] Marked % subscriptions as expired', v_count;
  end if;
end;
$$;

-- Schedule: run every 6 hours
select cron.schedule(
  'downgrade-expired-subscriptions',
  '0 */6 * * *',  -- At minute 0 of every 6th hour
  $$select public.downgrade_expired_subscriptions()$$
);

-- Also create a monthly reset job for free_transcriptions_used
-- This resets counters for ALL users at the start of each month
select cron.schedule(
  'reset-free-transcriptions-monthly',
  '0 0 1 * *',  -- At midnight on the 1st of each month
  $$update public.profiles
    set free_transcriptions_used = 0,
        free_transcriptions_reset_at = date_trunc('month', now()) + interval '1 month',
        updated_at = now()
    where plan = 'free' or subscription_status != 'active'$$
);
