-- ============================================================
-- FDA ADVERSE DRUG EVENTS ANALYSIS
-- Dataset: AEOLUS / FDA FAERS
-- Warehouse: Snowflake
-- Author: Bruno Inuggi
-- ============================================================


-- ============================================================
-- SECTION 1: EXPLORATORY DATA ANALYSIS (EDA)
-- ============================================================
-- Goal: Understand the structure and content of the dataset
-- before drawing any conclusions.
-- ============================================================

SELECT COUNT(*) AS total FROM PHARMACOVIGILANCE.PUBLIC.CONCEPT;
SELECT COUNT(*) AS total FROM PHARMACOVIGILANCE.PUBLIC.STANDARD_CASE_DRUG;
SELECT COUNT(*) AS total FROM PHARMACOVIGILANCE.PUBLIC.STANDARD_CASE_OUTCOME;
SELECT COUNT(*) AS total FROM PHARMACOVIGILANCE.PUBLIC.STANDARD_DRUG_OUTCOME_STATISTICS;

select * from pharmacovigilance.public.concept
limit 10;

SELECT 
    COUNT(*) AS total_filas,
    COUNT(concept_id) AS concept_id_no_null,
    COUNT(concept_name) AS concept_name_no_null,
    COUNT(domain_id) AS domain_id_no_null,
    COUNT(standard_concept) AS standard_concept_no_null,
    COUNT(invalid_reason) AS invalid_reason_no_null
FROM PHARMACOVIGILANCE.PUBLIC.CONCEPT;

SELECT 
    COUNT(*) AS total_filas,
    COUNT(primaryid) AS primaryid_no_null,
    COUNT(drug_seq) AS drug_seq_no_null,
    COUNT(role_cod) AS role_cod_no_null,
    COUNT(standard_concept_id) AS concept_id_no_null
FROM PHARMACOVIGILANCE.PUBLIC.STANDARD_CASE_DRUG;

select * from pharmacovigilance.public.standard_case_drug
limit 10;

SELECT *
FROM PHARMACOVIGILANCE.PUBLIC.STANDARD_CASE_DRUG
WHERE primaryid IS NULL
LIMIT 10;

SELECT *
FROM PHARMACOVIGILANCE.PUBLIC.STANDARD_DRUG_OUTCOME_STATISTICS
LIMIT 10;
-- 1.1 How many unique drugs are in the dataset?
-- -----------------------------------------------
SELECT COUNT(DISTINCT STANDARD_CONCEPT_ID) AS unique_drugs
FROM PHARMACOVIGILANCE.PUBLIC.STANDARD_CASE_DRUG;

-- Result: 1,594 unique drugs

-- -----------------------------------------------
-- 1.2 How many unique adverse effects are in the dataset?
-- -----------------------------------------------
SELECT COUNT(DISTINCT OUTCOME_CONCEPT_ID) AS unique_adverse_effects
FROM PHARMACOVIGILANCE.PUBLIC.STANDARD_CASE_OUTCOME;
-- Result: 8,975 unique adverse effects
--Observation: There are significantly more adverse effects (8,975) than drugs (1,594).This makes sense as a single drug can be associated with many different adverse outcomes.

-- -----------------------------------------------
-- 1.3 How many unique cases are in the dataset?
-- -----------------------------------------------
SELECT COUNT(DISTINCT COALESCE(PRIMARYID,ISR))
FROM PHARMACOVIGILANCE.PUBLIC.STANDARD_CASE_DRUG;
-- Result: 47,474 unique cases
-- Observation: COALESCE(primaryid, isr) was used to unify identifiers from two FDA systems — FAERS (current) and LAERS (legacy, pre-2012).
-- -----------------------------------------------
-- 1.4 On average, how many drugs does each case involve?
-- -----------------------------------------------
SELECT 
    COUNT(*) / COUNT(DISTINCT COALESCE(PRIMARYID, ISR)) AS avg_drugs_per_case
FROM PHARMACOVIGILANCE.PUBLIC.STANDARD_CASE_DRUG;
-- Result: 1.01 drugs per case
-- Observation: The low average suggests most cases in this sample involve a single reported drug. This may reflect a sampling limitation and should be considered when interpreting signal detection results.  It is usually known from literature that patients are usually taking more than one drug. I´ll take it in consideration for later on.

