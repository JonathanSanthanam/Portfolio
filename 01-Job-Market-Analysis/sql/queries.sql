USE analyst_jobs;

SELECT 'BA' AS source, COUNT(*) AS total_rows FROM ba_jobs_raw
UNION ALL
SELECT 'DA', COUNT(*) FROM da_jobs_raw;

CREATE TABLE jobs_combined AS
SELECT
    id,
    job_title,
    salary_estimate,
    job_description,
    rating,
    company_name,
    location,
    headquarters,
    company_size,
    founded,
    type_of_ownership,
    industry,
    sector,
    revenue,
    competitors,
    easy_apply,
    'Business Analyst' AS role_type
FROM ba_jobs_raw

UNION ALL

SELECT
    id,
    job_title,
    salary_estimate,
    job_description,
    rating,
    company_name,
    location,
    headquarters,
    company_size,
    founded,
    type_of_ownership,
    industry,
    sector,
    revenue,
    competitors,
    easy_apply,
    'Data Analyst' AS role_type
FROM da_jobs_raw;

ALTER TABLE jobs_combined ADD COLUMN job_id INT AUTO_INCREMENT PRIMARY KEY FIRST;

SELECT role_type, COUNT(*) AS job_count
FROM jobs_combined
GROUP BY role_type;

-- Verifica formato Salary
SELECT
    CASE
        WHEN salary_estimate LIKE '%$%K%' THEN 'Valid'
        ELSE 'Invalid/Missing'
    END AS salary_status,
    COUNT(*) AS count
FROM jobs_combined
GROUP BY salary_status;

CREATE VIEW jobs_clean AS
SELECT
    job_id,
    job_title,
    role_type,
    
    -- Salary Parsing
    CAST(
        REPLACE(REPLACE(SUBSTRING_INDEX(salary_estimate, '-', 1), '$', ''), 'K', '') 
        AS UNSIGNED
    ) * 1000 AS salary_min,
    
    CAST(
        REPLACE(REPLACE(
            SUBSTRING_INDEX(SUBSTRING_INDEX(salary_estimate, ' (', 1), '-', -1),
            '$', ''), 'K', '') 
        AS UNSIGNED
    ) * 1000 AS salary_max,
    
    -- Rating (NULL instead of -1)
    CASE WHEN CAST(rating AS DECIMAL(3,1)) = -1 THEN NULL ELSE CAST(rating AS DECIMAL(3,1)) END AS rating,
    
    -- Company name clean
    TRIM(SUBSTRING_INDEX(company_name, '\n', 1)) AS company_name_clean,
    
    -- Location split
    TRIM(SUBSTRING_INDEX(location, ',', 1)) AS city,
    TRIM(SUBSTRING_INDEX(location, ',', -1)) AS state,
    
    -- Company info
    industry,
    sector,
    company_size,
    revenue,
    founded,
    type_of_ownership,
    
    -- Job details
    job_description,
    easy_apply

FROM jobs_combined
WHERE salary_estimate LIKE '%$%K%';

DROP VIEW IF EXISTS jobs_analysis;
DROP VIEW IF EXISTS jobs_clean;

CREATE VIEW jobs_clean AS
SELECT
    job_id,
    job_title,
    role_type,
    
    -- Salary Parsing
    CAST(
        REPLACE(REPLACE(SUBSTRING_INDEX(salary_estimate, '-', 1), '$', ''), 'K', '') 
        AS UNSIGNED
    ) * 1000 AS salary_min,
    
    CAST(
        REPLACE(REPLACE(
            SUBSTRING_INDEX(SUBSTRING_INDEX(salary_estimate, ' (', 1), '-', -1),
            '$', ''), 'K', '') 
        AS UNSIGNED
    ) * 1000 AS salary_max,
    
    -- Rating (NULL instead of -1)
    CASE WHEN CAST(rating AS DECIMAL(3,1)) = -1 THEN NULL ELSE CAST(rating AS DECIMAL(3,1)) END AS rating,
    
    -- Company name clean
    TRIM(SUBSTRING_INDEX(company_name, '\n', 1)) AS company_name_clean,
    
    -- Location split
    TRIM(SUBSTRING_INDEX(location, ',', 1)) AS city,
    TRIM(SUBSTRING_INDEX(location, ',', -1)) AS state,
    
    -- Company info
    industry,
    sector,
    company_size,
    revenue,
    founded,
    type_of_ownership,
    
    -- Job details
    job_description,
    easy_apply

