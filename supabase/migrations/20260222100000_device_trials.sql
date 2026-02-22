-- ============================================================
-- device_trials: tracks which devices have used the 7-day Pro
-- trial. Prevents trial abuse across multiple accounts on the
-- same hardware (device_id = SHA256 of hardware fingerprint).
-- ============================================================

CREATE TABLE IF NOT EXISTS public.device_trials (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    device_id text NOT NULL,
    user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    trial_started_at timestamptz DEFAULT now(),
    trial_ends_at timestamptz DEFAULT (now() + interval '7 days'),
    created_at timestamptz DEFAULT now()
);

-- Each device can only have one trial ever
CREATE UNIQUE INDEX IF NOT EXISTS idx_device_trials_device_id ON public.device_trials(device_id);

-- Index for user lookups
CREATE INDEX IF NOT EXISTS idx_device_trials_user_id ON public.device_trials(user_id);

-- RLS
ALTER TABLE public.device_trials ENABLE ROW LEVEL SECURITY;

-- Users can read their own trial records
CREATE POLICY "Users can read own device trials"
    ON public.device_trials FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own trial record (device_id uniqueness prevents abuse)
CREATE POLICY "Users can insert own device trial"
    ON public.device_trials FOR INSERT
    WITH CHECK (auth.uid() = user_id);
