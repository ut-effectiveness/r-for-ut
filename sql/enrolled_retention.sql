/*
 Term to term retention
 */
   SELECT a.student_id,
          a.term_id,
          a.is_enrolled_census,
          a.is_returned_next_spring,
          a.is_returned_next_fall,
          c.primary_major_desc,
          c.primary_degree_id,
          c.primary_degree_desc,
          d.college_abbrv,
          d.college_desc,
          e.first_name,
          e.last_name,
          e.gender_code,
          e.ipeds_race_ethnicity,
          e.is_veteran,
          e.is_international,
          e.is_athlete,
          e.is_first_generation,
          CASE
              WHEN c.institutional_cumulative_gpa < 2.0 THEN '0_to_2'
              WHEN c.institutional_cumulative_gpa >= 2.0
               AND c.institutional_cumulative_gpa < 2.5 THEN '2_to_2.5'
              WHEN c.institutional_cumulative_gpa >= 2.5
               AND c.institutional_cumulative_gpa < 3.0 THEN '2.5_to_3'
              WHEN c.institutional_cumulative_gpa >= 3.0
               AND c.institutional_cumulative_gpa <= 4.0 THEN '3_to_4'
              WHEN c.institutional_cumulative_gpa is NULL THEN 'freshman'
         END AS gpa_band,
          COALESCE(f.is_exclusion, FALSE) AS is_exclusion,
          COALESCE(f.cohort_start_term_id, 'None') AS cohort_start_term_id,
          COALESCE(f.cohort_desc, 'None') AS cohort_type
     FROM export.student_term_outcome a
LEFT JOIN export.term b
       ON b.term_id = a.term_id
LEFT JOIN export.student_term_level_version c
       ON c.student_id = a.student_id
      AND c.term_id = a.term_id
      AND c.is_enrolled
      AND c.is_primary_level
      AND c.is_census_version
LEFT JOIN export.academic_programs d
       ON d.program_id = c.primary_program_id
LEFT JOIN export.student e
       ON e.student_id = a.student_id
LEFT JOIN export.student_term_cohort f
       ON f.student_id = a.student_id
      AND f.cohort_desc IN ('First-Time Freshman', 'Transfer')
    WHERE b.season = 'Fall'
      AND substr(a.term_id, 1, 4)::int >= (SELECT substr(term_id, 1, 4)::int - 5
                                     FROM export.term
                                     WHERE is_current_term)