FROM jobs_combined
WHERE salary_estimate LIKE '%$%K%';

CREATE VIEW jobs_analysis AS
SELECT
    j.*,
    (salary_min + salary_max) / 2 AS salary_avg,
    salary_max - salary_min AS salary_range
FROM jobs_clean j;

SELECT COUNT(*) AS clean_records FROM jobs_analysis;
SELECT * FROM jobs_analysis LIMIT 5;

-- KPI Summary
SELECT
    COUNT(*) AS total_jobs,
    COUNT(DISTINCT company_name_clean) AS unique_companies,
    COUNT(DISTINCT state) AS unique_states,
    ROUND(AVG(salary_avg), 0) AS avg_salary,
    ROUND(AVG(rating), 2) AS avg_rating
FROM jobs_analysis;

-- BA vs DA Comparison
SELECT
    role_type,
    COUNT(*) AS job_count,
    ROUND(AVG(salary_avg), 0) AS avg_salary,
    ROUND(AVG(rating), 2) AS avg_rating,
    COUNT(DISTINCT company_name_clean) AS unique_companies
FROM jobs_analysis
GROUP BY role_type;

-- Salary by State (top 15)
SELECT
    state,
    COUNT(*) AS job_count,
    ROUND(AVG(salary_avg), 0) AS avg_salary,
    ROUND(MIN(salary_min), 0) AS min_salary,
    ROUND(MAX(salary_max), 0) AS max_salary
FROM jobs_analysis
WHERE state IS NOT NULL AND TRIM(state) != ''
GROUP BY state
HAVING job_count >= 50
ORDER BY avg_salary DESC
LIMIT 15;

-- Top Industries
SELECT
    industry,
    COUNT(*) AS job_count,
    ROUND(AVG(salary_avg), 0) AS avg_salary,
    ROUND(AVG(rating), 2) AS avg_rating
FROM jobs_analysis
WHERE industry IS NOT NULL AND industry != '-1' AND industry != ''
GROUP BY industry
HAVING job_count >= 50
ORDER BY avg_salary DESC
LIMIT 15;

