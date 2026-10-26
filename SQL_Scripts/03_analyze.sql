-- =====================================================
-- STEP 1: DATASET OVERVIEW
-- =====================================================

-- Step 1A: Verify Dataset Size and Date Range
SELECT
    COUNT(*) AS total_appointments,
    COUNT(DISTINCT appointment_id) AS unique_appointments,
    COUNT(DISTINCT patient_id) AS unique_patients,
    MIN(appointment_day) AS first_appointment_date,
    MAX(appointment_day) AS last_appointment_date
FROM public.appointments_clean;

-- Step 1B: Calculate Overall No-Show Rate
SELECT
    COUNT(*) AS total_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 0) AS attended_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 1) AS missed_appointments,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 1)
        / NULLIF(COUNT(*), 0),
        2
    ) AS no_show_rate_pct,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 0)
        / NULLIF(COUNT(*), 0),
        2
    ) AS attended_rate_pct
FROM public.appointments_clean;
-- Of the 110,527 scheduled appointments, 88,208 were attended and 22,319 were missed
-- The overall no-show rate was 20.19%, meaning approximately one in five appointments resulted in a patient not attending
-- The attendance rate was 79.81%, indicating that most scheduled appointments were successfully attended
-- The relatively high number of missed appointments highlights an opportunity to
--  investigate scheduling patterns and patient characteristics associated with nonattendance

-- Step 1C: Analyze No-Show Rates by Gender
SELECT
    gender,
    COUNT(*) AS total_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 0) AS attended_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 1) AS missed_appointments,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 1)
        / NULLIF(COUNT(*), 0),
        2
    ) AS no_show_rate_pct
FROM public.appointments_clean
GROUP BY gender
ORDER BY no_show_rate_pct DESC;
-- Female patients accounted for 71,840 appointments, compared with 38,687 appointments for male patients.
-- Female appointments had a no-show rate of 20.31%, compared with 19.97% for male appointments.
-- The difference was only 0.34 percentage points, indicating relatively similar no-show rates by gender.
-- Although female patients accounted for more missed appointments, this largely reflects their greater number of scheduled appointments.

-- Step 1D: Analyze No-Show Rates by Age Group
WITH age_groups AS (
    SELECT
        CASE
            WHEN age IS NULL THEN 'Unknown'
            WHEN age BETWEEN 0 AND 17 THEN '0-17'
            WHEN age BETWEEN 18 AND 29 THEN '18-29'
            WHEN age BETWEEN 30 AND 44 THEN '30-44'
            WHEN age BETWEEN 45 AND 59 THEN '45-59'
            WHEN age BETWEEN 60 AND 74 THEN '60-74'
            ELSE '75+'
        END AS age_group,
        no_show_flag
    FROM public.appointments_clean
)
SELECT
    age_group,
    COUNT(*) AS total_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 0) AS attended_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 1) AS missed_appointments,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 1)
        / NULLIF(COUNT(*), 0),
        2
    ) AS no_show_rate_pct
FROM age_groups
GROUP BY age_group
ORDER BY
    CASE age_group
        WHEN '0-17' THEN 1
        WHEN '18-29' THEN 2
        WHEN '30-44' THEN 3
        WHEN '45-59' THEN 4
        WHEN '60-74' THEN 5
        WHEN '75+' THEN 6
        ELSE 7
    END;
-- Patients aged 0-17 accounted for the largest number of scheduled appointments (27,379).
-- Patients aged 18-29 had the highest no-show rate at 24.65%, followed by patients aged 0-17 at 21.90%.
-- Patients aged 60-74 had the lowest no-show rate at 15.04%.
-- The difference between the highest and lowest no-show rates was 9.61 percentage points.
-- No-show rates generally decreased among older age groups, with a slight increase for patients 75+.
-- One appointment had an unknown age and was retained as a separate category.

-- Step 1E: Analyze No-Show Rates by Day of the Week
SELECT
    TO_CHAR(appointment_day, 'FMDay') AS appointment_weekday,
    COUNT(*) AS total_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 0) AS attended_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 1) AS missed_appointments,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 1)
        / NULLIF(COUNT(*), 0),
        2
    ) AS no_show_rate_pct,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 0)
        / NULLIF(COUNT(*), 0),
        2
    ) AS attended_rate_pct
FROM public.appointments_clean
GROUP BY
    EXTRACT(ISODOW FROM appointment_day),
    TO_CHAR(appointment_day, 'FMDay')
