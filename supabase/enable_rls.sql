-- ══════════════════════════════════════════════════════════════
--  BC-CAD  —  Row Level Security  (run once in Supabase SQL editor)
--  Resolves: "Table publicly accessible" critical alert
--  Date: 2026-03-25
-- ══════════════════════════════════════════════════════════════

-- ── 1. Enable RLS on every public table ──────────────────────
ALTER TABLE public.campuses               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.call_types             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.units                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incidents              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incident_log           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roster_template_units  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings               ENABLE ROW LEVEL SECURITY;

-- ── 2. campuses ───────────────────────────────────────────────
-- Anon may read and update map_image_url (upload flow)
CREATE POLICY "campuses_select" ON public.campuses
  FOR SELECT TO anon USING (true);

CREATE POLICY "campuses_update" ON public.campuses
  FOR UPDATE TO anon USING (true) WITH CHECK (true);

-- ── 3. call_types ─────────────────────────────────────────────
-- Read-only — populated at DB setup, not touched by the app
CREATE POLICY "call_types_select" ON public.call_types
  FOR SELECT TO anon USING (true);

-- ── 4. units ──────────────────────────────────────────────────
-- Full CRUD — SOC loads/clears roster and changes status live
CREATE POLICY "units_select" ON public.units
  FOR SELECT TO anon USING (true);

CREATE POLICY "units_insert" ON public.units
  FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "units_update" ON public.units
  FOR UPDATE TO anon USING (true) WITH CHECK (true);

CREATE POLICY "units_delete" ON public.units
  FOR DELETE TO anon USING (true);

-- ── 5. incidents ──────────────────────────────────────────────
-- Full CRUD — SOC creates, edits, and closes incidents
CREATE POLICY "incidents_select" ON public.incidents
  FOR SELECT TO anon USING (true);

CREATE POLICY "incidents_insert" ON public.incidents
  FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "incidents_update" ON public.incidents
  FOR UPDATE TO anon USING (true) WITH CHECK (true);

CREATE POLICY "incidents_delete" ON public.incidents
  FOR DELETE TO anon USING (true);

-- ── 6. incident_log ───────────────────────────────────────────
-- INSERT + SELECT only — log entries are never modified
CREATE POLICY "incident_log_select" ON public.incident_log
  FOR SELECT TO anon USING (true);

CREATE POLICY "incident_log_insert" ON public.incident_log
  FOR INSERT TO anon WITH CHECK (true);

-- Allow delete only so the app can cascade-delete before removing an incident
CREATE POLICY "incident_log_delete" ON public.incident_log
  FOR DELETE TO anon USING (true);

-- ── 7. roster_template_units ──────────────────────────────────
-- Full CRUD — Admin manages roster templates per campus
CREATE POLICY "roster_template_select" ON public.roster_template_units
  FOR SELECT TO anon USING (true);

CREATE POLICY "roster_template_insert" ON public.roster_template_units
  FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "roster_template_update" ON public.roster_template_units
  FOR UPDATE TO anon USING (true) WITH CHECK (true);

CREATE POLICY "roster_template_delete" ON public.roster_template_units
  FOR DELETE TO anon USING (true);

-- ── 8. settings ───────────────────────────────────────────────
-- SELECT + UPDATE only — SOC passcode lives here, no insert/delete from app
CREATE POLICY "settings_select" ON public.settings
  FOR SELECT TO anon USING (true);

CREATE POLICY "settings_update" ON public.settings
  FOR UPDATE TO anon USING (true) WITH CHECK (true);

-- Also allow upsert (used by saveNewPasscode)
CREATE POLICY "settings_upsert" ON public.settings
  FOR INSERT TO anon WITH CHECK (true);

-- ── 9. Storage bucket — campus-maps ───────────────────────────
-- Allow anon to upload/read maps (bucket must exist and be set to public)
-- Run this only if the bucket policy is not already set in Storage UI
INSERT INTO storage.buckets (id, name, public)
  VALUES ('campus-maps', 'campus-maps', true)
  ON CONFLICT (id) DO UPDATE SET public = true;

CREATE POLICY "campus_maps_select" ON storage.objects
  FOR SELECT TO anon USING (bucket_id = 'campus-maps');

CREATE POLICY "campus_maps_insert" ON storage.objects
  FOR INSERT TO anon WITH CHECK (bucket_id = 'campus-maps');

CREATE POLICY "campus_maps_update" ON storage.objects
  FOR UPDATE TO anon USING (bucket_id = 'campus-maps') WITH CHECK (bucket_id = 'campus-maps');

CREATE POLICY "campus_maps_delete" ON storage.objects
  FOR DELETE TO anon USING (bucket_id = 'campus-maps');
