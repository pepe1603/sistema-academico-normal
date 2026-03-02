-- =====================================================
-- 1. GENERIC UPDATED_AT TRIGGER FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to tables with updated_at

CREATE TRIGGER trg_update_app_user
BEFORE UPDATE ON app_user
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_update_role
BEFORE UPDATE ON role
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_update_student
BEFORE UPDATE ON student
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_update_teacher
BEFORE UPDATE ON teacher
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_update_course
BEFORE UPDATE ON course
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_update_enrollment
BEFORE UPDATE ON enrollment
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();


-- =====================================================
-- 2. VALIDATE EVALUATION WEIGHT PER COURSE
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
        'Total evaluation weight for this course exceeds 100%% (Current: %)', 
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
-- 3. SECURE ENROLLMENT PROCEDURE
-- =====================================================

CREATE OR REPLACE FUNCTION sp_enroll_student(
    p_student_id UUID,
    p_course_id UUID,
    p_period_id UUID,
    p_teacher_id UUID
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
        RAISE EXCEPTION 
        'Student is already enrolled in this course for this academic period';
    END IF;

    INSERT INTO enrollment (
        id,
        student_id,
        course_id,
        academic_period_id,
        teacher_id
    )
    VALUES (
        uuid_generate_v4(),
        p_student_id,
        p_course_id,
        p_period_id,
        p_teacher_id
    )
    RETURNING id INTO v_enrollment_id;

    RETURN v_enrollment_id;
END;
$$ LANGUAGE plpgsql;


-- =====================================================
-- 4. KARDEX VIEW (ACADEMIC TRANSCRIPT)
-- =====================================================

CREATE OR REPLACE VIEW v_student_transcript AS
SELECT
    s.id AS student_id,
    s.enrollment_number,
    s.first_name || ' ' || s.last_name AS full_name,
    c.course_code,
    c.name AS course_name,
    ap.name AS academic_period,
    c.credits,
    ROUND(SUM((g.score * et.weight)/100),2) AS final_grade,
    e.status
FROM student s
JOIN enrollment e ON s.id = e.student_id
JOIN course c ON e.course_id = c.id
JOIN academic_period ap ON e.academic_period_id = ap.id
LEFT JOIN grade g ON e.id = g.enrollment_id
LEFT JOIN evaluation_type et ON g.evaluation_type_id = et.id
GROUP BY
    s.id,
    s.enrollment_number,
    s.first_name,
    s.last_name,
    c.course_code,
    c.name,
    ap.name,
    c.credits,
    e.status;


-- =====================================================
-- 5. STUDENT GPA SUMMARY VIEW
-- =====================================================

CREATE OR REPLACE VIEW v_student_gpa AS
SELECT
    student_id,
    full_name,
    ROUND(AVG(final_grade),2) AS gpa
FROM v_student_transcript
WHERE final_grade IS NOT NULL
GROUP BY student_id, full_name;


-- =====================================================
-- 6. COURSE APPROVAL RATE DASHBOARD VIEW
-- =====================================================

CREATE OR REPLACE VIEW v_course_approval_rate AS
SELECT
    c.id AS course_id,
    c.name AS course_name,
    COUNT(e.id) AS total_students,
    COUNT(CASE WHEN e.status = 'APPROVED' THEN 1 END) AS approved_students,
    ROUND(
        (COUNT(CASE WHEN e.status = 'APPROVED' THEN 1 END)::NUMERIC 
        / NULLIF(COUNT(e.id),0)) * 100,2
    ) AS approval_percentage
FROM course c
LEFT JOIN enrollment e ON c.id = e.course_id
GROUP BY c.id, c.name;


-- =====================================================
-- 7. TEACHER PERFORMANCE DASHBOARD VIEW
-- =====================================================

CREATE OR REPLACE VIEW v_teacher_performance AS
SELECT
    t.id AS teacher_id,
    t.first_name || ' ' || t.last_name AS teacher_name,
    COUNT(DISTINCT e.course_id) AS courses_taught,
    COUNT(e.id) AS total_enrollments
FROM teacher t
LEFT JOIN enrollment e ON t.id = e.teacher_id
GROUP BY t.id, teacher_name;


-- =====================================================
-- 8. GENERIC SOFT DELETE FUNCTION
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
-- 9. ACCESS AUDIT HELPER FUNCTION
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
    INSERT INTO access_audit (
        user_id,
        action,
        module,
        ip_address,
        success,
        metadata
    )
    VALUES (
        p_user_id,
        p_action,
        p_module,
        p_ip,
        p_success,
        p_metadata
    );
END;
$$ LANGUAGE plpgsql;