ORDER BY
    EXTRACT(ISODOW FROM appointment_day);
-- Wednesday had the highest number of scheduled appointments (25,867), followed by Tuesday (25,640).
-- Friday had the highest no-show rate among weekdays at 21.23%, while Thursday had the lowest at 19.35%.
-- The difference between Friday and Thursday was 1.88 percentage points.
-- Saturday had the highest overall no-show rate at 23.08%, but only 39 appointments were recorded.
-- The small Saturday sample limits the reliability of comparisons with other weekdays.
-- No appointments were recorded on Sundays.
-- Weekday no-show rates were relatively similar, ranging from 19.35% to 21.23%.

-- Step 1E.1: Verify Sunday Appointments
SELECT
    COUNT(*) AS sunday_appointments
FROM public.appointments_clean
WHERE EXTRACT(ISODOW FROM appointment_day) = 7;
-- No appointments were recorded on Sundays.
-- Sunday was therefore excluded from the weekday no-show rate analysis.
-- Because no Sunday appointments were recorded, a Sunday no-show rate cannot be calculated.
-- The dataset does not establish whether the clinics were closed on Sundays.

-- Step 1F: Analyze No-Show Rates by Scheduling Lead Time
WITH lead_time_groups AS (
    SELECT
        CASE
            WHEN lead_days IS NULL THEN 'Unknown'
            WHEN lead_days = 0 THEN 'Same Day'
            WHEN lead_days BETWEEN 1 AND 7 THEN '1-7 Days'
            WHEN lead_days BETWEEN 8 AND 14 THEN '8-14 Days'
            WHEN lead_days BETWEEN 15 AND 30 THEN '15-30 Days'
            ELSE '31+ Days'
        END AS lead_time_group,
        no_show_flag
    FROM public.appointments_clean
)
SELECT
    lead_time_group,
    COUNT(*) AS total_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 0) AS attended_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 1) AS missed_appointments,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 1)
        / NULLIF(COUNT(*), 0),
        2
    ) AS no_show_rate_pct,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 0)
        / NULLIF(COUNT(*), 0),
        2
    ) AS attended_rate_pct
FROM lead_time_groups
GROUP BY lead_time_group
ORDER BY
    CASE lead_time_group
        WHEN 'Same Day' THEN 1
        WHEN '1-7 Days' THEN 2
        WHEN '8-14 Days' THEN 3
        WHEN '15-30 Days' THEN 4
        WHEN '31+ Days' THEN 5
        ELSE 6
    END;
-- Same-day appointments accounted for the largest number of scheduled appointments (38,563).
-- Same-day appointments had the lowest no-show rate at 4.65%.
-- Appointments scheduled 1-7 days in advance had a no-show rate of 24.15%.
-- No-show rates increased to 30.47% for appointments scheduled 8-14 days in advance.
-- Appointments scheduled 15-30 days in advance had a no-show rate of 32.59%.
-- Appointments scheduled 31+ days in advance had the highest valid lead-time no-show rate at 33.00%.
-- The difference between same-day and 31+ day appointments was 28.35 percentage points.
-- Five appointments had unknown lead times, and all five were no-shows. This group is too small for meaningful comparison.
-- Longer scheduling lead times were associated with higher appointment no-show rates.

-- Step 1G: Analyze No-Show Rates by SMS Reminder Status
SELECT
    CASE
        WHEN sms_received = 1 THEN 'SMS Received'
        WHEN sms_received = 0 THEN 'No SMS Received'
        ELSE 'Unknown'
    END AS sms_status,
    COUNT(*) AS total_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 0) AS attended_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 1) AS missed_appointments,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 1)
        / NULLIF(COUNT(*), 0),
        2
    ) AS no_show_rate_pct,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 0)
        / NULLIF(COUNT(*), 0),
        2
    ) AS attended_rate_pct
FROM public.appointments_clean
GROUP BY sms_received
ORDER BY sms_received DESC;
-- A total of 35,482 appointments were associated with an SMS reminder, while 75,045 were not.
-- Appointments with an SMS reminder had a no-show rate of 27.57%.
-- Appointments without an SMS reminder had a no-show rate of 16.70%.
-- The difference between the two groups was 10.87 percentage points.
-- Appointments marked as receiving SMS reminders had a higher observed no-show rate.
-- This comparison does not establish that SMS reminders caused patients to miss appointments.
-- Scheduling lead time may help explain the observed difference between the groups.

