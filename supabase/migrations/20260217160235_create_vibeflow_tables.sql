-- VibeFlow Database Schema
-- Tables: profiles, subscriptions, usage_log

-- =============================================================
-- 1. PROFILES (extends auth.users)
-- =============================================================
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  name text,
  plan text not null default 'free' check (plan in ('free', 'pro')),
  subscription_status text not null default 'none' check (subscription_status in ('none', 'active', 'cancelled', 'expired', 'past_due')),
  eduzz_email text,
  free_transcriptions_used int not null default 0,
  free_transcriptions_reset_at timestamptz not null default date_trunc('month', now()) + interval '1 month',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.profiles is 'User profiles extending Supabase auth. Stores plan info and usage counters.';

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, email, name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name', '')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Auto-update updated_at
create or replace function public.update_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_updated_at
  before update on public.profiles
  for each row execute function public.update_updated_at();

-- =============================================================
-- 2. SUBSCRIPTIONS
-- =============================================================
create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  plan text not null check (plan in ('pro_monthly', 'pro_annual')),
  status text not null default 'active' check (status in ('active', 'cancelled', 'expired', 'past_due')),
  eduzz_transaction_id text,
  eduzz_product_id text,
  started_at timestamptz not null default now(),
  expires_at timestamptz,
  cancelled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.subscriptions is 'Subscription records linked to Eduzz purchases.';

create index idx_subscriptions_user_id on public.subscriptions(user_id);
create index idx_subscriptions_status on public.subscriptions(status);
create index idx_subscriptions_eduzz_tx on public.subscriptions(eduzz_transaction_id);

create trigger subscriptions_updated_at
  before update on public.subscriptions
  for each row execute function public.update_updated_at();

-- =============================================================
-- 3. USAGE LOG
-- =============================================================
create table public.usage_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  mode text not null,
  audio_duration_seconds real,
  output_length int,
  language text,
  created_at timestamptz not null default now()
);

comment on table public.usage_log is 'Tracks each transcription for analytics and usage limits.';

create index idx_usage_log_user_id on public.usage_log(user_id);
create index idx_usage_log_created_at on public.usage_log(created_at);
create index idx_usage_log_user_month on public.usage_log(user_id, created_at);

-- =============================================================
-- 4. ROW LEVEL SECURITY (RLS)
-- =============================================================

-- Profiles: users can only read/update their own profile
alter table public.profiles enable row level security;

create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Subscriptions: users can only view their own
alter table public.subscriptions enable row level security;

create policy "Users can view own subscriptions"
  on public.subscriptions for select
  using (auth.uid() = user_id);

-- Usage log: users can only view their own
alter table public.usage_log enable row level security;

create policy "Users can view own usage"
  on public.usage_log for select
  using (auth.uid() = user_id);

-- =============================================================
-- 5. HELPER FUNCTION: Reset monthly free transcriptions
-- =============================================================
create or replace function public.reset_free_transcriptions()
returns void
language plpgsql
security definer
as $$
begin
  update public.profiles
  set
    free_transcriptions_used = 0,
    free_transcriptions_reset_at = date_trunc('month', now()) + interval '1 month'
  where plan = 'free'
    and free_transcriptions_reset_at <= now();
end;
$$;

-- =============================================================
-- 6. HELPER FUNCTION: Check and increment transcription usage
-- =============================================================
create or replace function public.check_and_increment_usage(p_user_id uuid)
returns json
language plpgsql
security definer
as $$
declare
  v_profile public.profiles%rowtype;
begin
  -- Get profile with lock
  select * into v_profile
  from public.profiles
  where id = p_user_id
  for update;

  if not found then
    return json_build_object('allowed', false, 'error', 'User not found');
  end if;

  -- Pro users: always allowed
  if v_profile.plan = 'pro' and v_profile.subscription_status = 'active' then
    return json_build_object('allowed', true, 'plan', 'pro', 'remaining', -1);
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
