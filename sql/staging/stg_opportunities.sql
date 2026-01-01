-- Purpose: Normalize opportunity lifecycle data for sales funnel and revenue analysis
-- Grain: Opportunity
-- Notes:
-- - Standardizes opportunity stage and lifecycle dates
-- - Normalizes malformed date values to DATE (YYYY-MM-DD)
-- - Enables analysis of demo progression, close outcomes, and sales efficiency
-- - Serves as the bridge between lead activity and closed revenue


create or replace table DEMO_DB.DE_CASE_NICKFOX_SCHEMA.STG_OPPORTUNITIES as
select
  opportunity_id,
  stage_name,
  lost_reason_c,
  closed_lost_notes_c,
  business_issue_c,
  how_did_you_hear_about_us_c,
  to_date(created_date) as created_date,  -- TIMESTAMP -> DATE
  demo_held,
  try_to_date(
    regexp_replace(left(trim(to_varchar(demo_set_date)), 10), '^00([0-9]{2})', '20\\1'),
    'YYYY-MM-DD'
  ) as demo_set_date,
  demo_time,
  try_to_date(
    regexp_replace(left(trim(to_varchar(close_date)), 10), '^00([0-9]{2})', '20\\1'),
    'YYYY-MM-DD'
  ) as close_date,
  to_date(last_sales_call_date_time) as last_sales_call_date,
  account_id
from DEMO_DB.GTM_CASE.OPPORTUNITIES;
