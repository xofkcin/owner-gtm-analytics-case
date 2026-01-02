create or replace table DEMO_DB.DE_CASE_NICKFOX_SCHEMA.MART_GTM_PAYBACK_LENS_MONTHLY as
with base as (
  select
    month_date,
    total_gtm_cost_usd,
    advertising_usd,
    inbound_sales_team_usd,
    outbound_sales_team_usd,
    leads_created,
    opps_created,
    demos_set,
    demos_held,
    closed_won,
    closed_lost,
    cost_per_demo_held,
    blended_cac,
    est_monthly_rev_per_customer,
    payback_months
  from DEMO_DB.DE_CASE_NICKFOX_SCHEMA.MART_GTM_UNIT_ECONOMICS_MONTHLY
),

targets as (
  select 3 as target_payback_months
  union all
  select 6 as target_payback_months
)

select
  md5(to_varchar(b.month_date) || '|' || to_varchar(t.target_payback_months)) as pk_month_target,
  b.month_date,
  t.target_payback_months,

  -- Guardrail ceiling: maximum CAC allowed to remain within the payback threshold
  (b.est_monthly_rev_per_customer * t.target_payback_months) as cac_payback_ceiling,

  -- Actuals
  b.blended_cac,
  b.payback_months,

  -- Headroom (positive = within guardrail, negative = outside guardrail)
  ((b.est_monthly_rev_per_customer * t.target_payback_months) - b.blended_cac) as cac_headroom,

  -- Simple decision flag
  iff(
    b.blended_cac <= (b.est_monthly_rev_per_customer * t.target_payback_months),
    true,
    false
  ) as within_payback_guardrail,

  -- Helpful carry-through fields (keeps this lens usable without joining back)
  b.total_gtm_cost_usd,
  b.demos_held,
  b.closed_won,

  current_timestamp() as load_ts
from base b
cross join targets t;
