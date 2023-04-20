/*
 Program tracking
 */
   SELECT a.student_id,
          a.cohort_start_term_id,
          b.term_desc AS cohort,
          a.cohort_desc,
          a.cohort_degree_level_desc,
          c.term_id AS subsequent_term_id,
          f.term_desc AS subsequent_term_desc,
          CASE
              WHEN e.college_abbrv IS NOT NULL THEN e.college_abbrv
              WHEN c.is_degree_completer_associates OR is_degree_completer_bachelors OR is_degree_completer_masters THEN 'completer'
              WHEN (c.is_stopped_out OR c.is_dropped_out) THEN 'not_enrolled'
              ELSE 'error'
          END AS term_status,
           e.college_abbrv AS college,
          COALESCE(e.department_desc, e.college_abbrv) AS department,
          c.is_enrolled,
          c.is_dropped_out,
          c.is_stopped_out,
          c.is_degree_completer_bachelors,
          c.is_degree_completer_associates,
          c.is_degree_completer_certificate,
          c.is_degree_completer_associates OR is_degree_completer_bachelors OR is_degree_completer_masters AS completer,
          c.primary_program_id,
          d.primary_major_id,
          d.primary_major_desc
     FROM export.student_term_cohort a
LEFT JOIN export.term b
       ON b.term_id = a.cohort_start_term_id
LEFT JOIN export.student_term_outcome c
       ON c.student_id = a.student_id
      AND c.term_id::int >= a.cohort_start_term_id::int
      AND c.season IN ('Fall', 'Spring')
LEFT JOIN export.student_term_level_version d
       ON d.student_id = c.student_id
      AND d.term_id = c.term_id
      AND d.is_enrolled
      AND d.is_primary_level
      AND d.is_census_version
LEFT JOIN export.academic_programs e
       ON e.program_id = d.primary_program_id
LEFT JOIN export.term f
       ON f.term_id = c.term_id
    WHERE b.season = 'Fall'
      --AND a.cohort_start_term_id = '201840'
      AND a.cohort_desc IN ('First-Time Freshman', 'Transfer')
      AND substr(a.cohort_start_term_id, 1, 4)::int >= (SELECT substr(term_id, 1, 4)::int - 5
                                                          FROM export.term
                                                         WHERE is_current_term)