-- Skills Analysis
SELECT
    role_type,
    COUNT(*) AS sample_size,
    ROUND(SUM(CASE WHEN LOWER(job_description) LIKE '%sql%' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS sql_pct,
    ROUND(SUM(CASE WHEN LOWER(job_description) LIKE '%python%' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS python_pct,
    ROUND(SUM(CASE WHEN LOWER(job_description) LIKE '%excel%' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS excel_pct,
    ROUND(SUM(CASE WHEN LOWER(job_description) LIKE '%tableau%' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS tableau_pct,
    ROUND(SUM(CASE WHEN LOWER(job_description) LIKE '%power bi%' OR LOWER(job_description) LIKE '%powerbi%' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS powerbi_pct
FROM jobs_analysis
GROUP BY role_type;

-- Seniority Analysis
SELECT
    CASE
        WHEN LOWER(job_title) LIKE '%senior%' OR LOWER(job_title) LIKE '%sr.%' OR LOWER(job_title) LIKE '%sr %' OR LOWER(job_title) LIKE '%lead%' THEN 'Senior'
        WHEN LOWER(job_title) LIKE '%junior%' OR LOWER(job_title) LIKE '%jr.%' OR LOWER(job_title) LIKE '%jr %' OR LOWER(job_title) LIKE '%entry%' THEN 'Junior'
        WHEN LOWER(job_title) LIKE '%manager%' OR LOWER(job_title) LIKE '%director%' OR LOWER(job_title) LIKE '%head%' THEN 'Management'
        ELSE 'Mid-Level'
    END AS seniority,
    COUNT(*) AS job_count,
    ROUND(AVG(salary_avg), 0) AS avg_salary,
    ROUND(MIN(salary_min), 0) AS min_salary,
    ROUND(MAX(salary_max), 0) AS max_salary
FROM jobs_analysis
GROUP BY seniority
ORDER BY avg_salary DESC;

-- Rank Companies by Salary within Industry
WITH company_stats AS (
    SELECT
        company_name_clean,
        industry,
        COUNT(*) AS job_count,
        ROUND(AVG(salary_avg), 0) AS avg_salary
    FROM jobs_analysis
    WHERE industry IS NOT NULL AND industry != '-1' AND industry != ''
    GROUP BY company_name_clean, industry
    HAVING job_count >= 3
),
ranked AS (
    SELECT
        company_name_clean,
        industry,
        job_count,
        avg_salary,
        RANK() OVER (PARTITION BY industry ORDER BY avg_salary DESC) AS salary_rank
    FROM company_stats
)
SELECT * FROM ranked
WHERE salary_rank <= 3
ORDER BY industry, salary_rank;

-- BA vs DA Salary by State
SELECT
    state,
    SUM(CASE WHEN role_type = 'Business Analyst' THEN 1 ELSE 0 END) AS ba_jobs,
    SUM(CASE WHEN role_type = 'Data Analyst' THEN 1 ELSE 0 END) AS da_jobs,
    ROUND(AVG(CASE WHEN role_type = 'Business Analyst' THEN salary_avg END), 0) AS ba_avg_salary,
    ROUND(AVG(CASE WHEN role_type = 'Data Analyst' THEN salary_avg END), 0) AS da_avg_salary,
    ROUND(AVG(CASE WHEN role_type = 'Business Analyst' THEN salary_avg END) -
          AVG(CASE WHEN role_type = 'Data Analyst' THEN salary_avg END), 0) AS salary_diff
FROM jobs_analysis
WHERE state IS NOT NULL AND TRIM(state) != ''
GROUP BY state
HAVING ba_jobs >= 10 AND da_jobs >= 5
ORDER BY salary_diff DESC
LIMIT 15;

-- Salary Percentiles
WITH salary_ranked AS (
    SELECT
        salary_avg,
        NTILE(4) OVER (ORDER BY salary_avg) AS quartile
    FROM jobs_analysis
    WHERE salary_avg IS NOT NULL
)
SELECT
    quartile,
    MIN(salary_avg) AS min_salary,
    MAX(salary_avg) AS max_salary,
    ROUND(AVG(salary_avg), 0) AS avg_salary,
    COUNT(*) AS job_count
FROM salary_ranked
GROUP BY quartile
ORDER BY quartile;

-- Top Hiring Companies
SELECT
    company_name_clean,
    COUNT(*) AS job_count,
    ROUND(AVG(salary_avg), 0) AS avg_salary,
    ROUND(AVG(rating), 2) AS avg_rating,
    industry
FROM jobs_analysis
GROUP BY company_name_clean, industry
HAVING job_count >= 10
ORDER BY job_count DESC
LIMIT 20;

CREATE VIEW jobs_export AS
SELECT
    job_id,
    job_title,
    role_type,
    salary_min,
    salary_max,
    salary_avg,
    salary_max - salary_min AS salary_range,
    rating,
    company_name_clean AS company_name,
    city,
    state,
    industry,
    sector,
    company_size,
    revenue,
    founded,
    type_of_ownership,
    easy_apply,
    CASE WHEN LOWER(job_description) LIKE '%sql%' THEN 1 ELSE 0 END AS has_sql,
    CASE WHEN LOWER(job_description) LIKE '%python%' THEN 1 ELSE 0 END AS has_python,
    CASE WHEN LOWER(job_description) LIKE '%excel%' THEN 1 ELSE 0 END AS has_excel,
    CASE WHEN LOWER(job_description) LIKE '%tableau%' THEN 1 ELSE 0 END AS has_tableau,
    CASE WHEN LOWER(job_description) LIKE '%power bi%' OR LOWER(job_description) LIKE '%powerbi%' THEN 1 ELSE 0 END AS has_powerbi,
    CASE
        WHEN LOWER(job_title) LIKE '%senior%' OR LOWER(job_title) LIKE '%sr.%' OR LOWER(job_title) LIKE '%sr %' OR LOWER(job_title) LIKE '%lead%' THEN 'Senior'
        WHEN LOWER(job_title) LIKE '%junior%' OR LOWER(job_title) LIKE '%jr.%' OR LOWER(job_title) LIKE '%jr %' OR LOWER(job_title) LIKE '%entry%' THEN 'Junior'
        WHEN LOWER(job_title) LIKE '%manager%' OR LOWER(job_title) LIKE '%director%' OR LOWER(job_title) LIKE '%head%' THEN 'Management'
        ELSE 'Mid-Level'
    END AS seniority
FROM jobs_analysis;

SELECT * FROM jobs_export;
