
# Medical Appointment No-Show Analysis

**PostgreSQL | SQL | Tableau | Healthcare Analytics**

## Project Overview

This project analyzes historical medical appointment data to identify factors associated with patient no-shows and recommend opportunities to improve healthcare scheduling efficiency.

The analysis was developed for **Cedar Valley Community Health**, a fictional outpatient healthcare organization, using a publicly available dataset containing 110,527 medical appointments from Brazil.

The project demonstrates an end-to-end data analytics workflow involving data exploration, cleaning, validation, SQL analysis, Tableau visualizations, and business recommendations.

## Business Problem

Missed medical appointments can lead to unused appointment slots, inefficient resource allocation, and reduced patient access to healthcare services.

Cedar Valley Community Health seeks to understand appointment attendance patterns and identify opportunities to reduce missed visits.

### Key Business Questions

1. What is the overall appointment no-show rate?
2. How does appointment scheduling lead time relate to attendance?
3. What relationship exists between SMS reminders and no-show rates?
4. Which patient demographic and geographic characteristics are associated with missed appointments?
5. What recommendations could improve scheduling efficiency and patient attendance?

## Tools and Technologies

- **PostgreSQL:** Data storage, cleaning, transformation, validation, and analysis
- **DBeaver:** SQL development and database management
- **SQL:** CTEs, conditional aggregation, grouping, filtering, date calculations, and data-quality validation
- **Tableau:** Data visualization and dashboard development
- **CSV:** Exported analytical summaries

## Dataset

**Dataset:** Medical Appointment No Shows