-- 1.5 How are drug roles distributed? (PS / SS / C)
-- -----------------------------------------------
SELECT role_cod, COUNT(*) AS total
FROM PHARMACOVIGILANCE.PUBLIC.STANDARD_CASE_DRUG
GROUP BY role_cod ;
-- Result:
-- C  (Concomitant):      23,881
-- PS (Primary Suspect):  15,002
-- SS (Secondary Suspect): 8,945
-- I  (Interacting):         172
-- Observation: Most drug records are concomitant medications with no causal resolution. However, 15,002 drugs are identified as Primary Suspect — a solid base for signal detection. In Section 2, we will filter by PS and cross with PRR/ROR statistics to evaluate which primary suspects show the strongest safety signals.

-- 1.6 What are the most reported drugs?
-- -----------------------------------------------
SELECT c.concept_name AS drug_name, COUNT(*) AS total_reports
FROM PHARMACOVIGILANCE.PUBLIC.STANDARD_CASE_DRUG sd
JOIN PHARMACOVIGILANCE.PUBLIC.CONCEPT c 
    ON sd.standard_concept_id = c.concept_id
GROUP BY c.concept_name
ORDER BY total_reports DESC
LIMIT 10;

-- Result: Top 10 — Etanercept (843), Aspirin (805), Adalimumab (770),Interferon beta-1a (535), Levothyroxine (515), Acetaminophen (501), Simvastatin (474), Natalizumab (471), Atorvastatin (446), Omeprazole (440)
--Observation: Most reported drugs are associated with chronic conditions(autoimmune, cardiovascular, neurological, thyroid). As a nutritionist, it is worth noting that several of these conditions have well-documented nutritional interventions that could complement pharmacological treatment and potentially reduce symptom burden.

-- 1.7 What are the most frequently reported adverse effects?
-- -----------------------------------------------
SELECT c.concept_name AS adverse_effect, COUNT(*) AS total_reports
FROM PHARMACOVIGILANCE.PUBLIC.STANDARD_CASE_OUTCOME sd
JOIN PHARMACOVIGILANCE.PUBLIC.CONCEPT c 
    ON sd.snomed_outcome_concept_id = c.concept_id
GROUP BY c.concept_name
ORDER BY total_reports DESC
LIMIT 10;

-- Result: Dead (5,877), Nausea (5,791), Headache disorder (5,486), Malaise and fatigue (5,259), Diarrhea (3,748), Vomiting (3,725),Joint pain (3,637), Asthenia (3,206), Pain in limb (3,200), Fever (3,100)
-- Observation: Death is the most reported outcome, consistent with FDA mandatory reporting requirements for fatal adverse events. Several of the most reported adverse effects like nausea, vomiting, diarrhea, fatigue and joint pain could have documented nutritional interventions that may complement pharmacological treatment and improve patient outcomes. This cross-disciplinary perspective is a key motivation for this analysis.
-- Note: JOIN was performed on snomed_outcome_concept_id instead of outcome_concept_id, as the CONCEPT table uses OMOP concept IDs which match the SNOMED coding system in this dataset

-- ============================================================
-- SECTION 2: SAFETY SIGNAL DETECTION
-- ============================================================
-- Goal: Identify drug-outcome pairs with statistically significant safety signals using PRR and ROR.
-- ============================================================


-- 2.1 Which drug-outcome pairs have the strongest safety signals?
--     (PRR > 2, case_count > 100, lower confidence interval > 1)
-- -----------------------------------------------
USE DATABASE PHARMACOVIGILANCE;

SELECT 
    drug_concept_id,
    outcome_concept_id,
    case_count,
    prr,
    ror,
    prr_95_lower
FROM PHARMACOVIGILANCE.PUBLIC.STANDARD_DRUG_OUTCOME_STATISTICS
WHERE case_count > 100
    AND prr > 2
    AND prr_95_lower > 1
ORDER BY prr DESC
LIMIT 15;
USE DATABASE PHARMACOVIGILANCE;


USE DATABASE PHARMACOVIGILANCE;

