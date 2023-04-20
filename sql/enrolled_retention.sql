/* RNL Query.  Includes Enrollments At Census, for the last 5 years, Fall/Spring Semesters */
                 /* Deferrals */
            WITH cte_deferrals AS (
          SELECT sgbstdn_pidm,
                 sgbstdn_term_code_eff,
                 sgbstdn_leav_code,
                 TRUE AS is_deferral
            FROM banner.sgbstdn a
           WHERE NULLIF(sgbstdn_leav_code, '') IS NOT NULL
           ),
                 /* Online Tuition */
                 cte_online_tution AS (
          SELECT DISTINCT
                 tbraccd_pidm,
                 tbraccd_term_code,
                 SUM(tbraccd_amount :: numeric),
                 TRUE AS is_online_tuition
            FROM banner.tbraccd a
           WHERE tbraccd_detail_code IN ('1450','1451', '1452', '1460', '1461', '1462') -- Online Tuition Codes
        GROUP BY tbraccd_pidm,
                 tbraccd_term_code
          HAVING SUM(tbraccd_amount :: numeric) > 0 -- excludes reverse tuition charges
          ),
                 cte_cohort AS (
          SELECT a.term_id,
                 d.season,
                 a.student_id,
                 a.sis_system_id,
                 a.is_enrolled,
                 a.is_stopped_out,
                 a.is_dropped_out,
                 a.is_degree_completer_associates,
                 a.is_degree_completer_bachelors,
                 a.is_degree_completer_masters,
                 a.is_enrolled_census,
                 a.level_desc,
                 a.level_id,
                 a.primary_program_id
            FROM export.student_term_outcome a
       LEFT JOIN export.term d
              ON d.term_id = a.term_id
           WHERE d.season IN ('Fall', 'Spring')
             AND d.academic_year_code::integer >= (
                  SELECT d1.academic_year_code::integer - 5
                    FROM export.term d1
                   WHERE d1.is_current_term)
                     )
          /* Main Query */
          SELECT a.term_id,
                 a.season,
                 a.student_id,
                 a.sis_system_id,
                 a.is_enrolled,
                 a.is_stopped_out,
                 a.is_dropped_out,
                 a.is_degree_completer_associates,
                 a.is_degree_completer_bachelors,
                 a.is_degree_completer_masters,
                 a.is_enrolled_census,
                 b.level_id,
                 b.level_desc,
                 b.student_type_code,
                 b.student_type_desc,
                 CASE
                     WHEN b.student_type_code != 'H' THEN TRUE
                     ELSE FALSE
                 END AS is_non_concurrent,
                 CASE
                     WHEN b.student_type_code IN ('T', '2') THEN TRUE
                     ELSE FALSE
                 END AS is_transfer,
                 CASE
                     WHEN b.student_type_code IN ('R', '3') THEN TRUE
                     ELSE FALSE
                 END AS is_readmit,
                 CASE
                     WHEN a.is_degree_completer_associates THEN FALSE
                     WHEN b.student_type_code = 'F'
                      AND COALESCE(e.latest_high_school_gpa, f.latest_high_school_gpa) < 2.90
                      AND b.overall_cumulative_gpa > 3 THEN FALSE
                     WHEN b.student_type_code = 'F'
                      AND COALESCE(e.latest_high_school_gpa, f.latest_high_school_gpa) < 3.00 THEN TRUE
                     ELSE FALSE
                 END AS is_university_college,
                 b.is_degree_seeking,
                 b.full_time_part_time_code,
                 b.primary_program_id,
                 b.primary_major_id,
                 b.primary_major_desc,
                 c.college_abbrv,
                 c.college_desc,
                 e.gender_code,
                 --e.birth_date,
                 EXTRACT(YEAR from AGE(NOW(), e.birth_date)) AS age,
                 e.ipeds_race_ethnicity,
                 COALESCE(e.is_first_generation, f.is_first_generation) AS is_first_generation,
                 COALESCE(e.is_veteran, f.is_veteran) AS is_veteran,
                 COALESCE(b.is_pell_awarded, g.is_pell_awarded, FALSE) AS is_pell_awarded,
                 b.is_pell_eligible,
                 a.is_enrolled,
                 a.is_stopped_out,
                 a.is_dropped_out,
                 COALESCE(h.is_deferral, FALSE) AS is_deferral,
                 COALESCE(b.is_distance_ed_all, g.is_distance_ed_all, FALSE) AS is_distance_ed_all,  -- Online Only
                 COALESCE(b.is_distance_ed_none, g.is_distance_ed_none, FALSE) AS is_distance_ed_none,
                 COALESCE(b.is_distance_ed_some, g.is_distance_ed_some, FALSE) AS is_distance_ed_some,
                 COALESCE(i.is_online_tuition, FALSE) AS is_online_tution,
                 COALESCE(NULLIF(b.primary_major_campus_id, ''), NULLIF(g.primary_major_campus_id, '')) AS primary_major_campus_id,
                 COALESCE(NULLIF(b.primary_major_campus_desc, ''), NULLIF(g.primary_major_campus_desc, '')) AS primary_major_campus_desc,
                 g.institutional_cumulative_gpa,
                 CASE
                     WHEN g.institutional_cumulative_gpa < 2.0 THEN '0_to_2'
                     WHEN g.institutional_cumulative_gpa >= 2.0
                      AND g.institutional_cumulative_gpa < 2.5 THEN '2_to_2.5'
                     WHEN g.institutional_cumulative_gpa >= 2.5
                      AND g.institutional_cumulative_gpa < 3.0 THEN '2.5_to_3'
                     WHEN g.institutional_cumulative_gpa >= 3.0
                      AND g.institutional_cumulative_gpa <= 4.0 THEN '3_to_4'
                 END AS gpa_band,
                 g.institutional_cumulative_credits_earned,
                 g.institutional_cumulative_attempted_credits,
                 g.primary_level_class_desc,
                 g.term_desc
            FROM cte_cohort a
       LEFT JOIN export.student_term_level_version b
              ON b.student_id = a.student_id
             AND b.term_id = a.term_id
             AND b.is_census_version
       LEFT JOIN export.academic_programs c
              ON c.program_id = a.primary_program_id
       LEFT JOIN export.student_version e
              ON e.student_id = b.student_id
             AND e.version_snapshot_id = b.version_snapshot_id
       /* Joining on current tables to back fill data that is missing from census snapshots*/
       LEFT JOIN export.student f
              ON f.student_id = b.student_id
       LEFT JOIN export.student_term_level g
              ON g.student_id = a.student_id
             AND g.term_id = a.term_id
             AND g.is_primary_level
       /* Deferrals */
       LEFT JOIN cte_deferrals h
              ON h.sgbstdn_pidm = b.sis_system_id
             AND h.sgbstdn_term_code_eff = b.term_id
       /* Online Tuition */
       LEFT JOIN cte_online_tution i
              ON i.tbraccd_pidm = b.sis_system_id
             AND i.tbraccd_term_code = b.term_id
       /* cohorts */
       LEFT JOIN export.student_term_cohort j
              ON j.student_id = a.student_id
             AND j.cohort_start_term_id = a.term_id
             AND j.cohort_desc IN ('First-Time Freshman', 'Transfer')
       /* graduation and returned data */
       LEFT JOIN export.student_term_outcome k
              ON k.student_id = a.student_id
             AND k.term_id = a.term_id;