-- Step 1H: Analyze SMS Reminders by Scheduling Lead Time
WITH lead_time_groups AS (
    SELECT
        CASE
            WHEN lead_days IS NULL THEN 'Unknown'
            WHEN lead_days = 0 THEN 'Same Day'
            WHEN lead_days BETWEEN 1 AND 7 THEN '1-7 Days'
            WHEN lead_days BETWEEN 8 AND 14 THEN '8-14 Days'
            WHEN lead_days BETWEEN 15 AND 30 THEN '15-30 Days'
            ELSE '31+ Days'
        END AS lead_time_group,
        sms_received,
        no_show_flag
    FROM public.appointments_clean
)
SELECT
    lead_time_group,
    CASE
        WHEN sms_received = 1 THEN 'SMS Received'
        WHEN sms_received = 0 THEN 'No SMS Received'
        ELSE 'Unknown'
    END AS sms_status,
    COUNT(*) AS total_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 0)
        AS attended_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 1)
        AS missed_appointments,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 1)
        / NULLIF(COUNT(*), 0),
        2
    ) AS no_show_rate_pct,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 0)
        / NULLIF(COUNT(*), 0),
        2
    ) AS attended_rate_pct
FROM lead_time_groups
GROUP BY lead_time_group, sms_received
ORDER BY
    CASE lead_time_group
        WHEN 'Same Day' THEN 1
        WHEN '1-7 Days' THEN 2
        WHEN '8-14 Days' THEN 3
        WHEN '15-30 Days' THEN 4
        WHEN '31+ Days' THEN 5
        ELSE 6
    END,
    sms_received DESC NULLS LAST;
-- All 38,563 same-day appointments were recorded without SMS reminders and had a 4.65% no-show rate.
-- Among appointments scheduled 1-7 days in advance, the SMS group had a slightly lower no-show rate
-- 	(23.76%) than the no-SMS group (24.36%).
-- For appointments scheduled 8-14 days in advance, no-show rates were 28.11% with SMS versus 33.76% without SMS.
-- For appointments scheduled 15-30 days in advance, no-show rates were 29.80% with SMS versus 36.87% without SMS.
-- For appointments scheduled 31+ days in advance, no-show rates were 30.20% with SMS versus 37.53% without SMS.
-- Within every comparable lead-time category, the SMS group had a lower observed no-show rate.
-- The overall SMS comparison was influenced by same-day appointments, which received no SMS.
-- These associations do not establish that SMS reminders caused better appointment attendance.

-- Step 1I: Compare SMS No-Show Rates
-- Excluding Same-Day Appointments
SELECT
    CASE
        WHEN sms_received = 1 THEN 'SMS Received'
        WHEN sms_received = 0 THEN 'No SMS Received'
        ELSE 'Unknown'
    END AS sms_status,
    COUNT(*) AS total_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 0)
        AS attended_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 1)
        AS missed_appointments,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 1)
        / NULLIF(COUNT(*), 0),
        2
    ) AS no_show_rate_pct,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 0)
        / NULLIF(COUNT(*), 0),
        2
    ) AS attended_rate_pct
FROM public.appointments_clean
WHERE lead_days >= 1
GROUP BY sms_received
ORDER BY sms_received DESC;
-- After excluding same-day appointments and records with unknown lead times, 71,959 appointments remained.
-- Of these, 35,482 appointments received SMS reminders, while 36,477 did not.
-- Appointments with SMS reminders had a no-show rate of 27.57%.
-- Appointments without SMS reminders had a no-show rate of 29.44%.
-- The SMS group had a 1.87 percentage-point lower no-show rate than the no-SMS group.
-- Excluding same-day appointments reversed the overall relationship observed in Step 1G.
-- Same-day appointments substantially influenced the original SMS comparison.
-- The results suggest that scheduling lead time is important when evaluating SMS reminders.
-- These findings do not establish a causal effect of SMS reminders on attendance.

-- Step 1J: Analyze No-Show Rates by Scholarship Status
SELECT
    CASE
        WHEN scholarship = 1 THEN 'Scholarship'
        WHEN scholarship = 0 THEN 'No Scholarship'
        ELSE 'Unknown'
    END AS scholarship_status,
    COUNT(*) AS total_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 0)
        AS attended_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 1)
        AS missed_appointments,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 1)
        / NULLIF(COUNT(*), 0),
        2
    ) AS no_show_rate_pct,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 0)
        / NULLIF(COUNT(*), 0),
        2
    ) AS attended_rate_pct