**Source:** [Kaggle - Medical Appointment No Shows](https://www.kaggle.com/datasets/joniarroba/noshowappointments)

**Creator:** Joni Hoppen, with attribution to Aquarela Analytics

**License:** Creative Commons Attribution-NonCommercial-ShareAlike 4.0 (CC BY-NC-SA 4.0)

### Dataset Overview

- 110,527 medical appointment records
- 14 original columns
- Historical appointment information from Brazil
- Patient demographics, scheduling information, SMS reminder status, and attendance outcomes

The original and cleaned patient-level CSV datasets are not included in this repository. The original dataset can be accessed through Kaggle.

## Data Cleaning and Preparation

Data preparation was performed using PostgreSQL and DBeaver.

The cleaning process included:

1. Exploring the raw dataset and identifying data-quality issues.
2. Creating a separate cleaned working table while preserving the original dataset.
3. Standardizing column names and correcting data types.
4. Investigating invalid and unusual patient ages.
5. Identifying invalid appointment scheduling dates.
6. Calculating appointment scheduling lead times.
7. Creating derived variables for age groups and no-show indicators.
8. Validating cleaned records against the original dataset.
9. Exporting aggregated analytical summaries for visualization.

### SQL Workflow

The project is organized into three SQL scripts:

1. [Data Exploration](SQL_Scripts/01_prepare_exploration.sql)
2. [Data Cleaning and Validation](SQL_Scripts/02_process_cleaning.sql)
3. [Exploratory and Descriptive Analysis](SQL_Scripts/03_analyze.sql)

## Key Findings

### 1. Overall Appointment No-Show Rate

The analysis examined 110,527 medical appointments.

| Metric | Result |
|---|---:|
| Total Appointments | 110,527 |
| Missed Appointments | 22,319 |
| Overall No-Show Rate | 20.19% |

Approximately one in five scheduled appointments resulted in a no-show.

### 2. Scheduling Lead Time

Scheduling lead time showed one of the strongest observed relationships with appointment attendance.

| Scheduling Lead Time | No-Show Rate |
|---|---:|
| Same Day | 4.65% |
| 1-7 Days | 24.15% |
| 8-14 Days | 30.47% |
| 15-30 Days | 32.59% |
| 31+ Days | 33.00% |

Appointments scheduled farther in advance were associated with higher no-show rates.

![No-Show Rate by Lead Time](Visualizations/No-Show%20Rate%20by%20Lead%20Time.png)

### 3. SMS Reminder Analysis

SMS reminder results differed when scheduling lead time was considered.

Among appointments scheduled 31 or more days in advance:

- **With SMS reminders:** 30.20% no-show rate
- **Without SMS reminders:** 37.53% no-show rate

After excluding same-day appointments, the no-show rates were 27.57% for appointments with SMS reminders and 29.44% for those without reminders.

These findings suggest that targeted reminder strategies warrant further evaluation.

However, the observational data does not establish that SMS reminders caused improved attendance.

![SMS Reminders by Lead Time](Visualizations/SMS%20Reminders%20by%20Lead%20Time.png)

### 4. Patient Age Groups

Appointment no-show rates varied across age groups.

- **Ages 18-29:** 24.65%
- **Ages 60-74:** 15.04%
- **Ages 75+:** 16.02%

Patients aged 18-29 had the highest no-show rate among the defined age groups.

![No-Show Rate by Age Group](Visualizations/No-Show%20Rate%20by%20Age%20Group.png)

### 5. Neighborhood Analysis

Neighborhood analysis revealed differences between no-show percentages and missed-appointment volumes.

- **Santos Dumont:** 28.92% no-show rate
- **Jardim Camburi:** 1,465 missed appointments, despite a lower no-show rate of 18.98%

These findings highlight the importance of considering both appointment volume and no-show percentages when prioritizing improvements.

![Neighborhood No-Show Analysis](Visualizations/Neighborhood%20No-Show%20Analysis.png)

### 6. Appointment Timing Trends

Additional analysis examined appointment weekdays and weekly no-show trends.

Friday had the highest no-show rate among Monday-Friday appointments at 21.23%.

The relatively short observation period limits conclusions about long-term attendance trends.

![No-Show Rate by Weekday](Visualizations/No-Show%20Rate%20by%20Weekday.png)

![Weekly No-Show Trend](Visualizations/Weekly%20No-Show%20Trend.png)

## Business Recommendations

### Recommendation 1: Reduce Scheduling Delays

Review appointment capacity and offer earlier available appointment slots when clinically appropriate.

Implement appointment confirmation and rescheduling procedures for appointments booked well in advance.

### Recommendation 2: Pilot Targeted SMS Reminders

Evaluate an opt-in SMS reminder process for appointments with longer scheduling lead times.

Compare attendance outcomes among patients with similar lead times before expanding the reminder strategy.

### Recommendation 3: Improve Targeted Patient Outreach

Validate demographic and neighborhood attendance patterns using local appointment data.

Investigate scheduling, communication, and accessibility barriers to guide targeted patient support.

## Tableau Workbook

The final Tableau workbook contains the visualizations developed to investigate appointment attendance patterns.

[View Final Tableau Workbook](Tableau/Cedar_Valley_No_Show.twbx)

## Project Structure

```text
medical-appointment-no-show-analysis/
|
|-- Analysis_Outputs/
|   |-- age_group_summary.csv
|   |-- day_appointment_summary.csv
|   |-- lead_time_summary.csv
|   |-- neighborhood_summary.csv
|   |-- patient_characteristics_summary.csv
|   |-- sms_lead_time_summary.csv
|   |-- weekday_summary.csv
|   |-- weekly_appointment_summary.csv
|
|-- Documentation/
|   |-- Ivan_Sandoval_No_Show_Case_Study.pdf
|
|-- SQL_Scripts/
|   |-- 01_prepare_exploration.sql
|   |-- 02_process_cleaning.sql
|   |-- 03_analyze.sql
|
|-- Tableau/
|   |-- Cedar_Valley_No_Show.twbx
|
|-- Visualizations/
|   |-- Neighborhood No-Show Analysis.png
|   |-- No-Show Rate by Age Group.png
|   |-- No-Show Rate by Lead Time.png
|   |-- No-Show Rate by Weekday.png
|   |-- SMS Reminders by Lead Time.png
|   |-- Weekly No-Show Trend.png
|
|-- README.md
```

## Full Case Study Report

The complete report includes:

- Executive summary
- Business task and stakeholder objectives
- Data sources and limitations
- SQL data cleaning and validation
- Exploratory and descriptive analysis
- Supporting visualizations and findings
- Business recommendations
- Appendix tables and SQL queries

[Read the Complete Case Study Report](Documentation/Ivan_Sandoval_No_Show_Case_Study.pdf)

## Limitations

- The dataset contains historical appointments from Brazil.
- Cedar Valley Community Health is a fictional healthcare organization.
- Results may not generalize to other healthcare systems or patient populations.
- The dataset does not include all factors that may influence missed appointments.
- Relationships identified through observational analysis do not establish causation.
- Local validation would be necessary before implementing operational recommendations.

## Conclusion

This project identified scheduling lead time as an important factor associated with medical appointment attendance.

The analysis also revealed differences in no-show rates related to SMS reminder status, patient age groups, and geographic characteristics.

By combining SQL-based data preparation, exploratory analysis, and Tableau visualizations, the project demonstrates how healthcare data can be translated into practical, evidence-informed business recommendations.

## Author

**Ivan J. Sandoval**

Data Analytics Portfolio Project

[GitHub Profile](https://github.com/IvnSandoval)
