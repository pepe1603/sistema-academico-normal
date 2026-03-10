-- =====================================================
-- LOGIC LAYER (FUNCTIONS, TRIGGERS, VIEWS)
-- Compatible with PostgreSQL 14+
-- =====================================================

-- =====================================================
-- 1. GENERIC FUNCTION: Update updated_at timestamp
-- =====================================================

CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all tables with updated_at field
-- Drop triggers if they exist to avoid errors on re-execution

DROP TRIGGER IF EXISTS trg_update_app_user ON app_user;
CREATE TRIGGER trg_update_app_user
BEFORE UPDATE ON app_user
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_update_role ON role;
CREATE TRIGGER trg_update_role
BEFORE UPDATE ON role
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_update_student ON student;
CREATE TRIGGER trg_update_student
BEFORE UPDATE ON student
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_update_teacher ON teacher;
CREATE TRIGGER trg_update_teacher
BEFORE UPDATE ON teacher
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_update_course ON course;
CREATE TRIGGER trg_update_course
BEFORE UPDATE ON course
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_update_enrollment ON enrollment;
CREATE TRIGGER trg_update_enrollment
BEFORE UPDATE ON enrollment
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_update_generation ON generation;
CREATE TRIGGER trg_update_generation
BEFORE UPDATE ON generation
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_update_study_plan ON study_plan;
CREATE TRIGGER trg_update_study_plan
BEFORE UPDATE ON study_plan
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_update_academic_semester ON academic_semester;
CREATE TRIGGER trg_update_academic_semester
BEFORE UPDATE ON academic_semester
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_update_kardex ON kardex;
CREATE TRIGGER trg_update_kardex
BEFORE UPDATE ON kardex
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_update_report_card ON report_card;
CREATE TRIGGER trg_update_report_card
BEFORE UPDATE ON report_card
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_update_conduct ON conduct;
CREATE TRIGGER trg_update_conduct
BEFORE UPDATE ON conduct
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_update_certificate ON certificate;
CREATE TRIGGER trg_update_certificate
BEFORE UPDATE ON certificate
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_update_guardian ON guardian;
CREATE TRIGGER trg_update_guardian
BEFORE UPDATE ON guardian
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_update_student_document ON student_document;
CREATE TRIGGER trg_update_student_document
BEFORE UPDATE ON student_document
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_update_system_configuration ON system_configuration;
CREATE TRIGGER trg_update_system_configuration
BEFORE UPDATE ON system_configuration
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_update_portal_advertisement ON portal_advertisement;
CREATE TRIGGER trg_update_portal_advertisement
BEFORE UPDATE ON portal_advertisement
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_update_educational_resource ON educational_resource;
CREATE TRIGGER trg_update_educational_resource
BEFORE UPDATE ON educational_resource
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- =====================================================
-- 2. VALIDATE TOTAL EVALUATION WEIGHT (<= 100%)
-- =====================================================

CREATE OR REPLACE FUNCTION fn_validate_course_weight()
RETURNS TRIGGER AS $$
DECLARE
    total_weight NUMERIC(5,2);
BEGIN
    SELECT COALESCE(SUM(weight),0)
    INTO total_weight
    FROM evaluation_type
    WHERE course_id = NEW.course_id
      AND is_active = TRUE;

    IF total_weight > 100 THEN
        RAISE EXCEPTION 
        'El peso total de evaluación excede el 100%% (Total actual: %)',
        total_weight;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_course_weight
AFTER INSERT OR UPDATE ON evaluation_type
FOR EACH ROW
EXECUTE FUNCTION fn_validate_course_weight();

-- =====================================================
-- 3. UTILITY FUNCTIONS: Code Generation
-- =====================================================

-- Generate enrollment number: ENE-YYYY-NNNN
CREATE OR REPLACE FUNCTION fn_generate_enrollment_number(p_year INTEGER)
RETURNS VARCHAR(20) AS $$
DECLARE
    v_consecutive INTEGER;
    v_enrollment_number VARCHAR(20);
