# FDA Adverse Drug Events Analysis

**Tools:** SQL · Snowflake · OMOP CDM  
**Data:** FDA FAERS via AEOLUS pipeline · Kaggle  
**Author:** Bruno Inuggi · [LinkedIn](https://www.linkedin.com/in/brunoinuggi)

---

## Why this project?

I chose this dataset to better understand the pharmaceutical industry from a data perspective. As a nutritionist with a background in clinical research and epidemiology, health data is not new to me — but analyzing it at this scale, with industry-standard tools like Snowflake and OMOP, is a new challenge I wanted to take on.

The technical terminology was steep at first, but coming from a health science background helped me understand the context quickly. Terms like adverse events, drug interactions, and reporting ratios are familiar concepts — just in a new technical format.

---

## What is this dataset?

The **FDA Adverse Event Reporting System (FAERS)** collects reports of adverse drug events submitted by patients, doctors, and pharmaceutical companies. This dataset was processed through the **AEOLUS** pipeline, which standardizes the raw FDA data using the **OMOP Common Data Model** — the international standard used by pharmaceutical companies like Roche, Novartis, and Pfizer.

---

## Data Sources

This dataset combines two FDA reporting systems:

- **FAERS (FDA Adverse Event Reporting System):** The current system, active since 2012. Uses `primaryid` as the case identifier.
- **LAERS (Legacy Adverse Event Reporting System):** The predecessor system, active before 2012. Uses `isr` as the case identifier.

AEOLUS merged both systems into a single standardized database. To handle this, `COALESCE(primaryid, isr)` was used throughout the analysis to unify case identifiers across both systems.

---

## Tables

| Table | What it contains |
|-------|-----------------|
| `CONCEPT` | Dictionary — maps numeric codes to human-readable drug and outcome names |
| `STANDARD_CASE_DRUG` | Each drug involved in a reported adverse event |
| `STANDARD_CASE_OUTCOME` | Each adverse outcome reported per case |
| `STANDARD_DRUG_OUTCOME_STATISTICS` | PRR and ROR safety statistics for every drug-outcome pair |

---

## Step 1 — Data Exploration & Quality Assessment

Before any analysis, a thorough data quality assessment was performed on all tables.

### CONCEPT
- `concept_id`, `concept_name`, `domain_id` — no nulls
- `standard_concept` — 7,319 nulls. Not missing data — in OMOP, a null here means the concept is non-standard (a synonym). Expected and valid.
- `invalid_reason` — 40,996 nulls. Also valid — null means the concept is currently active.

### STANDARD_CASE_DRUG
- `drug_seq`, `role_cod`, `standard_concept_id` — no nulls
- `primaryid` — 18,092 nulls. After investigation, these are historical records from **LAERS** (the legacy FDA system, pre-2012), which use `isr` as the case identifier instead of `primaryid`. Records are valid and retained.

**Drug role distribution:**
- **C (Concomitant): 23,881** — drugs the patient was taking, not suspected
- **PS (Primary Suspect): 15,002** — main suspect drug
- **SS (Secondary Suspect): 8,945** — secondary suspect
- **I (Interacting): 172** — drugs involved in an interaction

For signal detection, analysis was filtered to **PS only** to focus on drugs actually suspected of causing harm.

---

## Step 2 — Descriptive Analysis

| Metric | Result |
|--------|--------|
| Unique drugs | 1,594 |
| Unique adverse effects | 8,975 |
| Unique cases | 47,474 |
| Avg drugs per case | 1.01 (sampling limitation) |

**Most reported drugs:** Etanercept (843), Aspirin (805), Adalimumab (770), Interferon beta-1a (535), Levothyroxine (515)

> Most reported drugs are associated with chronic conditions (autoimmune, cardiovascular, neurological, thyroid). Several of these conditions have well-documented nutritional interventions that may complement pharmacological treatment and improve patient outcomes.

**Most reported adverse effects:** Death (5,877), Nausea (5,791), Headache disorder (5,486), Malaise and fatigue (5,259), Diarrhea (3,748)

> Several of the most reported adverse effects — nausea, vomiting, diarrhea, fatigue and joint pain — have documented nutritional interventions that may complement pharmacological treatment. This cross-disciplinary perspective is a key motivation for this analysis.

---

## Step 3 — Safety Signal Detection

### Methodology
A safety signal is confirmed when all three conditions are met simultaneously:
- `case_count > 100` — sufficient cases for statistical relevance
- `PRR > 2` — the effect is reported at least twice as often as expected
- `PRR lower 95% CI > 1` — the signal is statistically significant

### 2.1 Strongest Safety Signals (by PRR)

| Drug | Cases | PRR | ROR |
|------|-------|-----|-----|
| Factor VIII | 369 | 6,721.50 | 7,014.49 |
| Etonogestrel | 230 | 1,927.36 | 1,938.76 |
| Ketotifen | 104 | 1,819.95 | 1,859.20 |
| Tretinoin | 125 | 1,800.97 | 1,824.63 |
| Levonorgestrel | 290 | 1,236.38 | 1,238.10 |

> **Factor VIII** (hemophilia treatment) shows the strongest signal. Nutritional note: iron-rich foods and dietary support play a complementary role in managing bleeding disorders.
> **Etonogestrel, Levonorgestrel, Ethinyl Estradiol** (hormonal contraceptives) appear multiple times — well-documented to interact with B vitamins, magnesium and zinc metabolism.
> **Tretinoin** (Vitamin A derivative) — dietary Vitamin A intake requires careful monitoring due to toxicity risk when combined with this drug.

### 2.2 Drugs with Most Safety Signals

| Drug | Total Signals |
|------|--------------|
| Adalimumab | 41 |
| Fentanyl | 32 |
| Etanercept | 31 |
| Methotrexate | 29 |
| Nicotine | 26 |
| Cyclophosphamide | 22 |
| Buprenorphine | 20 |
| Rofecoxib (Vioxx) | 18 |

> Notably, **Rofecoxib (Vioxx)** appears in the list — a drug withdrawn from the market in 2004 due to cardiovascular safety issues. Its presence validates the signal detection methodology.

### 2.3 Most Frequent Adverse Effect Signals
Analysis performed on outcome_concept_id level. Full name translation requires complete OMOP vocabulary access. Top outcome (ID: 35809327) appears in 78 drug-signal pairs with avg PRR of 5.31.

> Signal frequency and intensity are independent metrics — effects with fewer signals can still carry higher PRR severity scores.

### 2.4 Most Reported Confirmed Signals

| Drug | Cases | PRR |
|------|-------|-----|
| Etanercept | 25,850 | 31.94 |
| Tiotropium | 15,801 | 298.99 |
| Adalimumab | 14,265 | 2.36 |
| Esomeprazole | 9,775 | 12.27 |
| Fentanyl | 7,742 | 22.99 |
| Pregabalin | 7,208 | 2.33 |

> **Tiotropium** shows the highest PRR (298.99) — a very strong disproportionality signal for its associated outcome.
> **Esomeprazole** (PPI): long-term use is associated with B12, magnesium, calcium and iron malabsorption — nutritional monitoring is essential.
> **Fentanyl** (opioid): commonly causes constipation — adequate fiber, hydration and magnesium intake are important supportive measures.

---

## Key Concepts

**PRR (Proportional Reporting Ratio):** How much more often a drug-outcome pair is reported compared to all other drugs. PRR > 2 = safety signal.

**ROR (Reporting Odds Ratio):** Similar to PRR, statistically more robust. Used together with PRR to confirm signals.

**OMOP CDM:** International standard for observational health data. Used across the pharmaceutical industry to make data from different sources comparable.

---

## Limitations

- Analysis performed on a sample of the full FAERS/LAERS database
- Outcome name translation limited by available OMOP vocabulary sample
- Average drugs per case (1.01) reflects sampling constraints, not real-world patterns

---

*This project is part of a data portfolio focused on health and pharmaceutical data analysis.*

