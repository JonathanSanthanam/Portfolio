# 💰 The Profit Machine — Financial KPI Dashboard

A multi-page financial dashboard built in Power BI, analyzing $117.9M in revenue across 5 countries, 5 customer segments, and 6 products. The dashboard covers the full P&L pipeline, budget variance analysis, and pricing strategy — designed to give a CFO actionable answers in under 30 seconds.

---

## 📌 Business Questions Answered

- Which segments and countries are actually profitable — and which are destroying margin?
- Where does revenue go? (Gross Sales → Discounts → COGS → Profit)
- Are we hitting budget? Which departments are over or under?
- Is the forecast more accurate than the original budget?
- What's the optimal pricing strategy per product?

---

## 🗂️ Project Structure
```
02-Financial_KPI_Dashboard/
├── data/
│   ├── raw/                  # Original source files
│   └── cleaned/              # Exported from MySQL (financial_export.csv, budget_export.csv)
├── sql/
│   └── P2_queries.sql        # Full MySQL pipeline: cleaning, CTEs, Window Functions, Views
├── screenshots/              # Dashboard pages (Power BI)
├── powerbi/
│   └── P2_Financial_KPI_Dashboard.pbix
└── Project 2 done!.pdf       # Exported dashboard (all pages)
```

---

## 🛠️ Tools & Pipeline

**Excel → MySQL → Power BI**

| Phase | Tool | What I did |
|-------|------|------------|
| Exploration | Excel + Power Query | Data quality checks, Pivot Tables, P&L verification |
| Cleaning & Analysis | MySQL 8.0 | CTEs, Window Functions, RANK(), CASE WHEN, Views, What-If simulation |
| Visualization | Power BI | Star schema, DAX measures, 7-page interactive dashboard |

---

## 📊 Dashboard Pages

| Page | What it shows |
|------|---------------|
| 🏠 Home | Navigation hub |
| 📊 Command Center | P&L Waterfall · Monthly trend 2013 vs 2014 · 5 KPI cards |
| 🏆 Where We Win | Revenue vs Margin scatter · Profit by country · Segment × Country heatmap |
| 💸 The Cost Story | COGS vs Discounts by product · Margin trend · Discount impact by segment |
| 📋 Budget Reality Check | Budget vs Forecast vs Actual · Variance by department · Heatmap Q1–Q4 |
| 💰 Pricing Power | Price premium vs margin · Optimal discount band per product |
| 👔 CFO Briefing | Executive summary · Key insights · 3 actionable recommendations |

---

## 🔑 Key Findings

- **Government** segment drives **67% of total profit** despite not being the highest volume
- **Channel Partners** achieves **73% profit margin** — the highest of any segment
- **Enterprise** is the only segment with **negative margin (-3.3%)** — a clear red flag
- **France** leads in absolute profit at **$3.8M**, followed by Germany ($3.7M)
- **COGS is the main margin killer** at 85.7% of net revenue — discounts only account for 7.2%
- Overall budget variance: **+$5.5M (+1.5%)** — slightly over budget but in positive territory
- **Amarilla** is the top product by profit margin at **16%**

---

## 🧠 SQL Highlights
```sql
-- Pricing Strategy: which discount band maximizes margin per product?
WITH product_pricing AS (
    SELECT product, discount_band,
           ROUND(AVG(profit_margin_pct), 2) AS avg_margin_pct,
           RANK() OVER (PARTITION BY product ORDER BY AVG(profit_margin_pct) DESC) AS rk
    FROM financial_clean
    GROUP BY product, discount_band
)
SELECT product, discount_band, avg_margin_pct
FROM product_pricing
WHERE rk = 1;
```

---

## 📁 Data Sources

- **Microsoft Financial Sample** — Official Power BI training dataset (700 rows × 16 columns)
- **ExcelX Budget Forecast** — Quarterly Budget / Forecast / Actual by department

---

## 📸 Dashboard Preview

![Command Center](./screenshots/02_Command_Center.png)
![Where We Win](./screenshots/03_Where_We_Win.png)
![CFO Briefing](./screenshots/07_CFO_Briefing.png)
