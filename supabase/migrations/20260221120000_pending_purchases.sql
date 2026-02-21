-- ============================================================
-- pending_purchases: stores Eduzz purchases that arrived before
-- the user created a VoxAiGo account. When the user signs up
-- with the matching email, a trigger auto-activates their Pro.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.pending_purchases (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    email text NOT NULL,
    eduzz_transaction_id text NOT NULL,
    eduzz_product_id text,
    plan text NOT NULL DEFAULT 'pro_monthly',  -- 'pro_monthly' or 'pro_annual'
    status text NOT NULL DEFAULT 'pending',     -- 'pending' or 'claimed'
    raw_payload jsonb,                          -- full webhook payload for debugging
    created_at timestamptz DEFAULT now(),
    claimed_at timestamptz,
    claimed_by uuid REFERENCES public.profiles(id)
);

-- Index for fast lookup by email
CREATE INDEX IF NOT EXISTS idx_pending_purchases_email ON public.pending_purchases(email);
CREATE INDEX IF NOT EXISTS idx_pending_purchases_status ON public.pending_purchases(status);

-- RLS: only service_role can insert/read (webhook + trigger use admin client)
ALTER TABLE public.pending_purchases ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- Function: claim_pending_purchase
-- Called when a new profile is created (via trigger).
-- Checks if there's a pending purchase for this email and
-- activates Pro if found.
-- ============================================================

CREATE OR REPLACE FUNCTION public.claim_pending_purchase()
RETURNS TRIGGER AS $$
DECLARE
    pending RECORD;
    plan_type text;
    days_valid int;
BEGIN
    -- Look for unclaimed pending purchases matching this email
    SELECT * INTO pending
    FROM public.pending_purchases
    WHERE email = NEW.email
      AND status = 'pending'
    ORDER BY created_at DESC
    LIMIT 1;

    IF FOUND THEN
        -- Determine plan duration
        IF pending.plan = 'pro_annual' THEN
            plan_type := 'pro_annual';
            days_valid := 365;
        ELSE
            plan_type := 'pro_monthly';
            days_valid := 30;
        END IF;

        -- Activate subscription
        INSERT INTO public.subscriptions (user_id, plan, status, eduzz_transaction_id, eduzz_product_id, started_at, expires_at)
        VALUES (NEW.id, plan_type, 'active', pending.eduzz_transaction_id, pending.eduzz_product_id, now(), now() + (days_valid || ' days')::interval);

        -- Update profile to Pro
        UPDATE public.profiles
        SET plan = 'pro',
            subscription_status = 'active',
            updated_at = now()
        WHERE id = NEW.id;

        -- Mark pending purchase as claimed
        UPDATE public.pending_purchases
        SET status = 'claimed',
            claimed_at = now(),
            claimed_by = NEW.id
        WHERE id = pending.id;

        RAISE LOG 'Claimed pending purchase for %: txn=% plan=%', NEW.email, pending.eduzz_transaction_id, plan_type;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- Trigger: fires AFTER a new profile row is inserted
-- (profiles are created by the handle_new_user trigger on auth.users)
-- ============================================================

DROP TRIGGER IF EXISTS trigger_claim_pending_purchase ON public.profiles;
CREATE TRIGGER trigger_claim_pending_purchase
    AFTER INSERT ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.claim_pending_purchase();
