
-- =====================================================
-- STEP 1: VERIFY THE ORIGINAL DATASET
-- =====================================================

-- 1A: Check total number of records in the raw dataset
SELECT COUNT(*) AS total_records
FROM public.appointments_raw;

-- =====================================================
-- STEP 2: CHECK THE DATA FOR ERRORS
-- =====================================================

-- 2A: Investigate unusual patient ages
SELECT
    age,
    COUNT(*) AS record_count
FROM public.appointments_raw
WHERE age IN ('-1', '115')
GROUP BY age
ORDER BY age;

-- 2A.1: Investigate all patient ages
SELECT
    age,
    COUNT(*) AS record_count
FROM public.appointments_raw
GROUP BY age
ORDER BY age::INTEGER DESC;

-- 2B: Investigate scheduling-date inconsistencies
SELECT
    appointment_id,
    scheduled_day,
    appointment_day,
    no_show
FROM public.appointments_raw
WHERE LEFT(appointment_day, 10)::DATE
    < LEFT(scheduled_day, 10)::DATE
ORDER BY appointment_day;

-- 2C: Investigate values in the handcap column
SELECT
    handcap,
    COUNT(*) AS record_count
FROM public.appointments_raw
GROUP BY handcap
ORDER BY handcap;

-- 2D: Investigate appointment outcome categories
SELECT
    no_show,
    COUNT(*) AS record_count
FROM public.appointments_raw
GROUP BY no_show
ORDER BY no_show;

-- 2E: Check for invalid categorical and binary values
SELECT
    COUNT(*) FILTER (
        WHERE gender IS NULL
           OR gender NOT IN ('F', 'M')
    ) AS invalid_gender,
    COUNT(*) FILTER (
        WHERE scholarship IS NULL
           OR scholarship NOT IN ('0', '1')
    ) AS invalid_scholarship,
    COUNT(*) FILTER (
        WHERE hipertension IS NULL
           OR hipertension NOT IN ('0', '1')
    ) AS invalid_hypertension,
    COUNT(*) FILTER (
        WHERE diabetes IS NULL
           OR diabetes NOT IN ('0', '1')
    ) AS invalid_diabetes,
    COUNT(*) FILTER (
        WHERE alcoholism IS NULL
           OR alcoholism NOT IN ('0', '1')
    ) AS invalid_alcoholism,
    COUNT(*) FILTER (
        WHERE sms_received IS NULL
           OR sms_received NOT IN ('0', '1')
    ) AS invalid_sms_received
FROM public.appointments_raw;

-- 2F: Check for missing or blank values in all columns
SELECT
    column_name,
    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(column_value), '') IS NULL
    ) AS missing_count
FROM public.appointments_raw
CROSS JOIN LATERAL (
    VALUES
        ('patient_id', patient_id),
        ('appointment_id', appointment_id),
        ('gender', gender),
        ('scheduled_day', scheduled_day),
        ('appointment_day', appointment_day),
        ('age', age),
        ('neighbourhood', neighbourhood),
        ('scholarship', scholarship),
        ('hipertension', hipertension),
        ('diabetes', diabetes),
        ('alcoholism', alcoholism),
        ('handcap', handcap),
        ('sms_received', sms_received),
        ('no_show', no_show)
) AS columns_check(column_name, column_value)
GROUP BY column_name
ORDER BY column_name;

-- 2G: Check for duplicate appointment IDs
SELECT
    appointment_id,
    COUNT(*) AS duplicate_count
FROM public.appointments_raw
GROUP BY appointment_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 2H: Check for invalid numeric formatting
SELECT
    COUNT(*) FILTER (
        WHERE appointment_id !~ '^[0-9]+$'
    ) AS invalid_appointment_id,
    COUNT(*) FILTER (
        WHERE age !~ '^-?[0-9]+$'
    ) AS invalid_age_format,
    COUNT(*) FILTER (
        WHERE handcap !~ '^[0-9]+$'
    ) AS invalid_handcap_format