FROM public.appointments_clean
GROUP BY scholarship
ORDER BY scholarship DESC NULLS LAST;
-- A total of 10,861 appointments were associated with scholarship participants, compared with 99,666 appointments for nonparticipants.
-- Scholarship participants had a no-show rate of 23.74%, compared with 19.81% for nonparticipants.
-- The difference between the two groups was 3.93 percentage points.
-- Scholarship participants had an attendance rate of 76.26%, compared with 80.19% for nonparticipants.
-- Scholarship status was associated with differences in appointment attendance.
-- These results do not establish that scholarship participation causes missed appointments.

-- Step 1K: Analyze No-Show Rates by Hypertension Status
SELECT
    CASE
        WHEN hypertension = 1 THEN 'Hypertension'
        WHEN hypertension = 0 THEN 'No Hypertension'
        ELSE 'Unknown'
    END AS hypertension_status,
    COUNT(*) AS total_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 0)
        AS attended_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 1)
        AS missed_appointments,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 1)
        / NULLIF(COUNT(*), 0),
        2
    ) AS no_show_rate_pct,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 0)
        / NULLIF(COUNT(*), 0),
        2
    ) AS attended_rate_pct
FROM public.appointments_clean
GROUP BY hypertension
ORDER BY hypertension DESC NULLS LAST;
-- A total of 21,801 appointments were associated with patients recorded as having hypertension,
--	 compared with 88,726 without hypertension.
-- Patients with hypertension had a no-show rate of 17.30%, compared with 20.90% for patients without hypertension.
-- The difference between the two groups was 3.60 percentage points.
-- Patients with hypertension had an attendance rate of 82.70%, compared with 79.10% for patients without hypertension.
-- Hypertension status was associated with differences in appointment attendance.
-- Age may influence this relationship because older patients may be more likely to have hypertension and were previously observed
--	 to have lower no-show rates.
-- These findings do not establish that hypertension causes better attendance.

-- Step 1L: Analyze No-Show Rates by Diabetes Status
SELECT
    CASE
        WHEN diabetes = 1 THEN 'Diabetes'
        WHEN diabetes = 0 THEN 'No Diabetes'
        ELSE 'Unknown'
    END AS diabetes_status,
    COUNT(*) AS total_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 0)
        AS attended_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 1)
        AS missed_appointments,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 1)
        / NULLIF(COUNT(*), 0),
        2
    ) AS no_show_rate_pct,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 0)
        / NULLIF(COUNT(*), 0),
        2
    ) AS attended_rate_pct
FROM public.appointments_clean
GROUP BY diabetes
ORDER BY diabetes DESC NULLS LAST;
-- A total of 7,943 appointments were associated with patients recorded as having diabetes, compared with 102,584 without diabetes.
-- Patients with diabetes had a no-show rate of 18.00%, compared with 20.36% for patients without diabetes.
-- The difference between the two groups was 2.36 percentage points.
-- Patients with diabetes had an attendance rate of 82.00%, compared with 79.64% for patients without diabetes.
-- Diabetes status was associated with differences in appointment attendance.
-- Similar to hypertension, patients with diabetes had a lower observed no-show rate.
-- Age may influence this relationship because diabetes is more common among older adults.
-- These findings do not establish that diabetes causes better appointment attendance.

-- Step 1M: Analyze No-Show Rates by Alcoholism Status
SELECT
    CASE
        WHEN alcoholism = 1 THEN 'Alcoholism Recorded'
        WHEN alcoholism = 0 THEN 'No Alcoholism Recorded'
        ELSE 'Unknown'
    END AS alcoholism_status,
    COUNT(*) AS total_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 0)
        AS attended_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 1)
        AS missed_appointments,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 1)
        / NULLIF(COUNT(*), 0),
        2
    ) AS no_show_rate_pct,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 0)
        / NULLIF(COUNT(*), 0),
        2
    ) AS attended_rate_pct
