-- ============================================================
-- Tests: MART_GTM_UNIT_ECONOMICS_MONTHLY
-- Purpose: Lightweight data quality checks to validate SSOT
-- ============================================================


-- ------------------------------------------------------------
-- Test 1: Enforce grain (1 row per month)
-- Expectation: No month_date should appear more than once
-- ------------------------------------------------------------
select
  month_date,
  count(*) as row_count
from DEMO_DB.DE_CASE_NICKFOX_SCHEMA.MART_GTM_UNIT_ECONOMICS_MONTHLY
group by 1
having count(*) > 1;


-- ------------------------------------------------------------
-- Test 2: Cost and funnel volume sanity checks
-- Expectation: Key metrics should never be negative
-- ------------------------------------------------------------
select *
from DEMO_DB.DE_CASE_NICKFOX_SCHEMA.MART_GTM_UNIT_ECONOMICS_MONTHLY
where
  total_gtm_cost_usd < 0
  or advertising_usd < 0
  or inbound_sales_team_usd < 0
  or outbound_sales_team_usd < 0
  or leads_created < 0
  or demos_held < 0
  or closed_won < 0;


-- ------------------------------------------------------------
-- Test 3: Business logic integrity
-- Expectation:
--   - demos_held cannot exceed demos_set
--   - closed_won cannot exceed demos_held
-- NOTE:
-- This test currently surfaces known CRM inconsistencies where demos are held
-- without a corresponding demo_set_date.
-- These rows are intentionally not filtered out, as they highlight
-- funnel instrumentation gaps that impact CAC and cost-per-demo metrics.

-- ------------------------------------------------------------
select *
from DEMO_DB.DE_CASE_NICKFOX_SCHEMA.MART_GTM_UNIT_ECONOMICS_MONTHLY
where
  demos_held > demos_set
  or closed_won > demos_held;


-- ------------------------------------------------------------
-- Test 4: Payback period reasonableness
-- Expectation: Payback should be within a realistic range
-- ------------------------------------------------------------
select *
from DEMO_DB.DE_CASE_NICKFOX_SCHEMA.MART_GTM_UNIT_ECONOMICS_MONTHLY
where
  payback_months < 0
  or payback_months > 24;