FROM public.appointments_raw;

-- =====================================================
-- STEP 3: PREPARE THE CLEANED WORKING TABLE
-- =====================================================

-- 3A: Inspect identifier and date formats
SELECT
    patient_id,
    appointment_id,
    scheduled_day,
    appointment_day,
    age
FROM public.appointments_raw
LIMIT 10;


-- 3B: Validate date formats across the dataset
SELECT
    COUNT(*) FILTER (
        WHERE scheduled_day !~
        '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'
    ) AS invalid_scheduled_format,
    COUNT(*) FILTER (
        WHERE appointment_day !~
        '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'
    ) AS invalid_appointment_format,
    COUNT(*) FILTER (
        WHERE RIGHT(appointment_day, 9) <> '00:00:00Z'
    ) AS non_midnight_appointments
FROM public.appointments_raw;

-- 3C: Test data type conversions
SELECT
    COUNT(*) AS total_records,
    MIN(scheduled_day::TIMESTAMPTZ) AS earliest_scheduled,
    MAX(scheduled_day::TIMESTAMPTZ) AS latest_scheduled,
    MIN(LEFT(appointment_day, 10)::DATE) AS earliest_appointment,
    MAX(LEFT(appointment_day, 10)::DATE) AS latest_appointment,
    MAX(appointment_id::NUMERIC) AS max_appointment_id,
    MIN(age::NUMERIC) AS min_age,
    MAX(age::NUMERIC) AS max_age
FROM public.appointments_raw;

-- 3D: Create the cleaned working table
/*
CREATE TABLE public.appointments_clean AS
SELECT
    patient_id,
    appointment_id::BIGINT AS appointment_id,
    gender,
    scheduled_day::TIMESTAMPTZ AS scheduled_day,
    LEFT(appointment_day, 10)::DATE AS appointment_day,
    age::INTEGER AS age,
    neighbourhood,
    scholarship::SMALLINT AS scholarship,
    hipertension::SMALLINT AS hypertension,
    diabetes::SMALLINT AS diabetes,
    alcoholism::SMALLINT AS alcoholism,
    handcap::INTEGER AS handcap,
    sms_received::SMALLINT AS sms_received,
    no_show
FROM public.appointments_raw;
*/

-- 3E: Validate record counts and appointment uniqueness
SELECT
    (SELECT COUNT(*)
     FROM public.appointments_raw) AS raw_records,
    (SELECT COUNT(*)
     FROM public.appointments_clean) AS clean_records,
    (SELECT COUNT(DISTINCT appointment_id)
     FROM public.appointments_clean) AS unique_appointments;

-- =====================================================
-- STEP 4: CLEAN AND TRANSFORM THE DATA
-- =====================================================

-- 4A: Inspect records with invalid negative ages
SELECT
    appointment_id,
    patient_id,
    age,
    gender,
    scheduled_day,
    appointment_day,
    no_show
FROM public.appointments_clean
WHERE age < 0;

-- 4A.1: Check other appointments for the patient with an invalid age
SELECT
    appointment_id,
    patient_id,
    age,
    appointment_day,
    no_show
FROM public.appointments_clean
WHERE patient_id = (
    SELECT patient_id
    FROM public.appointments_clean
    WHERE age = -1
)
ORDER BY appointment_day;

-- 4B: Replace invalid patient age with NULL
-- Reason: Age -1 is invalid, and the correct age cannot be verified from other appointments.
-- Preserve the appointment and original raw record.
/*
UPDATE public.appointments_clean
SET age = NULL
WHERE appointment_id = 5775010
  AND age = -1
RETURNING
    appointment_id,
    age;
*/

-- 4B.1: Verify the invalid age was corrected
SELECT
    appointment_id,
    age
FROM public.appointments_clean
WHERE appointment_id = 5775010;

-- 4C: Investigate patients aged 115
SELECT
    appointment_id,
    patient_id,
    age,
    gender,
    neighbourhood,
    appointment_day,
    no_show