FROM public.appointments_clean
GROUP BY alcoholism
ORDER BY alcoholism DESC NULLS LAST;
-- A total of 3,360 appointments were associated with patients having an alcoholism indicator,
--	 compared with 107,167 appointments without it.
-- Appointments with the alcoholism indicator had a no-show rate of 20.15%.
-- Appointments without the alcoholism indicator had a no-show rate of 20.19%.
-- The difference between the two groups was only 0.04 percentage points.
-- Attendance rates were nearly identical, at 79.85% and 79.81%, respectively.
-- Alcoholism status showed little difference in appointment attendance in this comparison.
-- These findings do not establish that alcoholism has no relationship with appointment attendance
--	 after accounting for other patient characteristics.

-- Step 1N: Analyze No-Show Rates by Handicap Status
SELECT
    CASE
        WHEN handcap = 0 THEN 'None Recorded'
        WHEN handcap = 1 THEN 'Value 1'
        WHEN handcap = 2 THEN 'Value 2'
        WHEN handcap = 3 THEN 'Value 3'
        WHEN handcap = 4 THEN 'Value 4'
        ELSE 'Unknown'
    END AS handicap_status,
    COUNT(*) AS total_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 0)
        AS attended_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 1)
        AS missed_appointments,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 1)
        / NULLIF(COUNT(*), 0),
        2
    ) AS no_show_rate_pct,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 0)
        / NULLIF(COUNT(*), 0),
        2
    ) AS attended_rate_pct
FROM public.appointments_clean
GROUP BY handcap
ORDER BY handcap NULLS LAST;
-- Most appointments (108,286) had a handicap indicator of 0, with a no-show rate of 20.24%.
-- Category 1 included 2,042 appointments and had a no-show rate of 17.92%.
-- Category 2 included 183 appointments and had a no-show rate of 20.22%.
-- Category 3 included only 13 appointments and had a no-show rate of 23.08%.
-- Category 4 included only 3 appointments and had a no-show rate of 33.33%.
-- Categories 3 and 4 had extremely small sample sizes, limiting meaningful comparisons.
-- The recorded codes cannot be interpreted as disability severity without supporting documentation.
-- No consistent relationship between handicap indicator values and no-show rates was established.

-- Step 1O: Analyze No-Show Rates by Neighborhood
SELECT
    neighbourhood,
    COUNT(*) AS total_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 0)
        AS attended_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 1)
        AS missed_appointments,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 1)
        / NULLIF(COUNT(*), 0),
        2
    ) AS no_show_rate_pct,
     ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 0)
        / NULLIF(COUNT(*), 0),
        2
    ) AS attended_rate_pct
FROM public.appointments_clean
WHERE neighbourhood IS NOT NULL
GROUP BY neighbourhood
HAVING COUNT(*) >= 100
ORDER BY
    no_show_rate_pct DESC,
    total_appointments DESC
LIMIT 15;
-- Santos Dumont had the highest no-show rate among qualifying neighborhoods at 28.92%, with 369 missed appointments out of 1,276.
-- Santa Cecilia ranked second at 27.46%, followed by Santa Clara at 26.48%.
-- Itarare had a no-show rate of 26.27% and recorded 923 missed appointments out of 3,514.
-- Jesus de Nazareth recorded 696 missed appointments and a no-show rate of 24.40%.
-- The top-ranked neighborhoods had no-show rates above the overall dataset average of 20.19%.
-- High no-show rates did not always correspond to the highest numbers of missed appointments.
-- Only neighborhoods with at least 100 appointments were included in this exploratory ranking.
-- Geographic differences do not establish that neighborhood location causes missed appointments.

-- Step 1P: Identify Neighborhoods with the Most Missed Appointments
SELECT
    neighbourhood,
    COUNT(*) AS total_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 0)
        AS attended_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 1)
        AS missed_appointments,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 1)
        / NULLIF(COUNT(*), 0),
        2
    ) AS no_show_rate_pct,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 0)
        / NULLIF(COUNT(*), 0),
        2
    ) AS attended_rate_pct
FROM public.appointments_clean
WHERE neighbourhood IS NOT NULL
GROUP BY neighbourhood
HAVING COUNT(*) >= 100
ORDER BY
    missed_appointments DESC,
    total_appointments DESC