BEGIN
    SELECT COALESCE(MAX(
        CAST(SUBSTRING(enrollment_number FROM 9 FOR 4) AS INTEGER)
    ), 0) + 1 INTO v_consecutive
    FROM student
    WHERE enrollment_number LIKE 'ENE-' || p_year || '-%';
    
    v_enrollment_number := 'ENE-' || p_year || '-' || LPAD(v_consecutive::TEXT, 4, '0');
    
    RETURN v_enrollment_number;
END;
$$ LANGUAGE plpgsql;

-- Generate employee number: EMP-YYYY-NNNN
CREATE OR REPLACE FUNCTION fn_generate_employee_number(p_year INTEGER)
RETURNS VARCHAR(20) AS $$
DECLARE
    v_consecutive INTEGER;
    v_employee_number VARCHAR(20);
BEGIN
    SELECT COALESCE(MAX(
        CAST(SUBSTRING(employee_number FROM 9 FOR 4) AS INTEGER)
    ), 0) + 1 INTO v_consecutive
    FROM teacher
    WHERE employee_number LIKE 'EMP-' || p_year || '-%';
    
    v_employee_number := 'EMP-' || p_year || '-' || LPAD(v_consecutive::TEXT, 4, '0');
    
    RETURN v_employee_number;
END;
$$ LANGUAGE plpgsql;

-- Generate course code: XXNNN (2 letters + 3 digits)
CREATE OR REPLACE FUNCTION fn_generate_course_code(p_prefix VARCHAR, p_semester INTEGER)
RETURNS VARCHAR(20) AS $$
DECLARE
    v_consecutive INTEGER;
    v_course_code VARCHAR(20);
BEGIN
    SELECT COALESCE(MAX(
        CAST(SUBSTRING(course_code FROM 4 FOR 3) AS INTEGER)
    ), 0) + 1 INTO v_consecutive
    FROM course
    WHERE course_code LIKE p_prefix || '%';
    
    v_course_code := UPPER(p_prefix) || LPAD(v_consecutive::TEXT, 3, '0');
    
    RETURN v_course_code;
END;
$$ LANGUAGE plpgsql;

-- Generate kardex folio: KX-YYYYMMDD-NNNN
CREATE OR REPLACE FUNCTION fn_generate_kardex_folio()
RETURNS VARCHAR(30) AS $$
DECLARE
    v_folio VARCHAR(30);
    v_consecutive INTEGER;
BEGIN
    SELECT COALESCE(MAX(
        CAST(SUBSTRING(official_folio FROM 15 FOR 4) AS INTEGER)
    ), 0) + 1 INTO v_consecutive
    FROM kardex
    WHERE official_folio LIKE 'KX-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-%';
    
    v_folio := 'KX-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(v_consecutive::TEXT, 4, '0');
    
    RETURN v_folio;
END;
$$ LANGUAGE plpgsql;

-- Generate report card folio: RC-YYYY-NNNN
CREATE OR REPLACE FUNCTION fn_generate_report_card_folio(p_year INTEGER)
RETURNS VARCHAR(30) AS $$
DECLARE
    v_folio VARCHAR(30);
    v_consecutive INTEGER;
BEGIN
    SELECT COALESCE(MAX(
        CAST(SUBSTRING(folio FROM 10 FOR 4) AS INTEGER)
    ), 0) + 1 INTO v_consecutive
    FROM report_card
    WHERE folio LIKE 'RC-' || p_year || '-%';
    
    v_folio := 'RC-' || p_year || '-' || LPAD(v_consecutive::TEXT, 4, '0');
    
    RETURN v_folio;
END;
$$ LANGUAGE plpgsql;

-- Generate certificate folio: CERT-YYYY-NNNN
CREATE OR REPLACE FUNCTION fn_generate_certificate_folio(p_year INTEGER)
RETURNS VARCHAR(50) AS $$
DECLARE
    v_folio VARCHAR(50);
    v_consecutive INTEGER;