FROM public.appointments_clean
WHERE age = 115
ORDER BY patient_id, appointment_day;

-- 4C.1: Check age consistency for patients aged 115
SELECT
    patient_id,
    appointment_id,
    age,
    appointment_day,
    no_show
FROM public.appointments_clean
WHERE patient_id IN (
    SELECT DISTINCT patient_id
    FROM public.appointments_clean
    WHERE age = 115
)
ORDER BY patient_id, appointment_day, appointment_id;

-- 4D.1: Investigate scheduling-date inconsistencies
SELECT
    appointment_id,
    patient_id,
    (scheduled_day AT TIME ZONE 'UTC')::DATE
        AS scheduled_date,
    appointment_day,
    appointment_day -
        (scheduled_day AT TIME ZONE 'UTC')::DATE
        AS lead_days,
    no_show
FROM public.appointments_clean
WHERE appointment_day <
    (scheduled_day AT TIME ZONE 'UTC')::DATE
ORDER BY appointment_id;

-- 4D.2: Create a column for appointment lead times
ALTER TABLE public.appointments_clean
ADD COLUMN IF NOT EXISTS lead_days INTEGER;

-- 4D.3: Calculate valid appointment lead times
-- Negative lead times are assigned NULL.
-- Original appointment dates remain unchanged.
UPDATE public.appointments_clean
SET lead_days = CASE
    WHEN appointment_day >=
        (scheduled_day AT TIME ZONE 'UTC')::DATE
    THEN appointment_day -
        (scheduled_day AT TIME ZONE 'UTC')::DATE
    ELSE NULL
END;

-- 4D.4: Validate calculated appointment lead times
SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE lead_days IS NOT NULL
    ) AS valid_lead_times,
    COUNT(*) FILTER (
        WHERE lead_days IS NULL
    ) AS missing_lead_times,
    COUNT(*) FILTER (
        WHERE lead_days < 0
    ) AS negative_lead_times,
    COUNT(*) FILTER (
        WHERE lead_days IS DISTINCT FROM
            CASE
                WHEN appointment_day >=
                    (scheduled_day AT TIME ZONE 'UTC')::DATE
                THEN appointment_day -
                    (scheduled_day AT TIME ZONE 'UTC')::DATE
                ELSE NULL
            END
    ) AS mismatched_lead_times
FROM public.appointments_clean;

-- 4E.1: Validate handcap values after data type conversion
SELECT
    handcap,
    COUNT(*) AS record_count
FROM public.appointments_clean
GROUP BY handcap
ORDER BY handcap;

-- 4E.2: Handcap cleaning decision
-- All values (0-4) were preserved during conversion.
-- Values greater than 1 were investigated.
-- Their exact meaning could not be verified.
-- No changes were made to the handcap column.

-- =====================================================
-- 4F: STANDARDIZE APPOINTMENT OUTCOME
-- =====================================================

-- 4F.1: Create numeric no-show indicator
ALTER TABLE public.appointments_clean
ADD COLUMN IF NOT EXISTS no_show_flag SMALLINT;

-- 4F.2: Convert appointment outcomes into numeric values
-- Yes = 1 (Patient missed appointment)
-- No = 0 (Patient did not miss appointment)
UPDATE public.appointments_clean
SET no_show_flag = CASE
    WHEN no_show = 'Yes' THEN 1
    WHEN no_show = 'No' THEN 0
    ELSE NULL
END
WHERE no_show_flag IS NULL;

-- 4F.3: Validate numeric no-show indicators
SELECT
    no_show,
    no_show_flag,
    COUNT(*) AS record_count
FROM public.appointments_clean
GROUP BY
    no_show,
    no_show_flag
ORDER BY no_show_flag;

-- =====================================================
-- 4G: CHECK NEIGHBORHOOD NAME CONSISTENCY
-- =====================================================

