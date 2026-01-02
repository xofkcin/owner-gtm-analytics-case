# Owner.com – GTM Analytics Engineering Case

## Overview

This repository contains a GTM-focused analytics data product built in Snowflake SQL.
The objective is to create a **scalable single source of truth (SSOT)** that connects
marketing spend, sales costs, funnel execution, and revenue proxies to support
data-driven decision making across Sales, Marketing, RevOps, and Leadership.

The primary output is a **monthly GTM unit economics mart** designed to answer:
- How efficient is our go-to-market motion?
- Where is CAC increasing, and why?
- What is the fastest path to improving payback without increasing spend?

---

## Data Model Overview

The data model follows a layered analytics engineering pattern.

### Staging Layer (`sql/staging/`)

Staging models normalize raw GTM inputs and standardize formats, types, and dates.

- **stg_expenses_advertising.sql**  
  Normalizes marketing spend to monthly USD values.

- **stg_expenses_salary_and_commissions.sql**  
  Standardizes inbound and outbound sales team costs.

- **stg_leads.sql**  
  Cleans lead activity data, normalizes dates, engagement counts, and revenue proxy fields.

- **stg_opportunities.sql**  
  Normalizes opportunity lifecycle events including demos, stage progression, and outcomes.

Each staging model is designed to be reusable and resilient to upstream data quality issues.

---

### Mart Layer (`sql/marts/`)

#### mart_gtm_unit_economics_monthly.sql

This mart serves as the **single source of truth for GTM unit economics**, aggregated at a
**monthly grain**.

It combines:
- Marketing spend
- Sales team costs
- Funnel volume (leads → opportunities → demos → closed deals)
- Revenue proxies

Key metrics supported:
- Blended CAC
- Cost per demo held
- Demo-to-close efficiency
- Estimated payback period

The table is explicitly designed to surface **sales efficiency bottlenecks before scaling spend**.

---

#### mart_gtm_payback_lens_monthly.sql

This model is a lightweight **decision guardrail layer** derived from the GTM unit economics SSOT.
Its purpose is not to recommend a CAC target, but to define **clear payback ceilings** that protect
unit economics as GTM spend scales.

It answers a practical leadership question:
> “At current efficiency, are we inside our payback thresholds — and if not, how far outside the guardrail are we?”

For each month, the lens evaluates performance against two common payback guardrails (3-month and 6-month) and outputs:
- **CAC payback ceiling** — the maximum CAC allowed to remain within the payback window (guardrail, not a goal)
- **CAC headroom** — how far inside or outside the guardrail current performance sits  
  (positive = capacity to scale spend; negative = efficiency constraint)
- A **within_payback_guardrail** flag for quick scanning

This framing allows GTM leadership to distinguish between periods where spend can safely scale
and periods where execution improvements are required before additional investment.

---

## Data Quality & Validation

Lightweight SQL-based validation tests are included in `sql/tests/` to ensure data integrity
and enforce business logic.

### Test Coverage

- **Grain enforcement**  
  Ensures exactly one row per month.

- **Cost and funnel sanity checks**  
  Prevents negative costs or funnel counts.

- **Funnel logic integrity**  
  Flags cases where:
  - Demos held exceed demos set
  - Closed-won deals exceed demos held

- **Payback reasonableness**  
  Identifies anomalous payback periods.

### Observed Funnel Inconsistency (Intentional)

One validation test surfaces months where **demos held exceed demos set**.
This reflects real-world CRM instrumentation gaps (e.g. ad-hoc demos, missing stage updates,
or cross-system mismatches), not modeling errors.

These rows are intentionally preserved to:
- Avoid masking operational issues
- Prevent inflated confidence in funnel conversion metrics
- Highlight execution constraints that directly impact CAC and payback

---

## Key GTM Opportunities Identified

### 1. Sales Execution Is the Primary Growth Lever

Lead volume remains relatively stable month over month, indicating that **demand is not the
primary constraint**.

Rising CAC and payback are driven by inefficiencies **after the demo stage**, including
inconsistent demo execution and conversion. Improving demo-to-close performance and tightening
sales execution will unlock more growth than increasing marketing spend.

---

### 2. Spend Is Scaling Faster Than Revenue Efficiency

Marketing and sales costs increase steadily while estimated revenue per customer remains flat.
This indicates diminishing returns on spend and highlights the need for:
- Better ICP targeting
- Improved rep productivity
- Funnel quality optimization

Addressing these issues before scaling GTM investment will materially improve unit economics.

---

## Future Extensions

Potential next steps include:
- Splitting CAC by inbound vs outbound motion
- Cohort-based payback analysis by signup month
- Attribution of efficiency metrics by rep, channel, or segment
- Exposing payback guardrails via Sigma input controls or a Snowflake Notebook for interactive scenario modeling

---

## Summary

This data product provides a clear, scalable foundation for understanding GTM efficiency at
Owner.com. In addition to describing what is happening, the payback guardrail lens translates
unit economics into clear **go / no-go signals** that help leadership decide *when* to scale spend
versus *when* to focus on execution improvements.
