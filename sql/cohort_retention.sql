WITH cte_cohort AS (
       SELECT a.student_id,
              a.cohort_start_term_id,
              b.term_desc,
              b.season,
              b.census_date,
              a.cohort_code,
              a.cohort_code_desc,
              a.cohort_desc,
              a.cohort_degree_level_desc,
              a.full_time_part_time_code,
              a.is_graduated,
              a.is_graduated_year_2,
              a.is_graduated_year_3,
              a.is_graduated_year_4,
              a.is_graduated_year_5,
              a.is_graduated_year_6,
              a.is_graduated_year_7,
              a.is_graduated_year_8,
              a.is_returned_next_fall,
              a.is_returned_next_spring,
              a.is_returned_fall_3,
              a.is_returned_fall_4,
              a.is_returned_fall_5,
              a.is_returned_fall_6,
              a.is_degree_completer_2,
              a.is_degree_completer_3,
              a.is_degree_completer_4,
              a.is_degree_completer_5,
              a.is_degree_completer_6
         FROM export.student_term_cohort a
    LEFT JOIN export.term b
           ON b.term_id = a.cohort_start_term_id
        WHERE a.cohort_desc IN ('First-Time Freshman', 'Transfer')
          AND b.season IN ('Fall', 'Spring')
          AND b.academic_year_code::integer >= (
                  SELECT b1.academic_year_code::integer - 8
                    FROM export.term b1
                   WHERE b1.is_current_term)
)
   SELECT a.student_id,
          a.cohort_start_term_id,
          a.term_desc,
          a.season,
          a.cohort_code,
          a.cohort_code_desc,
          a.cohort_desc,
          EXTRACT(YEAR from AGE(a.census_date, e.birth_date)) AS age_at_census,
          CASE
              WHEN EXTRACT(YEAR from AGE(a.census_date, e.birth_date)) < 26 THEN 'less than 26'
              WHEN EXTRACT(YEAR from AGE(a.census_date, e.birth_date)) BETWEEN 26 and 32 THEN '26 to 32'
              WHEN EXTRACT(YEAR from AGE(a.census_date, e.birth_date)) > 32 THEN 'older than 32'
              ELSE 'error'
          END AS age_at_census_band,
          a.cohort_degree_level_desc,
          a.full_time_part_time_code,
          b.primary_program_id,
          b.primary_major_id,
          b.primary_major_desc,
          c.college_abbrv,
          c.college_desc,
          e.ipeds_race_ethnicity,
          COALESCE(e.is_first_generation, f.is_first_generation) AS is_first_generation,
          COALESCE(e.is_veteran, f.is_veteran) AS is_veteran,
          e.gender_code,
          COALESCE(e.latest_high_school_gpa, f.latest_high_school_gpa) AS hs_gpa,
          CASE
            WHEN COALESCE(e.latest_high_school_gpa, f.latest_high_school_gpa) IS NULL THEN 'NA'
            WHEN COALESCE(e.latest_high_school_gpa, f.latest_high_school_gpa) < 2.00 THEN 'less than 2.0'
            WHEN COALESCE(e.latest_high_school_gpa, f.latest_high_school_gpa) BETWEEN 2.0 AND 2.499 THEN '2.0 to 2.49'
            WHEN COALESCE(e.latest_high_school_gpa, f.latest_high_school_gpa) BETWEEN 2.5 AND 2.999 THEN '2.5 to 2.99'
            WHEN COALESCE(e.latest_high_school_gpa, f.latest_high_school_gpa) BETWEEN 3.0 AND 3.499 THEN '3.0 to 3.499'
            WHEN COALESCE(e.latest_high_school_gpa, f.latest_high_school_gpa) >= 3.5 THEN '3.5-4.0'
            ELSE 'error'
          END AS hs_gpa_band,
          CASE
            WHEN b.student_type_code = 'F'
             AND COALESCE(e.latest_high_school_gpa, f.latest_high_school_gpa) < 2.90
             AND b.overall_cumulative_gpa > 3 THEN FALSE
            WHEN b.student_type_code = 'F'
             AND COALESCE(e.latest_high_school_gpa, f.latest_high_school_gpa) < 3.00 THEN TRUE
            ELSE FALSE
          END AS is_university_college,
          a.is_graduated,
          a.is_graduated_year_2,
          a.is_graduated_year_3,
          a.is_graduated_year_4,
          a.is_graduated_year_5,
          a.is_graduated_year_6,
          a.is_graduated_year_7,
          a.is_graduated_year_8,
          a.is_returned_next_fall,
          a.is_returned_next_spring,
          a.is_returned_fall_3,
          a.is_returned_fall_4,
          a.is_returned_fall_5,
          a.is_returned_fall_6,
          a.is_degree_completer_2,
          a.is_degree_completer_3,
          a.is_degree_completer_4,
          a.is_degree_completer_5,
          a.is_degree_completer_6
     FROM cte_cohort a
LEFT JOIN export.student_term_level_version b
       ON b.student_id = a.student_id
      AND b.term_id = a.cohort_start_term_id
      AND b.is_census_version
      AND b.is_degree_seeking
LEFT JOIN export.academic_programs c
       ON c.program_id = b.primary_program_id
      AND (c.department_desc IS NOT NULL OR c.major_id = 'GE') -- There is an issue with the AS-ELED program in the academic programs table
LEFT JOIN export.student_version e
       ON e.student_id = b.student_id
      AND e.version_snapshot_id = b.version_snapshot_id
LEFT JOIN export.student f
       ON f.student_id = b.student_id
    WHERE a.student_id NOT IN ('00308718', '00379780', '00341050');