-- 4G.1: Check capitalization and whitespace
SELECT
    COUNT(DISTINCT neighbourhood)
        AS original_neighbourhoods,
    COUNT(DISTINCT UPPER(TRIM(neighbourhood)))
        AS standardized_neighbourhoods,
    COUNT(*) FILTER (
        WHERE neighbourhood <> TRIM(neighbourhood)
    ) AS whitespace_issues,
    COUNT(*) FILTER (
        WHERE neighbourhood <> UPPER(neighbourhood)
    ) AS capitalization_issues
FROM public.appointments_clean;

-- 4G.2: Inspect all unique neighborhood names
SELECT
    neighbourhood,
    COUNT(*) AS appointment_count
FROM public.appointments_clean
GROUP BY neighbourhood
ORDER BY neighbourhood;

-- 4G.3: Neighborhood cleaning decision
-- Identified 81 unique neighborhood names.
-- No capitalization or whitespace issues detected.
-- No obvious duplicate spellings found during inspection.
-- Neighborhoods with very few appointments were noted.
-- All original neighborhood names were preserved.
-- Geographic accuracy was not independently verified.

-- =====================================================
-- STEP 5: FINAL DATA-QUALITY VALIDATION
-- =====================================================

-- 5A: Verify cleaned dataset integrity
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT appointment_id)
        AS unique_appointments,
    COUNT(*) FILTER (
        WHERE age < 0
    ) AS negative_ages,
    COUNT(*) FILTER (
        WHERE age IS NULL
    ) AS missing_ages,
    COUNT(*) FILTER (
        WHERE lead_days IS NULL
    ) AS missing_lead_times,
    COUNT(*) FILTER (
        WHERE lead_days < 0
    ) AS negative_lead_times,
    COUNT(*) FILTER (
        WHERE no_show_flag IS DISTINCT FROM
            CASE
                WHEN no_show = 'Yes' THEN 1
                WHEN no_show = 'No' THEN 0
                ELSE NULL
            END
    ) AS incorrect_no_show_flags
FROM public.appointments_clean;

-- 5B: Verify appointment IDs between raw and cleaned tables
SELECT
    COUNT(*) FILTER (
        WHERE r.appointment_id IS NOT NULL
          AND c.appointment_id IS NOT NULL
    ) AS matching_appointments,
    COUNT(*) FILTER (
        WHERE r.appointment_id IS NOT NULL
          AND c.appointment_id IS NULL
    ) AS missing_from_clean,
    COUNT(*) FILTER (
        WHERE r.appointment_id IS NULL
          AND c.appointment_id IS NOT NULL
    ) AS unexpected_in_clean
FROM public.appointments_raw AS r
FULL OUTER JOIN public.appointments_clean AS c
    ON r.appointment_id::BIGINT = c.appointment_id;

-- 5C: Verify original field values against cleaned data
-- Account for intentional data type conversions and the correction of age -1 to NULL.
SELECT
    COUNT(*) AS checked_appointments,
    COUNT(*) FILTER (
        WHERE ROW(
            c.patient_id,
            c.appointment_id,
            c.gender,
            c.scheduled_day,
            c.appointment_day,
            c.age,
            c.neighbourhood,
            c.scholarship,
            c.hypertension,
            c.diabetes,
            c.alcoholism,
            c.handcap,
            c.sms_received,
            c.no_show
        ) IS DISTINCT FROM ROW(
            r.patient_id,
            r.appointment_id::BIGINT,
            r.gender,
            r.scheduled_day::TIMESTAMPTZ,
            LEFT(r.appointment_day, 10)::DATE,
            NULLIF(r.age, '-1')::INTEGER,
            r.neighbourhood,
            r.scholarship::SMALLINT,
            r.hipertension::SMALLINT,
            r.diabetes::SMALLINT,
            r.alcoholism::SMALLINT,
            r.handcap::INTEGER,
            r.sms_received::SMALLINT,
            r.no_show
        )
    ) AS unexpected_field_differences
FROM public.appointments_raw AS r
INNER JOIN public.appointments_clean AS c
    ON r.appointment_id::BIGINT = c.appointment_id;

-- check clean data

select *
from public.appointments_clean