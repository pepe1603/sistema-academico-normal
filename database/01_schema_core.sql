-- =====================================================
-- DATABASE CREATION
-- =====================================================

CREATE DATABASE academic_system;

-- Connect to academic_system before running the rest.

-- =====================================================
-- EXTENSIONS
-- =====================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- ORDER OF CREATION: 
-- 1. Base tables (no dependencies)
-- 2. Tables with dependencies
-- 3. Relationship tables
-- =====================================================

-- =====================================================
-- 1. SECURITY MODULE - BASE TABLES
-- =====================================================

CREATE TABLE app_user (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    failed_attempts INTEGER DEFAULT 0 CHECK (failed_attempts >= 0),
    is_locked BOOLEAN DEFAULT FALSE,
    last_login TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ,
    created_by UUID,
    updated_by UUID
);

CREATE INDEX idx_app_user_email ON app_user(email);

CREATE TABLE role (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ
);

CREATE TABLE permission (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    module VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- User sessions (depends on app_user)
CREATE TABLE user_session (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES app_user(id) ON DELETE CASCADE,
    jwt_token TEXT NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    started_at TIMESTAMPTZ DEFAULT now(),
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_user_session_user ON user_session(user_id);

-- Password recovery (depends on app_user)
CREATE TABLE password_recovery (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES app_user(id) ON DELETE CASCADE,
    recovery_token VARCHAR(255) NOT NULL UNIQUE,
    is_used BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- 2. ACADEMIC MODULE - BASE TABLES
-- =====================================================

-- Generation (no dependencies)
CREATE TABLE generation (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    entry_year INTEGER NOT NULL,
    graduation_year INTEGER,
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'GRADUATED', 'ARCHIVED')),
    start_date DATE NOT NULL,
    end_date DATE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ
);

CREATE INDEX idx_generation_entry_year ON generation(entry_year);

-- Study Plan (no dependencies)
CREATE TABLE study_plan (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    version VARCHAR(20),
    description TEXT,
    title_degree VARCHAR(150),
    total_credits INTEGER,
    duration_semesters INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ
);

-- Semester (depends on study_plan)
CREATE TABLE semester (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    study_plan_id UUID REFERENCES study_plan(id) ON DELETE CASCADE,
    semester_number INTEGER NOT NULL CHECK (semester_number BETWEEN 1 AND 10),
    name VARCHAR(50) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_semester_study_plan ON semester(study_plan_id);

-- Academic Semester (no dependencies)
CREATE TABLE academic_semester (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) NOT NULL,
    year INTEGER NOT NULL CHECK (year >= 2000),
    period INTEGER NOT NULL CHECK (period IN (1, 2)),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    classes_start_date DATE NOT NULL,
    classes_end_date DATE NOT NULL,
    enrollment_deadline DATE,
    drop_deadline DATE,
    status VARCHAR(20) DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'OPEN', 'CLOSED', 'ARCHIVED')),
    is_current BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ,
    CONSTRAINT chk_semester_dates CHECK (end_date > start_date AND classes_end_date >= classes_start_date)
);

CREATE INDEX idx_academic_semester_year ON academic_semester(year);
CREATE INDEX idx_academic_semester_status ON academic_semester(status);

-- Academic Period (legacy - no dependencies)
CREATE TABLE academic_period (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(20) NOT NULL UNIQUE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ,
    CHECK (end_date > start_date)
);

-- Teacher (no dependencies) - debe crearse antes de academic_group
-- Identification: RFC para trámites fiscales, CURP para identificación oficial mexicana
CREATE TABLE teacher (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE REFERENCES app_user(id) ON DELETE SET NULL,
    employee_number VARCHAR(20) UNIQUE,
    rfc VARCHAR(13) UNIQUE,
    curp VARCHAR(18) UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    institutional_email VARCHAR(150),
    secondary_email VARCHAR(150),
    phone VARCHAR(20),
    secondary_phone VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ
);

-- Course (depends on study_plan, semester) - debe crearse antes de academic_group
CREATE TABLE course (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    study_plan_id UUID REFERENCES study_plan(id) ON DELETE SET NULL,
    semester_id UUID REFERENCES semester(id) ON DELETE SET NULL,
    course_code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    credits INTEGER NOT NULL CHECK (credits > 0),
    hours_theory INTEGER DEFAULT 0,
    hours_practice INTEGER DEFAULT 0,
    description TEXT,
    is_mandatory BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ
);