SELECT concept_id, concept_name
FROM PHARMACOVIGILANCE.PUBLIC.CONCEPT
WHERE concept_id IN (1352213, 42709320, 1519936, 986117, 903643, 904525, 1589505, 1549786, 751889, 42709320);

USE DATABASE PHARMACOVIGILANCE;

SELECT 
    CASE s.drug_concept_id
        WHEN 1352213 THEN 'Factor VIII'
        WHEN 42709320 THEN 'Unknown (ID: 42709320)'
        WHEN 1519936 THEN 'Etonogestrel'
        WHEN 986117 THEN 'Ketotifen'
        WHEN 903643 THEN 'Tretinoin'
        WHEN 904525 THEN 'Bimatoprost'
        WHEN 1589505 THEN 'Levonorgestrel'
        WHEN 1549786 THEN 'Ethinyl Estradiol'
        WHEN 751889 THEN 'Glatiramer'
        ELSE 'ID: ' || s.drug_concept_id
    END AS drug_name,
    s.outcome_concept_id,
    s.case_count,
    ROUND(s.prr, 2) AS prr,
    ROUND(s.ror, 2) AS ror
FROM PHARMACOVIGILANCE.PUBLIC.STANDARD_DRUG_OUTCOME_STATISTICS s
WHERE s.case_count > 100
    AND s.prr > 2
    AND s.prr_95_lower > 1
ORDER BY s.prr DESC
LIMIT 10;

-- Result: Top 10 safety signals detected.
--1.Factor VIII (PRR: 6,721) — used in hemophilia treatment. 
-- Nutritional note: Iron-rich foods and dietary support play a complementary role in managing bleeding disorders.

--2.Etonogestrel, Levonorgestrel, Ethinyl Estradiol — hormonal contraceptives appear multiple times, suggesting consistent safety signals for this category.
-- Nutritional note: Hormonal contraceptives are well-documented to interact with nutritional status, particularly B vitamins, magnesium and zinc metabolism.

-- 3.Tretinoin (PRR: 1,800) — Vitamin A derivative used in acne and oncology.
-- Nutritional note: Vitamin A dietary intake requires careful monitoring in patients under Tretinoin treatment due to toxicity risk.

-- Note: outcome_concept_id translation requires full OMOP vocabulary access. Analysis performed on FDA FAERS/LAERS data via AEOLUS pipeline.

-- 2.2 Which drugs have the most safety signals?
-- -----------------------------------------------
USE DATABASE PHARMACOVIGILANCE;

SELECT 
    CASE drug_concept_id
        WHEN 1352213 THEN 'Factor VIII'
        WHEN 42709320 THEN 'ID: 42709320'
        WHEN 1519936 THEN 'Etonogestrel'
        WHEN 986117 THEN 'Ketotifen'
        WHEN 903643 THEN 'Tretinoin'
        WHEN 904525 THEN 'Bimatoprost'
        WHEN 1589505 THEN 'Levonorgestrel'
        WHEN 1549786 THEN 'Ethinyl Estradiol'
        WHEN 751889 THEN 'Glatiramer'
        ELSE 'ID: ' || drug_concept_id
    END AS drug_name,
    COUNT(*) AS total_signals
FROM PHARMACOVIGILANCE.PUBLIC.STANDARD_DRUG_OUTCOME_STATISTICS
WHERE case_count > 100
    AND prr > 2
    AND prr_95_lower > 1
GROUP BY drug_concept_id
ORDER BY total_signals DESC
LIMIT 10;

USE DATABASE PHARMACOVIGILANCE;

SELECT concept_id, concept_name
FROM PHARMACOVIGILANCE.PUBLIC.CONCEPT
WHERE concept_id IN (1119119, 1154029, 1151789, 1305058, 718583, 1310317, 19010482, 1133201, 715233, 1189754);

-- Result: Adalimumab (41), Fentanyl (32), Etanercept (31), Methotrexate (29),Nicotine (26), Cyclophosphamide (22), Buprenorphine (20), Baclofen (18), Rofecoxib (18)
-- Observation: Adalimumab and Etanercept (biologics for autoimmune diseases) top the list, consistent with their high report volume in Section 1. Notably, Rofecoxib (Vioxx) appears in the list — a drug withdrawn from the market in 2004 due to cardiovascular safety issues, validating the signal detection methodology.
   
