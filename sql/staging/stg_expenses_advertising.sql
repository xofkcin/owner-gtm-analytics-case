-- Purpose: Normalize advertising spend for GTM unit economics
-- Grain: Month
-- Notes:
-- - Parses currency strings with commas and currency symbols
-- - Standardizes month to DATE (YYYY-MM-01)
create or replace table DEMO_DB.DE_CASE_NICKFOX_SCHEMA.STG_EXPENSES_ADVERTISING as
select
  to_date(month, 'MON-YY') as month_date,
  advertising as advertising_raw,
  try_to_decimal(
    replace(regexp_replace(to_varchar(advertising), '[^0-9,.-]', ''), ',', '.'),
    18, 2
  ) as advertising_usd --refactoring euro-type of formatting for dollars
from DEMO_DB.GTM_CASE.EXPENSES_ADVERTISING;