CREATE INDEX idx_course_study_plan ON course(study_plan_id);
CREATE INDEX idx_course_semester ON course(semester_id);

-- Academic Group (Grupo - sección de un curso en un semestre)
-- Permite asignar un profesor a un grupo específico de estudiantes
CREATE TABLE academic_group (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) NOT NULL,
    academic_semester_id UUID REFERENCES academic_semester(id) ON DELETE CASCADE,
    course_id UUID REFERENCES course(id) ON DELETE CASCADE,
    teacher_id UUID REFERENCES teacher(id) ON DELETE SET NULL,
    capacity INTEGER DEFAULT 30,
    is_active BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ,
    UNIQUE (name, academic_semester_id, course_id)
);

CREATE INDEX idx_academic_group_semester ON academic_group(academic_semester_id);
CREATE INDEX idx_academic_group_course ON academic_group(course_id);
CREATE INDEX idx_academic_group_teacher ON academic_group(teacher_id);

-- Student (depends on generation, user)
-- Identification: CURP es el identificador oficial mexicano
CREATE TABLE student (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE REFERENCES app_user(id) ON DELETE SET NULL,
    enrollment_number VARCHAR(20) NOT NULL UNIQUE,
    curp VARCHAR(18) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    institutional_email VARCHAR(150),
    secondary_email VARCHAR(150),
    phone VARCHAR(20),
    secondary_phone VARCHAR(20),
    birth_date DATE,
    gender CHAR(1) CHECK (gender IN ('M', 'F', 'O')),
    enrollment_date DATE,
    graduation_date DATE,
    marital_status VARCHAR(20),
    birth_place VARCHAR(200),
    nationality VARCHAR(50) DEFAULT 'MEXICANA',
    address_street VARCHAR(200),
    address_colony VARCHAR(100),
    address_municipality VARCHAR(100),
    address_state VARCHAR(100),
    address_zip_code VARCHAR(10),
    blood_type VARCHAR(5),
    previous_school TEXT,
    photo_url TEXT,
    observations TEXT,
    has_scholarship BOOLEAN DEFAULT FALSE,
    scholarship_type VARCHAR(50),
    generation_id UUID REFERENCES generation(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ
);

CREATE INDEX idx_student_enrollment ON student(enrollment_number);
CREATE INDEX idx_student_curp ON student(curp);
CREATE INDEX idx_student_gender ON student(gender);
CREATE INDEX idx_student_enrollment_date ON student(enrollment_date);

-- Enrollment (depends on student, course, academic_period, academic_group)
-- El profesor se obtiene del group_id -> academic_group -> teacher_id
CREATE TABLE enrollment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES student(id) ON DELETE RESTRICT,
    course_id UUID NOT NULL REFERENCES course(id) ON DELETE RESTRICT,
    academic_period_id UUID NOT NULL REFERENCES academic_period(id) ON DELETE RESTRICT,
    group_id UUID REFERENCES academic_group(id) ON DELETE SET NULL,
    status VARCHAR(30) DEFAULT 'ENROLLED'
        CHECK (status IN ('ENROLLED','APPROVED','FAILED','WITHDRAWN')),
    is_active BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ,
    UNIQUE (student_id, course_id, academic_period_id)
);

CREATE INDEX idx_enrollment_student ON enrollment(student_id);
CREATE INDEX idx_enrollment_course ON enrollment(course_id);
CREATE INDEX idx_enrollment_period ON enrollment(academic_period_id);
CREATE INDEX idx_enrollment_group ON enrollment(group_id);