BEGIN
    SELECT COALESCE(MAX(
        CAST(SUBSTRING(official_folio FROM 15 FOR 4) AS INTEGER)
    ), 0) + 1 INTO v_consecutive
    FROM certificate
    WHERE official_folio LIKE 'CERT-' || p_year || '-%';
    
    v_folio := 'CERT-' || p_year || '-' || LPAD(v_consecutive::TEXT, 4, '0');
    
    RETURN v_folio;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 4. PROCEDURE: Enroll student in course
-- El profesor se asigna a través del group_id
-- =====================================================

CREATE OR REPLACE FUNCTION sp_enroll_student(
    p_student_id UUID,
    p_course_id UUID,
    p_period_id UUID,
    p_group_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_enrollment_id UUID;
BEGIN
    IF EXISTS (
        SELECT 1
        FROM enrollment
        WHERE student_id = p_student_id
          AND course_id = p_course_id
          AND academic_period_id = p_period_id
          AND is_deleted = FALSE
    ) THEN
        RAISE EXCEPTION 'El estudiante ya está inscrito en esta materia para este período académico';
    END IF;

    INSERT INTO enrollment (id, student_id, course_id, academic_period_id, group_id, status, is_active, is_deleted, created_at)
    VALUES (uuid_generate_v4(), p_student_id, p_course_id, p_period_id, p_group_id, 'ENROLLED', TRUE, FALSE, now())
    RETURNING id INTO v_enrollment_id;

    RETURN v_enrollment_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 5. FUNCTION: Convert numeric grade to letter
-- =====================================================

CREATE OR REPLACE FUNCTION fn_grade_to_letter(p_grade NUMERIC)
RETURNS VARCHAR(2) AS $$
BEGIN
    CASE
        WHEN p_grade >= 90 THEN RETURN 'A';
        WHEN p_grade >= 80 THEN RETURN 'B';
        WHEN p_grade >= 70 THEN RETURN 'C';
        WHEN p_grade >= 60 THEN RETURN 'D';
        WHEN p_grade < 60 THEN RETURN 'F';
        ELSE RETURN 'N/A';
    END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =====================================================
-- 6. PROCEDURE: Calculate kardex average
-- =====================================================

CREATE OR REPLACE FUNCTION fn_calculate_kardex_average(p_student_id UUID, p_semester_id UUID DEFAULT NULL)
RETURNS NUMERIC(5,2) AS $$
DECLARE
    v_average NUMERIC(5,2);
BEGIN
    IF p_semester_id IS NULL THEN
        SELECT ROUND(AVG(final_grade), 2)
        INTO v_average
        FROM kardex
        WHERE student_id = p_student_id 
          AND status IN ('APPROVED', 'EXTRAORDINARY')
          AND is_deleted = FALSE;
    ELSE
        SELECT ROUND(AVG(final_grade), 2)
        INTO v_average
        FROM kardex
        WHERE student_id = p_student_id 
          AND academic_semester_id = p_semester_id
          AND status IN ('APPROVED', 'EXTRAORDINARY')
          AND is_deleted = FALSE;
    END IF;
    
    RETURN COALESCE(v_average, 0);
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 7. PROCEDURE: Generate automatic report card
-- =====================================================

CREATE OR REPLACE FUNCTION sp_generate_report_card(
    p_student_id UUID,
    p_academic_semester_id UUID,
    p_report_card_type VARCHAR DEFAULT 'ORDINARY'
)
RETURNS UUID AS $$
DECLARE
    v_report_card_id UUID;
    v_average NUMERIC(5,2);
    v_credits_approved INTEGER := 0;
    v_subjects_approved INTEGER := 0;
    v_total_subjects INTEGER := 0;
    v_generation_id UUID;
    v_year INTEGER;
BEGIN
    SELECT generation_id INTO v_generation_id FROM student WHERE id = p_student_id;
    SELECT EXTRACT(YEAR FROM issue_date)::INTEGER INTO v_year FROM academic_semester WHERE id = p_academic_semester_id;
    
    v_average := fn_calculate_kardex_average(p_student_id, p_academic_semester_id);
    
    SELECT COUNT(*), 
           COUNT(CASE WHEN status IN ('APPROVED', 'EXTRAORDINARY') THEN 1 END),
           COALESCE(SUM(CASE WHEN status IN ('APPROVED', 'EXTRAORDINARY') THEN c.credits ELSE 0 END), 0)
    INTO v_total_subjects, v_subjects_approved, v_credits_approved
    FROM kardex k
    JOIN course c ON k.course_id = c.id
    WHERE k.student_id = p_student_id
      AND k.academic_semester_id = p_academic_semester_id
      AND k.is_deleted = FALSE;
    
    INSERT INTO report_card (id, student_id, academic_semester_id, generation_id, report_card_type, overall_average, average_letter, total_subjects, total_subjects_approved, total_credits_enrolled, total_credits_approved, issue_date, folio, status, created_at)
    VALUES (
        uuid_generate_v4(), 
        p_student_id, 
        p_academic_semester_id, 
        v_generation_id, 
        p_report_card_type, 
        v_average, 
        fn_grade_to_letter(v_average), 
        v_total_subjects, 
        v_subjects_approved,
        (SELECT SUM(credits) FROM kardex k2 JOIN course c2 ON k2.course_id = c2.id WHERE k2.student_id = p_student_id AND k2.academic_semester_id = p_academic_semester_id), 
        v_credits_approved, 
        CURRENT_DATE, 
        fn_generate_report_card_folio(v_year), 
        'ISSUED', 
        now()
    )
    RETURNING id INTO v_report_card_id;
    
    INSERT INTO report_card_detail (id, report_card_id, kardex_id, course_id, subject_name, subject_code, credits, grade, grade_letter, subject_status)
    SELECT uuid_generate_v4(), v_report_card_id, k.id, c.id, c.name, c.course_code, c.credits, k.final_grade, fn_grade_to_letter(k.final_grade), k.status
    FROM kardex k
    JOIN course c ON k.course_id = c.id
    WHERE k.student_id = p_student_id
      AND k.academic_semester_id = p_academic_semester_id
      AND k.is_deleted = FALSE;
    
    RETURN v_report_card_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 8. PROCEDURE: Enroll in course (with kardex)
-- =====================================================
-- 8. PROCEDURE: Enroll in course (with kardex)
-- El profesor se obtiene del group_id -> academic_group
-- =====================================================

CREATE OR REPLACE FUNCTION sp_enroll_in_course(
    p_student_id UUID,
    p_course_id UUID,
    p_period_id UUID,
    p_group_id UUID,
    p_semester_id UUID
)
RETURNS UUID AS $$
DECLARE
    v_enrollment_id UUID;
    v_kardex_id UUID;
BEGIN
    v_enrollment_id := sp_enroll_student(p_student_id, p_course_id, p_period_id, p_group_id);
    
    INSERT INTO kardex (id, student_id, course_id, academic_semester_id, enrollment_id, status, attempt_number, enrollment_date, created_at)
    VALUES (uuid_generate_v4(), p_student_id, p_course_id, p_semester_id, v_enrollment_id, 'ENROLLED', 1, CURRENT_DATE, now())
    RETURNING id INTO v_kardex_id;
    
    RETURN v_enrollment_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 9. PROCEDURE: Close academic semester
-- =====================================================

CREATE OR REPLACE FUNCTION sp_close_academic_semester(
    p_semester_id UUID,
    p_apply_averages BOOLEAN DEFAULT TRUE
)
RETURNS VOID AS $$
DECLARE
    v_enrollment RECORD;
    v_average NUMERIC(5,2);
BEGIN
    UPDATE academic_semester SET status = 'CLOSED', is_current = FALSE, updated_at = now() WHERE id = p_semester_id;
    
    IF p_apply_averages THEN
        FOR v_enrollment IN
            SELECT e.id, e.student_id, e.course_id
            FROM enrollment e
            WHERE e.is_deleted = FALSE
        LOOP
            SELECT ROUND(SUM(g.score * et.weight / 100), 2)
            INTO v_average
            FROM grade g
            JOIN evaluation_type et ON g.evaluation_type_id = et.id
            WHERE g.enrollment_id = v_enrollment.id;
            
            UPDATE kardex
            SET final_grade = v_average,
                letter_grade = fn_grade_to_letter(v_average),
                status = CASE WHEN v_average >= 60 THEN 'APPROVED' ELSE 'FAILED' END,
                approval_date = CURRENT_DATE,
                updated_at = now()
            WHERE student_id = v_enrollment.student_id
              AND course_id = v_enrollment.course_id
              AND academic_semester_id = p_semester_id;
        END LOOP;
    END IF;
    
    RAISE NOTICE 'Semestre académico cerrado exitosamente';
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 10. CONSTRAINT: Only one current semester at a time
-- =====================================================

CREATE OR REPLACE FUNCTION fn_only_one_current_semester()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_current = TRUE THEN
        UPDATE academic_semester SET is_current = FALSE WHERE id != NEW.id AND is_current = TRUE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_only_one_current_semester
BEFORE INSERT OR UPDATE ON academic_semester
FOR EACH ROW
EXECUTE FUNCTION fn_only_one_current_semester();

-- =====================================================
-- 11. GENERIC FUNCTION: Soft Delete
-- =====================================================

CREATE OR REPLACE FUNCTION fn_soft_delete()
RETURNS TRIGGER AS $$
BEGIN
    NEW.is_deleted = TRUE;
    NEW.is_active = FALSE;
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 12. AUDIT: Log accesses
-- =====================================================

CREATE OR REPLACE FUNCTION sp_log_access(
    p_user_id UUID,
    p_action VARCHAR,
    p_module VARCHAR,
    p_ip VARCHAR,
    p_success BOOLEAN,
    p_metadata JSONB
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO access_audit (id, user_id, action, module, ip_address, success, metadata, created_at)
    VALUES (uuid_generate_v4(), p_user_id, p_action, p_module, p_ip, p_success, p_metadata, now());
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 12.1 GROUPS: Academic group management
-- =====================================================

-- Trigger to update academic_group timestamp
CREATE OR REPLACE FUNCTION fn_update_academic_group()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_academic_group
BEFORE UPDATE ON academic_group
FOR EACH ROW EXECUTE FUNCTION fn_update_academic_group();

-- Function: Assign teacher to group
-- El profesor se asigna al grupo, y las inscripciones obtienen el profesor a través del grupo
CREATE OR REPLACE FUNCTION sp_assign_teacher_to_group(
    p_group_id UUID,
    p_teacher_id UUID
)
RETURNS VOID AS $$
BEGIN
    UPDATE academic_group 
    SET teacher_id = p_teacher_id, updated_at = now()
    WHERE id = p_group_id;
END;
$$ LANGUAGE plpgsql;

-- Function: Get students in a group (for teacher)
CREATE OR REPLACE FUNCTION fn_get_group_students(p_teacher_id UUID)
RETURNS TABLE (
    student_id UUID,
    enrollment_number VARCHAR,
    full_name VARCHAR,
    course_name VARCHAR,
    group_name VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id AS student_id,
        s.enrollment_number,
        s.first_name || ' ' || s.last_name AS full_name,
        c.name AS course_name,
        ag.name AS group_name
    FROM enrollment e
    JOIN student s ON e.student_id = s.id
    JOIN course c ON e.course_id = c.id
    JOIN academic_group ag ON e.group_id = ag.id
    WHERE ag.teacher_id = p_teacher_id
      AND e.is_deleted = FALSE
      AND s.is_deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

-- Function: Validate teacher can grade student
CREATE OR REPLACE FUNCTION fn_can_teacher_grade(
    p_teacher_id UUID,
    p_enrollment_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_can_grade BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 
        FROM enrollment e
        JOIN academic_group ag ON e.group_id = ag.id
        WHERE e.id = p_enrollment_id
          AND ag.teacher_id = p_teacher_id
    ) INTO v_can_grade;
    
    RETURN v_can_grade;
END;
$$ LANGUAGE plpgsql;

-- Function: Generate ONLINE report card (student view)
CREATE OR REPLACE FUNCTION sp_generate_online_report_card(
    p_student_id UUID,
    p_academic_semester_id UUID
)
RETURNS UUID AS $$
DECLARE
    v_report_card_id UUID;
BEGIN
    v_report_card_id := sp_generate_report_card(
        p_student_id, 
        p_academic_semester_id, 
        'ORDINARY'
    );
    
    UPDATE report_card 
    SET generation_mode = 'ONLINE', status = 'ISSUED'
    WHERE id = v_report_card_id;
    
    RETURN v_report_card_id;
END;
$$ LANGUAGE plpgsql;

-- Function: Generate OFFICIAL report card (control escolar - with signature)
CREATE OR REPLACE FUNCTION sp_generate_official_report_card(
    p_student_id UUID,
    p_academic_semester_id UUID,
    p_report_card_type VARCHAR DEFAULT 'ORDINARY',
    p_signed_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_report_card_id UUID;
BEGIN
    v_report_card_id := sp_generate_report_card(
        p_student_id, 
        p_academic_semester_id, 
        p_report_card_type
    );
    
    UPDATE report_card 
    SET generation_mode = 'OFFICIAL', 
        status = 'ISSUED',
        is_signed = TRUE,
        signed_by = p_signed_by,
        signed_at = now()
    WHERE id = v_report_card_id;
    
    RETURN v_report_card_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 13. VIEWS: ACADEMIC REPORTS
-- =====================================================

-- View: Official student kardex
CREATE OR REPLACE VIEW v_kardex_oficial AS
SELECT
    s.enrollment_number AS enrollment_number,
    s.first_name || ' ' || s.last_name AS full_name,
    c.course_code AS course_code,
    c.name AS course_name,
    c.credits AS credits,
    ac.name AS academic_semester,
    ac.year AS year,
    k.final_grade AS final_grade,
    k.letter_grade AS letter_grade,
    k.status AS status,
    k.attempt_number AS attempt_number,
    k.enrollment_date AS enrollment_date,
    k.approval_date AS approval_date,
    k.official_folio AS official_folio,
    k.is_officialized AS is_officialized,
    k.officialization_date AS officialization_date,
    t.first_name || ' ' || t.last_name AS teacher_name
FROM kardex k
JOIN student s ON k.student_id = s.id
JOIN course c ON k.course_id = c.id
JOIN academic_semester ac ON k.academic_semester_id = ac.id
LEFT JOIN enrollment e ON k.enrollment_id = e.id
LEFT JOIN academic_group ag ON e.group_id = ag.id
LEFT JOIN teacher t ON ag.teacher_id = t.id
WHERE k.is_deleted = FALSE
ORDER BY s.enrollment_number, ac.year, ac.period;

-- View: Academic summary by student
CREATE OR REPLACE VIEW v_resumen_academico AS
SELECT
    s.id AS student_id,
    s.enrollment_number AS enrollment_number,
    s.first_name || ' ' || s.last_name AS full_name,
    g.name AS generation,
    COUNT(k.id) AS total_subjects_enrolled,
    COUNT(CASE WHEN k.status IN ('APPROVED', 'EXTRAORDINARY') THEN 1 END) AS total_approved,
    COUNT(CASE WHEN k.status = 'FAILED' THEN 1 END) AS total_failed,
    COALESCE(SUM(CASE WHEN k.status IN ('APPROVED', 'EXTRAORDINARY') THEN c.credits ELSE 0 END), 0) AS credits_approved,
    COALESCE(SUM(c.credits), 0) AS credits_enrolled,
    ROUND(AVG(CASE WHEN k.status IN ('APPROVED', 'EXTRAORDINARY') THEN k.final_grade END), 2) AS overall_average,
    fn_grade_to_letter(ROUND(AVG(CASE WHEN k.status IN ('APPROVED', 'EXTRAORDINARY') THEN k.final_grade END), 2)) AS average_letter
FROM student s
LEFT JOIN kardex k ON s.id = k.student_id AND k.is_deleted = FALSE
LEFT JOIN course c ON k.course_id = c.id
LEFT JOIN generation g ON s.generation_id = g.id
WHERE s.is_deleted = FALSE
GROUP BY s.id, s.enrollment_number, s.first_name, s.last_name, g.name;

-- View: Report cards issued by period
CREATE OR REPLACE VIEW v_boletas_periodo AS
SELECT
    rc.id AS report_card_id,
    s.enrollment_number AS enrollment_number,
    s.first_name || ' ' || s.last_name AS student_name,
    ac.name AS academic_semester,
    rc.report_card_type AS type,
    rc.overall_average AS average,
    rc.average_letter AS average_letter,
    rc.total_subjects AS total_subjects,
    rc.total_subjects_approved AS subjects_approved,
    rc.total_credits_approved AS credits_approved,
    rc.issue_date AS issue_date,
    rc.status AS status,
    rc.folio AS folio
FROM report_card rc
JOIN student s ON rc.student_id = s.id
JOIN academic_semester ac ON rc.academic_semester_id = ac.id
WHERE rc.is_deleted = FALSE
ORDER BY ac.year DESC, ac.period DESC, s.last_name;

-- View: Attendance summary
CREATE OR REPLACE VIEW v_asistencia_concentrado AS
SELECT
    s.enrollment_number AS enrollment_number,
    s.first_name || ' ' || s.last_name AS student_name,
    c.course_code AS course_code,
    c.name AS course_name,
    ac.name AS semester,
    ap.total_classes AS total_classes,
    ap.total_present AS present,
    ap.total_absent AS absent,
    ap.attendance_percentage AS percentage,
    CASE 
        WHEN ap.attendance_percentage >= 80 THEN 'SATISFACTORY'
        WHEN ap.attendance_percentage >= 60 THEN 'AT_RISK'
        ELSE 'INSUFFICIENT'
    END AS attendance_status
FROM attendance_period ap
JOIN enrollment e ON ap.enrollment_id = e.id
JOIN student s ON e.student_id = s.id
JOIN course c ON e.course_id = c.id
JOIN academic_semester ac ON ap.academic_semester_id = ac.id
WHERE e.is_deleted = FALSE
ORDER BY ac.year DESC, s.last_name;

-- View: Extraordinary exams by student
CREATE OR REPLACE VIEW v_extraordinarios_estudiante AS
SELECT
    s.enrollment_number AS enrollment_number,
    s.first_name || ' ' || s.last_name AS student_name,
    c.course_code AS course_code,
    c.name AS course_name,
    ee.attempt_number AS attempt_number,
    ee.scheduled_date AS scheduled_date,
    ee.previous_grade AS previous_grade,
    ee.grade AS grade,
    ee.status AS status,
    ee.payment_folio AS payment_folio
FROM extraordinary_exam ee
JOIN student s ON ee.student_id = s.id
JOIN course c ON ee.course_id = c.id
WHERE ee.is_deleted = FALSE
ORDER BY s.enrollment_number, ee.attempt_number;

-- View: Student transcript (compatibility)
CREATE OR REPLACE VIEW v_student_transcript AS
SELECT
    s.id AS student_id,
    s.enrollment_number AS enrollment_number,
    s.first_name || ' ' || s.last_name AS full_name,
    c.course_code AS course_code,
    c.name AS course_name,
    ap.name AS academic_period,
    c.credits AS credits,
    ROUND(SUM((g.score * et.weight)/100),2) AS final_grade,
    e.status AS status
FROM student s
JOIN enrollment e ON s.id = e.student_id
JOIN course c ON e.course_id = c.id
JOIN academic_period ap ON e.academic_period_id = ap.id
LEFT JOIN grade g ON e.id = g.enrollment_id
LEFT JOIN evaluation_type et ON g.evaluation_type_id = et.id
WHERE s.is_deleted = FALSE AND e.is_deleted = FALSE
GROUP BY s.id, s.enrollment_number, s.first_name, s.last_name, c.course_code, c.name, ap.name, c.credits, e.status;

-- View: Student GPA
CREATE OR REPLACE VIEW v_student_gpa AS
SELECT student_id, full_name, ROUND(AVG(final_grade),2) AS gpa
FROM v_student_transcript
WHERE final_grade IS NOT NULL
GROUP BY student_id, full_name;

-- View: Course approval rate
CREATE OR REPLACE VIEW v_course_approval_rate AS
SELECT
    c.id AS course_id,
    c.name AS course_name,
    COUNT(e.id) AS total_students,
    COUNT(CASE WHEN e.status = 'APPROVED' THEN 1 END) AS approved_students,
    ROUND((COUNT(CASE WHEN e.status = 'APPROVED' THEN 1 END)::NUMERIC / NULLIF(COUNT(e.id),0)) * 100,2) AS approval_percentage
FROM course c
LEFT JOIN enrollment e ON c.id = e.course_id
WHERE c.is_deleted = FALSE
GROUP BY c.id, c.name;

-- View: Teacher performance
-- El profesor se relaciona a través del grupo académico
CREATE OR REPLACE VIEW v_teacher_performance AS
SELECT
    t.id AS teacher_id,
    t.employee_number AS employee_number,
    t.first_name || ' ' || t.last_name AS teacher_name,
    COUNT(DISTINCT ag.course_id) AS courses_taught,
    COUNT(DISTINCT e.id) AS total_enrollments
FROM teacher t
LEFT JOIN academic_group ag ON t.id = ag.teacher_id AND ag.is_deleted = FALSE
LEFT JOIN enrollment e ON ag.id = e.group_id AND e.is_deleted = FALSE
WHERE t.is_deleted = FALSE
GROUP BY t.id, t.employee_number, t.first_name, t.last_name;

-- =====================================================
-- 14. PERFORMANCE INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_enrollment_student ON enrollment(student_id);
CREATE INDEX IF NOT EXISTS idx_enrollment_course ON enrollment(course_id);
CREATE INDEX IF NOT EXISTS idx_enrollment_period ON enrollment(academic_period_id);
CREATE INDEX IF NOT EXISTS idx_grade_enrollment ON grade(enrollment_id);
CREATE INDEX IF NOT EXISTS idx_evaluation_course ON evaluation_type(course_id);
CREATE INDEX IF NOT EXISTS idx_access_audit_user ON access_audit(user_id);
CREATE INDEX IF NOT EXISTS idx_access_audit_date ON access_audit(created_at);
CREATE INDEX IF NOT EXISTS idx_kardex_student ON kardex(student_id);
CREATE INDEX IF NOT EXISTS idx_kardex_course ON kardex(course_id);
CREATE INDEX IF NOT EXISTS idx_kardex_semester ON kardex(academic_semester_id);
CREATE INDEX IF NOT EXISTS idx_attendance_enrollment ON attendance(enrollment_id);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance(attendance_date);
CREATE INDEX IF NOT EXISTS idx_report_card_student ON report_card(student_id);
CREATE INDEX IF NOT EXISTS idx_report_card_semester ON report_card(academic_semester_id);
CREATE INDEX IF NOT EXISTS idx_certificate_student ON certificate(student_id);
CREATE INDEX IF NOT EXISTS idx_guardian_student ON guardian(student_id);
