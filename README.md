# SubTrak Analytics - dbt Project

> **Payment tracking and contract management analytics for subscription-based solar power business**

[![dbt](https://img.shields.io/badge/dbt-1.0+-orange.svg)](https://www.getdbt.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14+-blue.svg)](https://www.postgresql.org/)

## 📋 Project Overview

**SubTrak** is an analytics engineering project that models payment tracking and contract performance for a subscription-based solar power business operating in Nigeria. The project transforms raw transactional data into analytics-ready models that power business intelligence, rep performance tracking, and risk management.

### Business Context

The company operates a hybrid business model:
- **Outright purchases**: Full payment upfront
- **12-month installment plans**: Upfront payment + 12 monthly installments (30-day cycles)
- **Regional sales network**: Performance-based rep incentive structure
- **Solar power products**: Critical infrastructure requiring consistent payment compliance

### Key Business Metrics
- **Contract Status Tracking**: Active, Owner, Lost, Retrieved
- **Payment Compliance**: On-time rate, grace period, late payments
- **Rep Performance**: Incentive qualification, portfolio health
- **Risk Management**: Early identification of potential defaults (31-60+ days overdue)

---

## 🏗️ Architecture

### Data Flow

```
Source (OLTP PostgreSQL)
    ↓
Staging Layer (cleaned, typed, renamed)
    ↓
Intermediate Layer (joins, business logic)
    ↓
Analytics Layer (marts for consumption)
    ↓
BI Layer (Power BI dashboards)
```

### Schema Structure

```
subtrak_db/
├── oltp/          # Source OLTP tables
├── staging/       # Cleaned staging models
└── analytics/     # Analytics-ready marts
```

---

## 📊 Data Models

### Staging Layer (`models/staging/`)

**Purpose**: Clean, type, and standardize raw OLTP data

- `stg_regions` - Geographic regions
- `stg_reps` - Sales representatives
- `stg_customers` - Customer master data
- `stg_deals` - Product/pricing plans
- `stg_contracts` - Contract master records
- `stg_payments` - Payment transactions

**Transformations**:
- Standardized column naming (snake_case)
- Data type casting
- Null handling
- Deduplication
- Basic data quality checks

### Analytics Layer (`models/analytics/`)

#### 1. **`dim_contracts_enriched`**
**Grain**: One row per contract

Master dimension with all contract attributes including customer, rep, region, and deal details.

**Key Fields**:
- Contract identifiers and dates
- Customer demographics
- Rep information and performance flags
- Product/deal details
- Time-based attributes (year, quarter, month)
- Calculated fields (contract age, repossession status)

**Use Cases**:
- Customer segmentation
- Rep/region performance analysis
- Product mix analysis
- Cohort definitions

---

#### 2. **`fct_billing_cycles`** ⭐ **Core Fact Table**
**Grain**: One row per contract per billing cycle

Tracks expected vs actual payments for each billing period with detailed payment behavior metrics.

**Key Fields**:
- Cycle identification (cycle_number: 0 = upfront, 1-12 = monthly)
- Expected vs actual amounts
- Payment timing (on_time, grace_period, late)
- Days from due date (negative = early, positive = late)
- Rep incentive qualification flag
- Cycle status (paid, pending, overdue)
- Days overdue calculation

**Business Logic**:
```sql
Payment Timing:
- On-time: payment_date <= due_date
- Grace period: payment_date <= due_date + 5 days (qualifies for rep incentive)
- Late: payment_date > due_date + 5 days
```

**Use Cases**:
- Monthly collections reporting
- Payment behavior analysis
- Rep incentive calculations
- Cash flow forecasting
- Delinquency tracking

---

#### 3. **`contract_status_current`** ⭐ **Executive Dashboard**
**Grain**: One row per contract

Comprehensive contract health scorecard with current status, risk level, and performance metrics.

**Key Metrics**:

| Category | Metrics |
|----------|---------|
| **Payment Progress** | total_billing_cycles, cycles_paid, cycles_unpaid, percent_paid |
| **Financial** | total_contract_value, total_amount_paid, total_amount_outstanding |
| **Performance** | on_time_payment_rate, incentive_qualifying_payments |
| **Timing** | last_payment_date, next_payment_due, days_since_last_payment |
| **Risk** | max_days_overdue, risk_category, overdue_cycle_count |

**Status Classifications**:

**System Status** (Application-driven):
- `enabled`: Service active (current_date < next_payment_due)
- `locked`: Service suspended (payment overdue)
- `retrieved`: Physical repossession
- `completed`: All payments made

**Business Status** (Analytics classification):
- `active`: Contract ongoing, < 61 days overdue
- `owner`: Completed all payments + past contract_end_date
- `lost`: 61+ days in default (business write-off)
- `retrieved`: Repossessed

**Risk Categories**:
- `good_standing`: 0-5 days overdue
- `low_risk`: 6-30 days overdue
- `medium_risk`: 31-60 days overdue
- `high_risk`: 61+ days overdue

**Use Cases**:
- Executive dashboards
- Portfolio health monitoring
- Risk management
- Collections prioritization
- Rep performance scorecards

---

## 🧪 Data Quality & Testing

### Test Coverage

- **Uniqueness tests**: All primary keys
- **Not null tests**: Required fields
- **Referential integrity**: Foreign key relationships
- **Accepted values**: Categorical fields (status, risk_category, etc.)
- **Business logic tests**: 
  - Total paid ≤ total contract value
  - Cycles paid + unpaid = total cycles
  - Payment timing categories are valid

### Running Tests

```bash
# Run all tests
dbt test

# Run tests for specific model
dbt test --select contract_status_current

# Run tests for analytics layer
dbt test --select analytics.*
```

---

## 🚀 Getting Started

### Prerequisites

- Python 3.8+
- PostgreSQL 14+
- dbt-core 1.0+
- dbt-postgres adapter

### Installation

```bash
# Clone repository
git clone <your-repo-url>
cd subtrak-analytics

# Install dependencies
pip install dbt-core dbt-postgres

# Configure connection
cp profiles.yml.example ~/.dbt/profiles.yml
# Edit ~/.dbt/profiles.yml with your database credentials
```

### Running the Project

```bash
# Install dependencies (if using packages)
dbt deps

# Run staging models
dbt run --select staging.*

# Run analytics models
dbt run --select analytics.*

# Run everything
dbt run

# Test everything
dbt test

# Generate documentation
dbt docs generate
dbt docs serve
```

---

## 📈 Example Queries

See [`example_queries.sql`](example_queries.sql) for ready-to-use analytical queries including:

1. **Executive Dashboard**
   - Current portfolio overview
   - Risk distribution
   - Monthly collections performance

2. **Rep Performance**
   - Rep performance scorecard
   - Incentive qualification summary

3. **Payment Behavior**
   - Payment timing distribution
   - First payment analysis

4. **Cohort Analysis**
   - Contract cohorts by signup month
   - Completion and loss rates

5. **Product Analysis**
   - Product performance by deal type
   - Revenue realization

6. **Risk Management**
   - Early warning indicators
   - High-risk contract identification

---

## 📊 Key Business Insights

### Example: Portfolio Health (as of current date)

```sql
SELECT 
    business_status,
    COUNT(*) as contracts,
    SUM(total_contract_value) as total_value,
    SUM(total_amount_paid) as collected,
    ROUND(AVG(percent_paid), 2) as avg_completion
FROM analytics.contract_status_current
GROUP BY business_status;
```

### Example: Rep Incentive Qualification

```sql
SELECT 
    rep_name,
    incentive_qualified_payments,
    total_payments,
    ROUND(incentive_qualification_rate, 2) || '%' as qualification_rate
FROM rep_incentive_summary
WHERE payment_month = CURRENT_DATE
ORDER BY incentive_qualification_rate DESC;
```

---

## 🎯 Use Cases

This project demonstrates:

1. **Financial Data Modeling** ✅
   - Complex payment schedules and contract tracking
   - Interest calculations logic
   - Balance and payment reconciliation

2. **Analytics Engineering Best Practices** ✅
   - Dimensional modeling (facts + dimensions)
   - Clear data lineage (staging → analytics)
   - Comprehensive testing and documentation
   - Reusable, modular SQL

3. **Business Acumen** ✅
   - Understanding of subscription/recurring payment models
   - Risk classification and early warning systems
   - Performance incentive structures
   - Customer lifecycle tracking

4. **Nigerian Market Context** ✅
   - Solar power sector (infrastructure, payment challenges)
   - Regional sales network model
   - Payment behavior patterns in emerging markets

5. **Technical Skills** ✅
   - Advanced SQL (window functions, CTEs, date math)
   - dbt (models, tests, documentation)
   - PostgreSQL
   - Data quality frameworks



---

## 📝 Data Dictionary

### Key Metrics Definitions

- **Cycle**: A billing period (upfront or monthly installment)
- **On-time Payment**: Payment made on or before due date
- **Grace Period**: Payment made 1-5 days after due date (still qualifies for rep incentive)
- **Late Payment**: Payment made 6+ days after due date
- **Days Overdue**: Current date - due date (for unpaid cycles past due date)
- **Active Contract**: Not completed, not lost (< 91 days overdue), completed payment but contract has not ended
- **Owner Status**: All payments complete + past contract end date
- **Lost Contract**: 90+ days in default (business write-off threshold)

---

## 🔄 Model Lineage

```
stg_regions ────┐
stg_reps ───────┼──→ dim_contracts_enriched ──┐
stg_customers ──┤                              │
stg_deals ──────┤                              │
stg_contracts ──┴──→ fct_billing_cycles ───────┼──→ BI Dashboards
                                                │
stg_payments ──────→ payment aggregations ─────┴──→ contract_status_current
```

---

## 🛠️ Future Enhancements

- [ ] Add customer churn prediction model
- [ ] Build rep territory optimization analysis
- [ ] Create automated alerting for high-risk contracts
- [ ] Implement incremental models for better performance
- [ ] Add seasonal payment pattern analysis
- [ ] Build customer lifetime value (CLV) prediction
- [ ] Create macros for common calculations
- [ ] Add exposure metrics (dbt exposures) for downstream BI

---

## 👤 Author

**Chidinma Okoro**
- Email: okoromannie@gmail.com
- LinkedIn: [\[Chidinma Okoro\]](https://www.linkedin.com/in/chidinma-okoro/)


---

## 📄 License

This project is for portfolio demonstration purposes.

---

## 🙏 Acknowledgments


**Project completed**: [ongoing]
**dbt version**: 1.0+
**Database**: PostgreSQL 14