-- Evaluation Type (depends on course)
CREATE TABLE evaluation_type (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID REFERENCES course(id) ON DELETE CASCADE,
    code VARCHAR(20) NOT NULL,
    name VARCHAR(50),
    weight NUMERIC(5,2) CHECK (weight BETWEEN 0 AND 100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_evaluation_course ON evaluation_type(course_id);

-- Grade (depends on enrollment, evaluation_type, app_user)
CREATE TABLE grade (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enrollment_id UUID REFERENCES enrollment(id) ON DELETE CASCADE,
    evaluation_type_id UUID REFERENCES evaluation_type(id) ON DELETE CASCADE,
    score NUMERIC(5,2) CHECK (score BETWEEN 0 AND 100),
    recorded_by UUID REFERENCES app_user(id) ON DELETE SET NULL,
    recorded_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE (enrollment_id, evaluation_type_id)
);

CREATE INDEX idx_grade_enrollment ON grade(enrollment_id);

-- =====================================================
-- 3. KARDEX (depends on student, course, academic_semester, teacher, enrollment)
-- =====================================================

CREATE TABLE kardex (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES student(id) ON DELETE RESTRICT,
    course_id UUID NOT NULL REFERENCES course(id) ON DELETE RESTRICT,
    academic_semester_id UUID NOT NULL REFERENCES academic_semester(id) ON DELETE RESTRICT,
    enrollment_id UUID REFERENCES enrollment(id) ON DELETE SET NULL,
    
    final_grade NUMERIC(5,2) CHECK (final_grade BETWEEN 0 AND 100),
    letter_grade VARCHAR(2),
    status VARCHAR(20) NOT NULL DEFAULT 'ENROLLED' 
        CHECK (status IN ('ENROLLED', 'APPROVED', 'FAILED', 'EXTRAORDINARY', 'DROPPED', 'VALIDATED', 'EQUIVALENCE')),
    
    attempt_number INTEGER DEFAULT 1,
    enrollment_date DATE NOT NULL,
    approval_date DATE,
    registration_date TIMESTAMPTZ DEFAULT now(),
    
    official_folio VARCHAR(30) UNIQUE,
    kardex_folio VARCHAR(30),
    kardex_sequence INTEGER,
    
    is_officialized BOOLEAN DEFAULT FALSE,
    officialization_date TIMESTAMPTZ,
    officialized_by UUID REFERENCES app_user(id) ON DELETE SET NULL,
    
    observations TEXT,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ,
    
    UNIQUE (student_id, course_id, academic_semester_id, attempt_number)
);

CREATE INDEX idx_kardex_student ON kardex(student_id);
CREATE INDEX idx_kardex_course ON kardex(course_id);
CREATE INDEX idx_kardex_semester ON kardex(academic_semester_id);
CREATE INDEX idx_kardex_status ON kardex(status);

-- =====================================================
-- 4. REPORT CARDS (depends on student, academic_semester, generation)
-- =====================================================

CREATE TABLE report_card (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES student(id) ON DELETE RESTRICT,
    academic_semester_id UUID NOT NULL REFERENCES academic_semester(id) ON DELETE RESTRICT,
    generation_id UUID REFERENCES generation(id) ON DELETE SET NULL,
    
    report_card_type VARCHAR(30) NOT NULL DEFAULT 'ORDINARY' 
        CHECK (report_card_type IN ('ORDINARY', 'EXTRAORDINARY', 'SPECIAL', 'PARTIAL_CERTIFICATE', 'FINAL_CERTIFICATE')),
    
    -- ONLINE: boleta vista por estudiante en portal
    -- OFFICIAL: boleta oficial generada por control escolar (sellada y firmada)
    generation_mode VARCHAR(20) NOT NULL DEFAULT 'ONLINE'
        CHECK (generation_mode IN ('ONLINE', 'OFFICIAL')),
    
    overall_average NUMERIC(5,2) CHECK (overall_average BETWEEN 0 AND 100),
    average_letter VARCHAR(2),
    attendance_average NUMERIC(5,2),
    
    total_credits_enrolled INTEGER DEFAULT 0,
    total_credits_approved INTEGER DEFAULT 0,
    total_subjects INTEGER DEFAULT 0,
    total_subjects_approved INTEGER DEFAULT 0,
    
    status VARCHAR(20) DEFAULT 'ISSUED' 
        CHECK (status IN ('PENDING', 'ISSUED', 'DELIVERED', 'ARCHIVED', 'CANCELLED')),
    
    issue_date DATE NOT NULL,
    delivery_date DATE,
    origin_semester_id UUID,
    destination_semester_id UUID,
    
    folio VARCHAR(30) UNIQUE,
    series VARCHAR(20),
    
    observations TEXT,
    is_signed BOOLEAN DEFAULT FALSE,
    signed_by UUID REFERENCES app_user(id) ON DELETE SET NULL,
    signed_at TIMESTAMPTZ,
    signed_seal_url TEXT,
    
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ
);

CREATE INDEX idx_report_card_student ON report_card(student_id);
CREATE INDEX idx_report_card_semester ON report_card(academic_semester_id);
CREATE INDEX idx_report_card_folio ON report_card(folio);
CREATE INDEX idx_report_card_generation_mode ON report_card(generation_mode);

-- Report Card Detail (depends on report_card, kardex, course)
CREATE TABLE report_card_detail (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_card_id UUID NOT NULL REFERENCES report_card(id) ON DELETE CASCADE,
    kardex_id UUID REFERENCES kardex(id) ON DELETE SET NULL,
    course_id UUID NOT NULL REFERENCES course(id) ON DELETE RESTRICT,
    
    subject_name VARCHAR(150) NOT NULL,
    subject_code VARCHAR(20) NOT NULL,
    credits INTEGER NOT NULL,
    
    grade NUMERIC(5,2) CHECK (grade BETWEEN 0 AND 100),
    grade_letter VARCHAR(2),
    subject_status VARCHAR(20),
    
    attendance_percentage NUMERIC(5,2),
    total_attendances INTEGER,
    classes_attended INTEGER,
    
    observations TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_report_card_detail_report_card ON report_card_detail(report_card_id);

-- =====================================================
-- 5. ATTENDANCE (depends on enrollment)
-- =====================================================

CREATE TABLE attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enrollment_id UUID NOT NULL REFERENCES enrollment(id) ON DELETE CASCADE,
    
    attendance_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'PRESENT' 
        CHECK (status IN ('PRESENT', 'ABSENT', 'JUSTIFIED', 'LATE')),
    
    class_time VARCHAR(10),
    subject_code VARCHAR(20),
    
    observations TEXT,
    justified_by UUID REFERENCES app_user(id) ON DELETE SET NULL,
    justification_date TIMESTAMPTZ,
    
    recorded_by UUID REFERENCES app_user(id) ON DELETE SET NULL,
    recorded_at TIMESTAMPTZ DEFAULT now(),
    
    UNIQUE (enrollment_id, attendance_date)
);

CREATE INDEX idx_attendance_enrollment ON attendance(enrollment_id);
CREATE INDEX idx_attendance_date ON attendance(attendance_date);

-- Attendance Period (depends on enrollment, academic_semester)
CREATE TABLE attendance_period (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enrollment_id UUID NOT NULL REFERENCES enrollment(id) ON DELETE CASCADE,
    academic_semester_id UUID NOT NULL REFERENCES academic_semester(id) ON DELETE RESTRICT,
    
    total_classes INTEGER DEFAULT 0,
    total_present INTEGER DEFAULT 0,
    total_absent INTEGER DEFAULT 0,
    total_justified INTEGER DEFAULT 0,
    total_late INTEGER DEFAULT 0,
    
    attendance_percentage NUMERIC(5,2),
    attendance_status VARCHAR(20) DEFAULT 'IN_RANGE',
    observations TEXT,
    updated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    
    UNIQUE (enrollment_id, academic_semester_id)
);

-- =====================================================
-- 6. CONDUCT (depends on enrollment, academic_semester)
-- =====================================================

CREATE TABLE conduct (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enrollment_id UUID NOT NULL REFERENCES enrollment(id) ON DELETE RESTRICT,
    academic_semester_id UUID NOT NULL REFERENCES academic_semester(id) ON DELETE RESTRICT,
    
    grade VARCHAR(2),
    observations TEXT,
    warnings INTEGER DEFAULT 0,
    congratulations INTEGER DEFAULT 0,
    
    registration_date TIMESTAMPTZ DEFAULT now(),
    recorded_by UUID REFERENCES app_user(id) ON DELETE SET NULL,
    updated_at TIMESTAMPTZ,
    
    UNIQUE (enrollment_id, academic_semester_id)
);

-- Conduct Incident (depends on enrollment)
CREATE TABLE conduct_incident (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enrollment_id UUID NOT NULL REFERENCES enrollment(id) ON DELETE CASCADE,
    
    incident_type VARCHAR(50) NOT NULL 
        CHECK (incident_type IN ('WARNING', 'CONGRATULATION', 'CALL_ATTENTION', 'SUSPENSION', 'OTHER')),
    description TEXT NOT NULL,
    incident_date DATE NOT NULL,
    
    severity VARCHAR(20) DEFAULT 'MINOR' CHECK (severity IN ('MINOR', 'MODERATE', 'SERIOUS')),
    actions_taken TEXT,
    attention_date DATE,
    
    recorded_by UUID REFERENCES app_user(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- 7. EXTRAORDINARY EXAMS (depends on student, course, academic_semester, teacher)
-- =====================================================

CREATE TABLE extraordinary_exam (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES student(id) ON DELETE RESTRICT,
    course_id UUID NOT NULL REFERENCES course(id) ON DELETE RESTRICT,
    academic_semester_id UUID REFERENCES academic_semester(id) ON DELETE SET NULL,
    
    attempt_number INTEGER NOT NULL DEFAULT 1,
    status VARCHAR(20) DEFAULT 'SCHEDULED' 
        CHECK (status IN ('SCHEDULED', 'APPLIED', 'APPROVED', 'FAILED', 'CANCELLED', 'NO_SHOW')),
    
    scheduled_date DATE,
    application_date DATE,
    application_time VARCHAR(10),
    application_location VARCHAR(100),
    
    previous_grade NUMERIC(5,2),
    grade NUMERIC(5,2),
    grade_letter VARCHAR(2),
    
    examiner_id UUID REFERENCES teacher(id) ON DELETE SET NULL,
    observation TEXT,
    
    cost DECIMAL(10,2) DEFAULT 0,
    payment_receipt VARCHAR(100),
    payment_folio VARCHAR(50),
    
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ,
    
    UNIQUE (student_id, course_id, attempt_number)
);

CREATE INDEX idx_extraordinary_exam_student ON extraordinary_exam(student_id);
CREATE INDEX idx_extraordinary_exam_status ON extraordinary_exam(status);

-- Retake Exam (depends on student, course, academic_semester)
CREATE TABLE retake_exam (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES student(id) ON DELETE RESTRICT,
    course_id UUID NOT NULL REFERENCES course(id) ON DELETE RESTRICT,
    academic_semester_id UUID NOT NULL REFERENCES academic_semester(id) ON DELETE RESTRICT,
    
    origin_semester_id UUID REFERENCES academic_semester(id),
    previous_average NUMERIC(5,2),
    status VARCHAR(20) DEFAULT 'ENROLLED',
    
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ,
    
    UNIQUE (student_id, course_id, academic_semester_id)
);

-- =====================================================
-- 8. CERTIFICATES (depends on student, generation)
-- =====================================================

CREATE TABLE certificate (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES student(id) ON DELETE RESTRICT,
    generation_id UUID REFERENCES generation(id) ON DELETE SET NULL,
    
    certificate_type VARCHAR(50) NOT NULL 
        CHECK (certificate_type IN ('PARTIAL', 'TOTAL', 'TITLE', 'DIPLOMA', 'CONSTANCIA')),
    
    official_folio VARCHAR(50) UNIQUE,
    internal_folio VARCHAR(50),
    series VARCHAR(20),
    
    final_average NUMERIC(5,2),
    total_credits INTEGER,
    total_subjects INTEGER,
    issue_date DATE NOT NULL,
    delivery_date DATE,
    
    status VARCHAR(20) DEFAULT 'ISSUED' 
        CHECK (status IN ('REQUESTED', 'IN_PROCESS', 'ISSUED', 'DELIVERED', 'CANCELLED')),
    
    director_signer UUID REFERENCES app_user(id) ON DELETE SET NULL,
    secretary_signer UUID REFERENCES app_user(id) ON DELETE SET NULL,
    
    record_number VARCHAR(30),
    record_book VARCHAR(20),
    record_page VARCHAR(20),
    
    observations TEXT,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ
);

CREATE INDEX idx_certificate_student ON certificate(student_id);

-- =====================================================
-- 9. GUARDIANS (depends on student)
-- =====================================================

CREATE TABLE guardian (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES student(id) ON DELETE CASCADE,
    full_name VARCHAR(200) NOT NULL,
    relationship VARCHAR(50) NOT NULL CHECK (relationship IN ('FATHER', 'MOTHER', 'GUARDIAN', 'SIBLING', 'OTHER')),
    curp VARCHAR(18),
    primary_phone VARCHAR(20),
    secondary_phone VARCHAR(20),
    email VARCHAR(150),
    occupation VARCHAR(100),
    company VARCHAR(150),
    address TEXT,
    is_emergency_contact BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ
);

CREATE INDEX idx_guardian_student ON guardian(student_id);

-- =====================================================
-- 10. DOCUMENTS (depends on student)
-- =====================================================

CREATE TABLE student_document (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES student(id) ON DELETE CASCADE,
    
    document_type VARCHAR(50) NOT NULL 
        CHECK (document_type IN ('CURP', 'BIRTH_CERTIFICATE', 'PHOTO', 'HIGH_SCHOOL_CERTIFICATE', 
                                   'HIGH_SCHOOL_KARDEX', 'IDENTIFICATION', 'PROOF_OF_ADDRESS',
                                   'PAYMENT', 'OTHER')),
    
    original_name VARCHAR(200) NOT NULL,
    file_name VARCHAR(200) NOT NULL,
    file_path TEXT NOT NULL,
    file_size_bytes BIGINT,
    mime_type VARCHAR(100),
    
    document_number VARCHAR(50),
    issue_date DATE,
    expiration_date DATE,
    
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by UUID REFERENCES app_user(id) ON DELETE SET NULL,
    verification_date TIMESTAMPTZ,
    
    observations TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ
);

CREATE INDEX idx_student_document_student ON student_document(student_id);

-- =====================================================
-- 11. CONFIGURATION (no dependencies)
-- =====================================================

CREATE TABLE system_configuration (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    config_key VARCHAR(50) NOT NULL UNIQUE,
    config_value TEXT NOT NULL,
    description TEXT,
    data_type VARCHAR(20) DEFAULT 'STRING' CHECK (data_type IN ('STRING', 'NUMBER', 'BOOLEAN', 'JSON')),
    module VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ
);

-- =====================================================
-- 12. PUBLIC PORTAL
-- =====================================================

-- Institution (no dependencies)
CREATE TABLE institution (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200),
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(150),
    website VARCHAR(200),
    mission TEXT,
    vision TEXT,
    history TEXT,
    values TEXT,
    logo_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- News (no dependencies)
CREATE TABLE news (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(200),
    content TEXT,
    image_url TEXT,
    is_published BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ
);

-- Event (no dependencies)
CREATE TABLE event (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(200),
    description TEXT,
    event_date DATE,
    location VARCHAR(200),
    is_published BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ
);

-- Portal Advertisement (no dependencies)
CREATE TABLE portal_advertisement (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    image_url TEXT,
    link_url VARCHAR(500),
    position VARCHAR(20) DEFAULT 'BANNER' CHECK (position IN ('BANNER', 'SIDEBAR', 'FOOTER')),
    display_order INTEGER DEFAULT 0,
    is_published BOOLEAN DEFAULT TRUE,
    start_date DATE,
    end_date DATE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ
);

-- Portal Contact (no dependencies)
CREATE TABLE portal_contact (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(150) NOT NULL,
    phone VARCHAR(20),
    subject VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    is_responded BOOLEAN DEFAULT FALSE,
    response TEXT,
    response_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Educational Resource (depends on course)
CREATE TABLE educational_resource (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    resource_type VARCHAR(50) NOT NULL 
        CHECK (resource_type IN ('PDF', 'VIDEO', 'LINK', 'DOCUMENT', 'PRESENTATION')),
    resource_url TEXT NOT NULL,
    course_id UUID REFERENCES course(id) ON DELETE SET NULL,
    is_published BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ
);

-- =====================================================
-- 13. AUDIT (no dependencies)
-- =====================================================

CREATE TABLE access_audit (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES app_user(id) ON DELETE SET NULL,
    action VARCHAR(100),
    module VARCHAR(100),
    ip_address VARCHAR(45),
    success BOOLEAN,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_access_audit_created_at ON access_audit(created_at);

-- =====================================================
-- 14. RELATIONSHIP TABLES (must be last)
-- =====================================================

-- User-Role (depends on app_user, role)
CREATE TABLE user_role (
    user_id UUID REFERENCES app_user(id) ON DELETE CASCADE,
    role_id UUID REFERENCES role(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

-- Role-Permission (depends on role, permission)
CREATE TABLE role_permission (
    role_id UUID REFERENCES role(id) ON DELETE CASCADE,
    permission_id UUID REFERENCES permission(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);