-- 2.3 Which adverse effects appear most often as safety signals?
-- -----------------------------------------------
USE DATABASE PHARMACOVIGILANCE;

SELECT 
    outcome_concept_id,
    COUNT(*) AS total_signals,
    ROUND(AVG(prr), 2) AS avg_prr
FROM PHARMACOVIGILANCE.PUBLIC.STANDARD_DRUG_OUTCOME_STATISTICS
WHERE case_count > 100
    AND prr > 2
    AND prr_95_lower > 1
GROUP BY outcome_concept_id
ORDER BY total_signals DESC
LIMIT 10;

USE DATABASE PHARMACOVIGILANCE;

SELECT concept_id, concept_name
FROM PHARMACOVIGILANCE.PUBLIC.CONCEPT
WHERE concept_id IN (35809327, 36211195, 35809120, 35809170, 35809131, 35809304, 36211493, 35809377, 36211464, 36211462)
ORDER BY concept_id;

--Result: outcome_concept_id 35809327 (78 signals, avg PRR: 5.31),
-- 36211195 (74 signals, avg PRR: 9.20), 35809120 (72 signals, avg PRR: 7.89)
-- Note: Full outcome name translation requires the complete OMOP vocabular. The avg_prr column shows that effects with fewer signals can still have higher severity signal frequency and intensity are independent metrics.

-- 2.4 Top 10 most dangerous drug-outcome pairs by case count
--     among confirmed signals
-- -----------------------------------------------
SELECT 
    c.concept_name AS drug_name,
    s.outcome_concept_id,
    s.case_count,
    ROUND(s.prr, 2) AS prr,
    ROUND(s.ror, 2) AS ror,
    ROUND(s.prr_95_lower, 2) AS prr_95_lower
FROM PHARMACOVIGILANCE.PUBLIC.STANDARD_DRUG_OUTCOME_STATISTICS s
JOIN PHARMACOVIGILANCE.PUBLIC.CONCEPT c 
    ON s.drug_concept_id = c.concept_id
WHERE s.case_count > 100
    AND s.prr > 2
    AND s.prr_95_lower > 1
ORDER BY s.case_count DESC
LIMIT 10;

-- Result: Top 10 most dangerous drug-outcome pairs by case count among confirmed signals.
-- 1. Etanercept (25,850 cases, PRR: 31.94) — TNF-alpha inhibitor used for rheumatoid arthritis, psoriasis and ankylosing spondylitis.
-- Nutritional note: Patients on immunosuppressants benefit from adequate vitamin D, omega-3 fatty acids and antioxidants to support immune modulation.

-- 2. Tiotropium (15,801 cases, PRR: 298.99) — anticholinergic bronchodilator for COPD. Extremely high PRR suggests strong signal.
-- Nutritional note: COPD patients often experience malnutrition; adequate protein intake and anti-inflammatory nutrients (omega-3, vitamin E) are recommended.

-- 3. Adalimumab (14,265 cases, PRR: 2.36) — TNF-alpha inhibitor for autoimmune conditions. Appears 3 times in top 10 with different outcomes.
-- Nutritional note: Similar to Etanercept, nutritional support focusing on inflammation modulation is beneficial.

-- 4. Esomeprazole (9,775 cases, PRR: 12.27) — proton pump inhibitor for GERD and ulcers.
-- Nutritional note: Long-term PPI use is associated with vitamin B12, magnesium, calcium and iron malabsorption. Supplementation monitoring is essential.

-- 5. Fentanyl (7,742 cases, PRR: 22.99) — potent opioid analgesic for severe pain.
-- Nutritional note: Opioid use commonly causes constipation; adequate fiber, hydration and magnesium intake are important supportive measures.

-- 6. Pregabalin (7,208 cases, PRR: 2.33) — anticonvulsant used for neuropathic pain and anxiety.
-- Nutritional note: Pregabalin may cause weight gain and edema; dietary management and sodium control may help mitigate these effects.

-- Observation: Biologics (Etanercept, Adalimumab) dominate by case volume, consistent with their high reporting rates in Section 1. 
-- Tiotropium shows the highest PRR (298.99), indicating a very strong disproportionality signal for its associated outcome.

