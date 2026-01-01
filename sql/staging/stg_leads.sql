-- Purpose: Normalize sales team compensation costs for GTM analysis
-- Grain: Month
-- Notes:
-- - Separates inbound and outbound sales team costs
-- - Normalizes currency formatting to numeric USD values
-- - Enables allocation of GTM costs across funnel stages
-- - Standardizes month to DATE (YYYY-MM-01)


create or replace table DEMO_DB.DE_CASE_NICKFOX_SCHEMA.STG_LEADS as
select
  lead_id,
  -- normalize dates to DATE (YYYY-MM-DD output)
  try_to_date(
    regexp_replace(left(trim(to_varchar(form_submission_date)), 10), '^00([0-9]{2})', '20\\1'),
    'YYYY-MM-DD'
  ) as form_submission_date,
  try_to_date(regexp_replace(left(trim(to_varchar(first_sales_call_date)), 10), '^00([0-9]{2})', '20\\1'), 'YYYY-MM-DD')
    as first_sales_call_date,
  try_to_date(regexp_replace(left(trim(to_varchar(first_text_sent_date)), 10), '^00([0-9]{2})', '20\\1'), 'YYYY-MM-DD')
    as first_text_sent_date,
  try_to_date(regexp_replace(left(trim(to_varchar(first_meeting_booked_date)), 10), '^00([0-9]{2})', '20\\1'), 'YYYY-MM-DD')
    as first_meeting_booked_date,
  try_to_date(regexp_replace(left(trim(to_varchar(last_sales_call_date)), 10), '^00([0-9]{2})', '20\\1'), 'YYYY-MM-DD')
    as last_sales_call_date,
  try_to_date(regexp_replace(left(trim(to_varchar(last_sales_activity_date)), 10), '^00([0-9]{2})', '20\\1'), 'YYYY-MM-DD')
    as last_sales_activity_date,
  try_to_date(regexp_replace(left(trim(to_varchar(last_sales_email_date)), 10), '^00([0-9]{2})', '20\\1'), 'YYYY-MM-DD')
    as last_sales_email_date,
  -- normalize counts
  try_to_number(sales_call_count)  as sales_call_count,
  try_to_number(sales_text_count)  as sales_text_count,
  try_to_number(sales_email_count) as sales_email_count,
  -- revenue proxy: keep raw + normalized numeric
  predicted_sales_with_owner as predicted_sales_with_owner_raw,
  try_to_decimal(
    replace(regexp_replace(to_varchar(predicted_sales_with_owner), '[^0-9,.-]', ''), ',', '.'),
    18, 2
  ) as predicted_sales_with_owner,
  marketplaces_used,
  online_ordering_used,
  cuisine_types,
  try_to_number(nullif(trim(to_varchar(location_count)), '')) as location_count,
  -- normalize to boolean (safe if already boolean)
  try_to_boolean(connected_with_decision_maker) as connected_with_decision_maker,
  status,
  converted_opportunity_id,
  -- helpful derived flags for downstream GTM funnel analysis
  iff(first_meeting_booked_date is not null, true, false) as has_meeting_booked,
  iff(
    coalesce(try_to_number(sales_call_count), 0)
    + coalesce(try_to_number(sales_text_count), 0)
    + coalesce(try_to_number(sales_email_count), 0) > 0,
    true, false
  ) as has_any_sales_activity
from DEMO_DB.GTM_CASE.LEADS;
