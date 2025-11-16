# 📊 Subtrak Data Project: Phase 1 - Foundation & Data Loading

This repository documents the end-to-end data project for a fictional company, **SubTrak**, mirroring a subscription-based business model.
The business model includes both outright purchases and recurring payment contracts, managed through a network of regional sales representatives.

**Phase 1** focuses on establishing the core **Operational Database (OLTP)**, creating the necessary tables, and loading the raw data.

---

## 🚀 Project Stack

| Component | Tool / Technology | Purpose |
| :--- | :--- | :--- |
| **Database** | PostgreSQL | Our single source for transactional data (`oltp` schema) and analytical output (`marts` schema). |
| **Design** | dbdiagram.io | Used to design the normalized relational database schema. |
| **Transformation** | dbt (Data Build Tool) | (Future Phase) Will handle the `T` in ELT, transforming raw data into analytical tables. |
| **Visualization** | Power BI | (Future Phase) Will connect to the transformed data for reporting. |

---

## 🏛️ Database Architecture

For this project, we are using a **single PostgreSQL instance** but logically separating the raw and analytical data using **schemas**.

### 1. The `oltp` Schema (Operational/Raw Data)

This schema holds the initial, normalized, transactional data directly loaded from CSV files. This data is messy and detailed—perfect for capturing real-time operations, but not yet optimized for reporting.

### 2. The `marts` Schema (Analytical/Transformed Data)

This schema is where all transformed data will reside (created by dbt in Phase 2). It will contain denormalized **Fact and Dimension tables** optimized for high-speed analytical queries.

---

## 📁 Repository Structure (Phase 1 Focus)

This section details the files relevant to the database setup and initial data load.

| Path | Purpose |
| :--- | :--- |
| `documentation/dbdiagram_design.png` | Image of the final **Relational Schema Design**. |
| `01_database_setup/01_schema_creation.sql` | SQL script to create the `oltp` and `marts` schemas. |
| `01_database_setup/02_table_creation.sql` | SQL script to create the **Source Tables** (e.g., `oltp.raw_orders`). |
| `01_database_setup/03_data_loading/` | Contains all raw `.csv` files and the script used to load them into the `oltp` schema. |

---

## 🛠️ Phase 1 Setup & Execution

### Prerequisites

Before starting, ensure you have the following installed:
* **PostgreSQL** (with a server running)
* **Python** (if using a Python script for loading)

### 1. Database and Schema Creation

Connect to your PostgreSQL server and execute the scripts in the following order:

1.  **Create Schemas:** Run `01_database_setup/01_schema_creation.sql`
2.  **Create Tables:** Run `01_database_setup/02_table_creation.sql`

```sql
-- Example from 01_schema_creation.sql
CREATE SCHEMA IF NOT EXISTS oltp;
CREATE SCHEMA IF NOT EXISTS marts;

### Data Loading

Load the raw data files from the `01_database_setup/03_data_loading/` folder into their corresponding tables within the oltp schema.

---

## 🛠️ Phase 2
