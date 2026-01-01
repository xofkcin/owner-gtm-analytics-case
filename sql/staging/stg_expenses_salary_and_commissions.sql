-- Purpose: Normalize sales team compensation costs for GTM analysis
-- Grain: Month
-- Notes:
-- - Separates inbound and outbound sales team costs
-- - Normalizes currency formatting to numeric USD values
-- - Enables allocation of GTM costs across funnel stages
-- - Standardizes month to DATE (YYYY-MM-01)


create or replace table DEMO_DB.DE_CASE_NICKFOX_SCHEMA.STG_EXPENSES_SALARY_AND_COMMISSIONS as
select
  to_date(month, 'MON-YY') as month_date,

  outbound_sales_team as outbound_sales_team_raw,
  inbound_sales_team  as inbound_sales_team_raw,

  try_to_decimal(
    replace(regexp_replace(to_varchar(outbound_sales_team), '[^0-9,.-]', ''), ',', '.'),
    18, 2
  ) as outbound_sales_team_usd,

  try_to_decimal(
    replace(regexp_replace(to_varchar(inbound_sales_team), '[^0-9,.-]', ''), ',', '.'),
    18, 2
  ) as inbound_sales_team_usd
from DEMO_DB.GTM_CASE.EXPENSES_SALARY_AND_COMMISSIONS;
