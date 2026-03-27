-- Mission Control Schema — Run in Supabase SQL Editor
-- Project: sbirszjpnmduxnhxfnll

-- 1. AGENTS (core — referenced by most other tables)
CREATE TABLE IF NOT EXISTS public.agents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  model TEXT DEFAULT 'claude-sonnet-4-20250514',
  status TEXT DEFAULT 'offline',
  current_project_id UUID,
  current_step TEXT,
  mood TEXT DEFAULT 'gray',
  started_at TIMESTAMPTZ,
  config JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. PROJECTS
CREATE TABLE IF NOT EXISTS public.projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  type TEXT,
  status TEXT DEFAULT 'queued',
  agent_id UUID REFERENCES public.agents(id),
  vercel_url TEXT,
  vercel_project_id TEXT,
  github_repo TEXT,
  config JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. DEPLOYMENTS
CREATE TABLE IF NOT EXISTS public.deployments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES public.projects(id),
  vercel_deployment_id TEXT,
  name TEXT,
  url TEXT,
  status TEXT DEFAULT 'unknown',
  response_time_ms INTEGER,
  error_rate NUMERIC DEFAULT 0,
  lighthouse_json JSONB,
  last_checked TIMESTAMPTZ DEFAULT now(),
  deployed_at TIMESTAMPTZ DEFAULT now(),
  commit_hash TEXT,
  config JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 4. CRON JOBS
CREATE TABLE IF NOT EXISTS public.cron_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  schedule TEXT NOT NULL,
  last_run TIMESTAMPTZ,
  next_run TIMESTAMPTZ,
  status TEXT DEFAULT 'active',
  config JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 5. CRON RUNS
CREATE TABLE IF NOT EXISTS public.cron_runs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cron_job_id UUID REFERENCES public.cron_jobs(id),
  status TEXT DEFAULT 'running',
  started_at TIMESTAMPTZ DEFAULT now(),
  completed_at TIMESTAMPTZ,
  duration_seconds INTEGER,
  output TEXT,
  error TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 6. HEARTBEATS
CREATE TABLE IF NOT EXISTS public.heartbeats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id UUID REFERENCES public.agents(id),
  agent_name TEXT NOT NULL,
  status TEXT DEFAULT 'ok',
  message TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 7. GATEWAY HEALTH
CREATE TABLE IF NOT EXISTS public.gateway_health (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  response_time_ms INTEGER,
  status TEXT DEFAULT 'healthy',
  ws_connected BOOLEAN DEFAULT false,
  tls_valid BOOLEAN DEFAULT true,
  tls_expiry TIMESTAMPTZ,
  uptime_seconds BIGINT,
  version TEXT,
  agents_online INTEGER DEFAULT 0,
  active_sessions INTEGER DEFAULT 0,
  checked_at TIMESTAMPTZ DEFAULT now()
);

-- 8. AGENT ACTIVITY
CREATE TABLE IF NOT EXISTS public.agent_activity (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id UUID REFERENCES public.agents(id),
  project_id UUID REFERENCES public.projects(id),
  timestamp TIMESTAMPTZ DEFAULT now(),
  action TEXT NOT NULL,
  detail TEXT,
  severity TEXT DEFAULT 'info'
);

-- 9. ALERTS
CREATE TABLE IF NOT EXISTS public.alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT NOT NULL,
  severity TEXT DEFAULT 'info',
  message TEXT NOT NULL,
  resolved BOOLEAN DEFAULT false,
  resolved_at TIMESTAMPTZ,
  resolved_by TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 10. ALERT RULES
CREATE TABLE IF NOT EXISTS public.alert_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  condition_type TEXT NOT NULL,
  threshold NUMERIC,
  channels JSONB,
  enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 11. BUILDS
CREATE TABLE IF NOT EXISTS public.builds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES public.projects(id),
  agent_id UUID REFERENCES public.agents(id),
  model TEXT,
  status TEXT DEFAULT 'pending',
  trigger_source TEXT DEFAULT 'slack',
  started_at TIMESTAMPTZ DEFAULT now(),
  completed_at TIMESTAMPTZ,
  duration_seconds INTEGER,
  current_stage TEXT,
  stages_completed TEXT[],
  error_message TEXT,
  files_changed TEXT[],
  logs TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 12. SESSIONS
