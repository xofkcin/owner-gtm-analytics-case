-- Purpose: Single source of truth for GTM unit economics and sales efficiency
-- Grain: Month
-- Notes:
-- - Combines marketing spend, sales costs, funnel volume, and revenue proxies
-- - Supports CAC, cost-per-demo, and payback period analysis
-- - Designed to identify efficiency bottlenecks before scaling spend


create or replace table DEMO_DB.DE_CASE_NICKFOX_SCHEMA.MART_GTM_UNIT_ECONOMICS_MONTHLY as
with costs as (
    select
        month_date,
        advertising_usd,
        inbound_sales_team_usd,
        outbound_sales_team_usd,
        coalesce(advertising_usd, 0)
          + coalesce(inbound_sales_team_usd, 0)
          + coalesce(outbound_sales_team_usd, 0) as total_gtm_cost_usd
    from DEMO_DB.DE_CASE_NICKFOX_SCHEMA.STG_EXPENSES_ADVERTISING a
    full outer join DEMO_DB.DE_CASE_NICKFOX_SCHEMA.STG_EXPENSES_SALARY_AND_COMMISSIONS s
      using (month_date)
),

leads as (
    select
        date_trunc('month', form_submission_date) as month_date,
        count(*) as leads_created,
        avg(predicted_sales_with_owner) as avg_predicted_sales_with_owner
    from DEMO_DB.DE_CASE_NICKFOX_SCHEMA.STG_LEADS
    where form_submission_date is not null
    group by 1
),

opps as (
    select
        date_trunc('month', created_date) as month_date,
        count(*) as opps_created,
        count_if(demo_set_date is not null) as demos_set,
        count_if(demo_held = true) as demos_held,
        count_if(stage_name = 'Closed Won') as closed_won,
        count_if(stage_name like 'Closed Lost%') as closed_lost
    from DEMO_DB.DE_CASE_NICKFOX_SCHEMA.STG_OPPORTUNITIES
    where created_date is not null
    group by 1
),

final as (
    select
        c.month_date,

        -- costs
        c.total_gtm_cost_usd,
        c.advertising_usd,
        c.inbound_sales_team_usd,
        c.outbound_sales_team_usd,

        -- volume
        l.leads_created,
        o.opps_created,
        o.demos_set,
        o.demos_held,
        o.closed_won,
        o.closed_lost,

        -- efficiency
        c.total_gtm_cost_usd / nullif(o.demos_held, 0) as cost_per_demo_held,
        c.total_gtm_cost_usd / nullif(o.closed_won, 0) as blended_cac,

        -- revenue proxy (assumes predicted_sales_with_owner ~ monthly expected GMV/online sales)
        500 + (0.05 * l.avg_predicted_sales_with_owner) as est_monthly_rev_per_customer,

        -- payback proxy (months)
        (c.total_gtm_cost_usd / nullif(o.closed_won, 0))
          / nullif(500 + (0.05 * l.avg_predicted_sales_with_owner), 0)
          as payback_months

    from costs c
    left join leads l on c.month_date = l.month_date
    left join opps  o on c.month_date = o.month_date
)

select

    --md5(to_varchar(month_date)) as pk_month,
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

    ROUND(cost_per_demo_held,2) as cost_per_demo_held,
    ROUND(blended_cac,2) as blended_cac,
    ROUND(est_monthly_rev_per_customer,2) as est_monthly_rev_per_customer,
    ROUND(payback_months,2) as payback_months,

    current_timestamp() as load_ts
from final
order by month_date;
