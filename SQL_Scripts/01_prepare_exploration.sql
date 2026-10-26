-- =====================================================
-- STEP 1: VERIFY IMPORTED DATASET
-- =====================================================

-- 1A: Count total appointment records
select count(*) as total_appointments
from public.appointments_raw;

-- 1B: Verify the total number of columns
select count(*) as total_columns
from information_schema.columns
where table_schema = 'public'
	and table_name = 'appointments_raw';

-- =====================================================
-- STEP 2: EXAMINE DATASET STRUCTURE
-- =====================================================

-- 2A: Identify column names and data types
select
	ordinal_position,
	column_name,
	data_type
from information_schema.columns
where table_schema = 'public'
	and table_name = 'appointments_raw'
order by ordinal_position;

-- 2B: Preview the first 10 appointment records
select *
from public.appointments_raw
limit 10;

-- =====================================================
-- STEP 3: SORT APPOINTMENT RECORDS
-- =====================================================

-- 3A: Sort appointments by scheduled date (earliest first)
select
	appointment_id,
	patient_id,
	scheduled_day,
	appointment_day,
	no_show
from public.appointments_raw
order by scheduled_day asc
limit 10;

-- 3B: Sort appointments by pateint age (oldest first)
select
	appointment_id,
	patient_id,
	age,
	appointment_day,
	no_show
from public.appointments_raw
order by age::integer desc
limit 10;

-- =====================================================
-- STEP 4: FILTER APPOINTMENT RECORDS
-- =====================================================

-- 4A: Filter appointments where patients did not attend
select
	appointment_id,
	patient_id,
	gender,
	age,
	appointment_day,
	sms_received,
	no_show
from public.appointments_raw
where no_show = 'Yes'
limit 10;

-- 4B: Filter appointments where pateints attended
select
	appointment_id,
	patient_id,
	gender,
	age,
	appointment_day,
	sms_received,
	no_show
from public.appointments_raw
where no_show = 'No'
limit 10;


-- =====================================================
-- STEP 5: INVESTIGATE DATA INTEGRITY
-- =====================================================

-- 5A: Check for missing values in important columns

SELECT
    COUNT(*) FILTER (
        WHERE patient_id IS NULL OR TRIM(patient_id) = ''
    ) AS missing_patient_ids,
    COUNT(*) FILTER (
        WHERE appointment_id IS NULL OR TRIM(appointment_id) = ''
    ) AS missing_appointment_ids,
    COUNT(*) FILTER (
        WHERE scheduled_day IS NULL OR TRIM(scheduled_day) = ''
    ) AS missing_scheduled_dates,
    COUNT(*) FILTER (
        WHERE appointment_day IS NULL OR TRIM(appointment_day) = ''
    ) AS missing_appointment_dates,
    COUNT(*) FILTER (
        WHERE no_show IS NULL OR TRIM(no_show) = ''
    ) AS missing_no_show_values
FROM public.appointments_raw;

-- 5A.1: Check for missing values in all columns
SELECT
    key AS column_name,
    COUNT(*) FILTER (
        WHERE value = 'null'::jsonb
    ) AS missing_count
FROM public.appointments_raw AS t
CROSS JOIN LATERAL jsonb_each(to_jsonb(t))
GROUP BY key
ORDER BY missing_count DESC, column_name;

-- 5B: Check for duplicate IDs
select
	appointment_id,
	count(*) as occurrence_count
from public.appointments_raw
group by appointment_id
having count(*) > 1
order by occurrence_count desc
limit 10;

-- 5C: Investigate invalid or unusual patient ages
SELECT
    appointment_id,
    patient_id,
    age
FROM public.appointments_raw
WHERE age::INTEGER < 0
   OR age::INTEGER > 110
ORDER BY age::INTEGER DESC;

-- 5D: Check for appointments dated before scheduling
SELECT
    COUNT(*) AS invalid_date_order_count
FROM public.appointments_raw
WHERE LEFT(appointment_day, 10)
    < LEFT(scheduled_day, 10);

-- 5D.1: Examine appointments with inconsistent dates
SELECT
    appointment_id,
    patient_id,
    scheduled_day,
    appointment_day,
    no_show
FROM public.appointments_raw
WHERE LEFT(appointment_day, 10)
    < LEFT(scheduled_day, 10)
ORDER BY scheduled_day;

-- 5E: Check distinct values in the no_show column
SELECT DISTINCT
    no_show
FROM public.appointments_raw
ORDER BY no_show;

-- 5F: Examine distinct values in the handcap column
SELECT
    handcap,
    COUNT(*) AS appointment_count
FROM public.appointments_raw
GROUP BY handcap
ORDER BY handcap::INTEGER;

-- 5G: Examine distinct values in other indicator columns
SELECT
    indicator,
    recorded_value,
    COUNT(*) AS appointment_count
FROM public.appointments_raw
CROSS JOIN LATERAL (
    VALUES
        ('scholarship', scholarship),
        ('hipertension', hipertension),
        ('diabetes', diabetes),
        ('alcoholism', alcoholism),
        ('sms_received', sms_received)
) AS indicators(indicator, recorded_value)
GROUP BY indicator, recorded_value
ORDER BY indicator, recorded_value;

-- 5H: Examine distinct values in the gender column
SELECT
    gender,
    COUNT(*) AS appointment_count
FROM public.appointments_raw
GROUP BY gender
ORDER BY gender;
