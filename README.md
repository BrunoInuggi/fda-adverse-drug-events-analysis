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

## Tables

| Table | What it contains |
|-------|-----------------|
| `CONCEPT` | Dictionary — maps numeric codes to human-readable drug and outcome names |
| `STANDARD_CASE_DRUG` | Each drug involved in a reported adverse event |
| `STANDARD_CASE_OUTCOME` | Each adverse outcome reported per case |
| `STANDARD_DRUG_OUTCOME_STATISTICS` | PRR and ROR safety statistics for every drug-outcome pair |

---

## Step 1 — Data Exploration & Quality Assessment

Before any analysis, I assessed the quality of each table.

### CONCEPT
- `concept_id`, `concept_name`, `domain_id` — no nulls ✅
- `standard_concept` — 7,319 nulls. Not missing data — in OMOP, a null here means the concept is non-standard (a synonym). Expected and valid.
- `invalid_reason` — 40,996 nulls. Also valid — null means the concept is currently active.

### STANDARD_CASE_DRUG
- `drug_seq`, `role_cod`, `standard_concept_id` — no nulls ✅
- `primaryid` — 18,092 nulls. After investigation, these are historical records from **LAERS** (the legacy FDA system, pre-2012), which use `isr` as the case identifier instead of `primaryid`. Records are valid and retained.

**Note on role_cod:** Each drug in a case has a role:
- **PS (Primary Suspect)** — the drug suspected of causing the adverse event
- **SS (Secondary Suspect)** — secondary suspect
- **C (Concomitant)** — drug the patient was taking, not suspected

For signal detection, I filter by **PS only** to focus on drugs actually suspected of causing harm.

---

## Step 2 — Analysis

### Most frequently reported adverse effects
*Coming soon*

### Top drugs by adverse event reports
*Coming soon*

### Safety signal detection using PRR & ROR
*Coming soon*

### Drug-indication-outcome relationships
*Coming soon*

---

## Key concepts

**PRR (Proportional Reporting Ratio):** How much more often a drug-outcome pair is reported compared to all other drugs. PRR > 2 = safety signal.

**ROR (Reporting Odds Ratio):** Similar to PRR, statistically more robust. Used together with PRR to confirm signals.

**OMOP CDM:** International standard for observational health data. Used across the pharmaceutical industry to make data from different sources comparable.

---

*This is an ongoing project — analysis sections will be updated as queries are completed.*