CREATE TABLE IF NOT EXISTS public.sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id UUID REFERENCES public.agents(id),
  agent_name TEXT NOT NULL,
  session_key TEXT NOT NULL,
  status TEXT DEFAULT 'active',
  channel TEXT DEFAULT 'telegram',
  model TEXT,
  context_tokens INTEGER DEFAULT 0,
  max_context_tokens INTEGER DEFAULT 1000000,
  total_messages INTEGER DEFAULT 0,
  started_at TIMESTAMPTZ DEFAULT now(),
  last_activity_at TIMESTAMPTZ DEFAULT now(),
  metadata JSONB DEFAULT '{}'::jsonb
);

-- 13. SESSION MESSAGES
CREATE TABLE IF NOT EXISTS public.session_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES public.sessions(id),
  role TEXT NOT NULL,
  content TEXT NOT NULL,
  tokens INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 14. MEMORY SNAPSHOTS
CREATE TABLE IF NOT EXISTS public.memory_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id UUID REFERENCES public.agents(id),
  agent_name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_type TEXT NOT NULL,
  content_preview TEXT,
  size_bytes INTEGER DEFAULT 0,
  entries_count INTEGER DEFAULT 0,
  last_modified TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 15. SPEND LOGS
CREATE TABLE IF NOT EXISTS public.spend_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  timestamp TIMESTAMPTZ DEFAULT now(),
  service TEXT NOT NULL,
  agent_id UUID REFERENCES public.agents(id),
  project_id UUID REFERENCES public.projects(id),
  amount_cents INTEGER NOT NULL DEFAULT 0,
  tokens_in INTEGER DEFAULT 0,
  tokens_out INTEGER DEFAULT 0,
  model TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 16. NOTIFICATIONS
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  severity TEXT DEFAULT 'info',
  read BOOLEAN DEFAULT false,
  read_at TIMESTAMPTZ,
  action_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 17. COMPACTION EVENTS
CREATE TABLE IF NOT EXISTS public.compaction_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id UUID REFERENCES public.agents(id),
  agent_name TEXT NOT NULL,
  session_key TEXT,
  context_before INTEGER,
  context_after INTEGER,
  messages_compacted INTEGER,
  summary TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 18. STANDUPS
CREATE TABLE IF NOT EXISTS public.standups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE NOT NULL,
  shipped JSONB,
  in_progress JSONB,
  blocked JSONB,
  planned JSONB,
  notes TEXT,
  agent_summary TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 19. CONFIG SNAPSHOTS
CREATE TABLE IF NOT EXISTS public.config_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  config_key TEXT NOT NULL,
  config_value JSONB,
  snapshot_at TIMESTAMPTZ DEFAULT now()
);

-- 20. SKILLS
CREATE TABLE IF NOT EXISTS public.skills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  location TEXT NOT NULL,
  description TEXT,
  file_count INTEGER DEFAULT 0,
  has_scripts BOOLEAN DEFAULT false,
  has_references BOOLEAN DEFAULT false,
  source TEXT DEFAULT 'workspace',
  last_modified TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 21. PROJECT STAGES
CREATE TABLE IF NOT EXISTS public.project_stages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES public.projects(id),
  stage TEXT NOT NULL,
  entered_at TIMESTAMPTZ DEFAULT now(),
  exited_at TIMESTAMPTZ,
  duration_hours NUMERIC,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 22. DEVICES
CREATE TABLE IF NOT EXISTS public.devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id TEXT NOT NULL,
  role TEXT,
  status TEXT DEFAULT 'paired',
  paired_at TIMESTAMPTZ,
  last_seen TIMESTAMPTZ DEFAULT now(),
  metadata JSONB DEFAULT '{}'::jsonb
);

-- Enable RLS on all tables (authenticated users can read all)
ALTER TABLE public.agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deployments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cron_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cron_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.heartbeats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gateway_health ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agent_activity ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alert_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.builds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.memory_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.spend_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.compaction_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.standups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.config_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_stages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;

-- RLS Policies: authenticated users can read everything
-- (Dashboard is behind login, so authenticated = dashboard user)
DO $$
DECLARE
  t TEXT;
BEGIN
  FOR t IN SELECT unnest(ARRAY[
    'agents','projects','deployments','cron_jobs','cron_runs',
    'heartbeats','gateway_health','agent_activity','alerts','alert_rules',
    'builds','sessions','session_messages','memory_snapshots','spend_logs',
    'notifications','compaction_events','standups','config_snapshots',
    'skills','project_stages','devices'
  ]) LOOP
    EXECUTE format('CREATE POLICY "allow_authenticated_read" ON public.%I FOR SELECT TO authenticated USING (true)', t);
    EXECUTE format('CREATE POLICY "allow_authenticated_write" ON public.%I FOR ALL TO authenticated USING (true) WITH CHECK (true)', t);
  END LOOP;
END $$;