LIMIT 15;
-- Jardim Camburi recorded the highest number of missed appointments (1,465), with a no-show rate of 18.98%.
-- Maria Ortiz ranked second with 1,219 missed appointments and a no-show rate of 21.00%.
-- Itarare ranked third with 923 missed appointments and a no-show rate of 26.27%.
-- The five neighborhoods with the most missed appointments accounted for 5,216 no-shows,
--	 approximately 23.37% of all missed appointments.
-- Jardim Camburi had the most missed appointments despite having a below-average no-show rate.
-- Comparing Steps 1O and 1P demonstrates that high no-show rates and high missed-appointment
--	 counts identify different geographic priorities.
-- Higher appointment volumes can produce more missed appointments even when rates are lower.
-- Neighborhood differences do not establish geographic location as a cause of no-shows.

-- Step 1Q: Complete Neighborhood Summary
SELECT
    neighbourhood,
    COUNT(*) AS total_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 0)
        AS attended_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 1)
        AS missed_appointments,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 1)
        / NULLIF(COUNT(*), 0),
        2
    ) AS no_show_rate_pct,
     ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 0)
        / NULLIF(COUNT(*), 0),
        2
    ) AS attended_rate_pct
FROM public.appointments_clean
GROUP BY neighbourhood
ORDER BY total_appointments DESC;
-- The complete neighborhood summary contains 81 neighborhoods.
-- Jardim Camburi had the highest appointment volume, with 7,717 scheduled appointments.
-- Jardim Camburi recorded 1,465 missed appointments and a no-show rate of 18.98%.
-- Santos Dumont had a comparatively high no-show rate of 28.92%.
-- Some neighborhoods had very small sample sizes, resulting in extreme no-show rates.
-- Ilhas Oceanicas de Trindade recorded a 100% no-show rate based on only two appointments.
-- Parque Industrial recorded a 0% no-show rate based on only one appointment.
-- Small sample sizes limit the reliability of comparisons between neighborhoods.
-- The complete summary preserves all neighborhoods for further analysis and visualization.

-- Step 1R: Analyze Daily Appointment Trends
SELECT
    appointment_day,
    COUNT(*) AS total_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 0)
        AS attended_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 1)
        AS missed_appointments,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 1)
        / NULLIF(COUNT(*), 0),
        2
    ) AS no_show_rate_pct,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 0)
        / NULLIF(COUNT(*), 0),
        2
    ) AS attended_rate_pct
FROM public.appointments_clean
GROUP BY appointment_day
ORDER BY appointment_day;
-- The dataset contains appointments across 27 distinct dates from April 29 to June 8, 2016.
-- June 6 recorded the highest appointment volume, with 4,692 scheduled appointments.
-- May 16 had the most missed appointments on a single date, with 1,049 no-shows.
-- May 20 had the highest daily no-show rate at 23.48%.
-- June 8 had the lowest daily no-show rate at 17.28%.
-- The difference between the highest and lowest daily no-show rates was 6.20 percentage points.
-- May 14 had only 39 appointments, making its daily no-show rate less reliable for comparisons.
-- Daily no-show rates fluctuated throughout the observation period.
-- The final observed dates generally showed lower no-show rates than several earlier dates.
-- The short observation period limits conclusions about long-term attendance trends.

-- Step 1S: Analyze Weekly Appointment Trends
SELECT
    DATE_TRUNC('week', appointment_day)::date
        AS week_start,
    COUNT(DISTINCT appointment_day)
        AS appointment_days,
    COUNT(*) AS total_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 0)
        AS attended_appointments,
    COUNT(*) FILTER (WHERE no_show_flag = 1)
        AS missed_appointments,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 1)
        / NULLIF(COUNT(*), 0),
        2
    ) AS no_show_rate_pct,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show_flag = 0)
        / NULLIF(COUNT(*), 0),
        2
    ) AS attended_rate_pct
FROM public.appointments_clean
GROUP BY DATE_TRUNC('week', appointment_day)::date
ORDER BY week_start;
-- The dataset contains appointments across 7 calendar weeks from April 25 to June 6, 2016.
-- The week of May 9 had the highest appointment volume, with 21,722 scheduled appointments.
-- The week of May 16 recorded the most missed appointments (4,665) and the highest weekly no-show rate (21.74%).
-- Weekly no-show rates increased from 20.37% during the week of May 2 to 21.74% during the week of May 16.
-- After May 16, weekly no-show rates declined, reaching 18.13% during the week of June 6.
-- The difference between the peak rate and final observed weekly rate was 3.61 percentage points.
-- The week of May 23 contained only two recorded appointment days.
-- The first and last observed weeks were also incomplete.
-- Differences in the number of appointment days limit direct comparisons of weekly volumes.
-- The short observation period does not establish a long-term improvement in attendance.

