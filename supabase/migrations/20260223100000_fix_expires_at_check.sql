-- Fix: check_and_increment_usage must validate subscriptions.expires_at
-- Without this, users with expired subscriptions keep Pro access forever.

create or replace function public.check_and_increment_usage(p_user_id uuid)
returns json
language plpgsql
security definer
as $$
declare
  v_profile public.profiles%rowtype;
  v_subscription_valid boolean := false;
begin
  -- Get profile with lock
  select * into v_profile
  from public.profiles
  where id = p_user_id
  for update;

  if not found then
    return json_build_object('allowed', false, 'error', 'User not found');
  end if;

  -- Pro users: check BOTH plan status AND subscription expiry
  if v_profile.plan = 'pro' and v_profile.subscription_status = 'active' then
    -- Verify subscription hasn't expired
    select exists(
      select 1 from public.subscriptions
      where user_id = p_user_id
        and status = 'active'
        and (expires_at is null or expires_at > now())
    ) into v_subscription_valid;

    if v_subscription_valid then
      return json_build_object('allowed', true, 'plan', 'pro', 'remaining', -1);
    else
      -- Subscription expired — auto-downgrade to free
      update public.profiles
      set plan = 'free',
          subscription_status = 'expired'
      where id = p_user_id;

      -- Also mark subscription as expired
      update public.subscriptions
      set status = 'expired'
      where user_id = p_user_id
        and status = 'active'
        and expires_at <= now();

      -- Fall through to free tier check below
      v_profile.plan := 'free';
    end if;
  end if;

  -- Free users: check if reset needed
  if v_profile.free_transcriptions_reset_at <= now() then
    update public.profiles
    set free_transcriptions_used = 0,
        free_transcriptions_reset_at = date_trunc('month', now()) + interval '1 month'
    where id = p_user_id;
    v_profile.free_transcriptions_used := 0;
  end if;

  -- Free users: check limit
  if v_profile.free_transcriptions_used >= 100 then
    return json_build_object(
      'allowed', false,
      'error', 'free_limit_reached',
      'used', v_profile.free_transcriptions_used,
      'limit', 100,
      'resets_at', v_profile.free_transcriptions_reset_at
    );
  end if;

  -- Increment counter
  update public.profiles
  set free_transcriptions_used = free_transcriptions_used + 1
  where id = p_user_id;

  return json_build_object(
    'allowed', true,
    'plan', 'free',
    'used', v_profile.free_transcriptions_used + 1,
    'remaining', 100 - (v_profile.free_transcriptions_used + 1),
    'limit', 100
  );
end;
$$;