-- =====================================================
-- STEP 2: ADVANCED STATISTICAL ANALYSIS
-- =====================================================

-- Step 2A: Correlation with Appointment No-Shows
SELECT
    ROUND(CORR(age::NUMERIC, no_show_flag::NUMERIC)::NUMERIC, 4)
        AS age_correlation,
    ROUND(CORR(lead_days::NUMERIC, no_show_flag::NUMERIC)::NUMERIC, 4)
        AS lead_days_correlation,
    ROUND(CORR(sms_received::NUMERIC, no_show_flag::NUMERIC)::NUMERIC, 4)
        AS sms_received_correlation,
    ROUND(CORR(scholarship::NUMERIC, no_show_flag::NUMERIC)::NUMERIC, 4)
        AS scholarship_correlation
FROM public.appointments_clean;
-- Lead days had the strongest positive correlation with no-shows (r = 0.1863), indicating a weak positive relationship.
-- SMS reminders also showed a weak positive correlation with no-shows (r = 0.1264).
-- The positive SMS correlation does not establish that reminders cause missed appointments.
-- Age showed a very weak negative correlation (r = -0.0603), suggesting slightly fewer no-shows among older patients.
-- Scholarship status showed a negligible positive correlation (r = 0.0291).
-- Overall, none of the four variables demonstrated a strong linear relationship with appointment no-shows.
-- Correlation alone cannot establish causation or account for potentially confounding variables.

-- Step 2B: Identify Variables for Correlation Analysis
SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'appointments_clean'
ORDER BY ordinal_position;

-- Step 2C: Comprehensive Correlation Analysis
SELECT
    ROUND(CORR(age::NUMERIC, no_show_flag::NUMERIC)::NUMERIC, 4)
        AS age_correlation,
    ROUND(CORR(lead_days::NUMERIC, no_show_flag::NUMERIC)::NUMERIC, 4)
        AS lead_days_correlation,
    ROUND(CORR(sms_received::NUMERIC, no_show_flag::NUMERIC)::NUMERIC, 4)
        AS sms_received_correlation,
    ROUND(CORR(scholarship::NUMERIC, no_show_flag::NUMERIC)::NUMERIC, 4)
        AS scholarship_correlation,
    ROUND(CORR(hypertension::NUMERIC, no_show_flag::NUMERIC)::NUMERIC, 4)
        AS hypertension_correlation,
    ROUND(CORR(diabetes::NUMERIC, no_show_flag::NUMERIC)::NUMERIC, 4)
        AS diabetes_correlation,
    ROUND(CORR(alcoholism::NUMERIC, no_show_flag::NUMERIC)::NUMERIC, 4)
        AS alcoholism_correlation,
    ROUND(
        CORR(
            (CASE
                WHEN handcap > 0 THEN 1
                WHEN handcap = 0 THEN 0
                ELSE NULL
            END)::NUMERIC,
            no_show_flag::NUMERIC
        )::NUMERIC, 4
    ) AS handicap_correlation,
    ROUND(
        CORR(
            (CASE
                WHEN UPPER(TRIM(gender)) = 'F' THEN 1
                WHEN UPPER(TRIM(gender)) = 'M' THEN 0
                ELSE NULL
            END)::NUMERIC,
            no_show_flag::NUMERIC
        )::NUMERIC, 4
    ) AS gender_correlation
FROM public.appointments_clean;
-- Lead days had the strongest positive correlation with no-shows (r = 0.1863), indicating a weak positive relationship.
-- SMS reminders had the second-strongest positive correlation (r = 0.1264), although this does not establish causation.
-- Age showed a very weak negative correlation (r = -0.0603), suggesting slightly fewer no-shows among older patients.
-- Hypertension (r = -0.0357) and diabetes (r = -0.0152) showed very weak negative correlations.
-- Scholarship status showed a very weak positive correlation (r = 0.0291).
-- Alcoholism (r = -0.0002) and handicap (r = -0.0073) showed negligible negative correlations.
-- Gender showed a negligible positive correlation (r = 0.0041), using female = 1 and male = 0.
-- Overall, no individual variable demonstrated a strong linear relationship with appointment no-shows.
-- These findings suggest that scheduling-related factors may be more informative than the other individual variables examined.
-- Correlation does not establish causation, and nonlinear or combined relationships may still exist.