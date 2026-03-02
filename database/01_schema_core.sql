-- =====================================================
-- DATABASE CREATION
-- =====================================================

CREATE DATABASE academic_system;

-- Connect to academic_system before running below.

-- =====================================================
-- EXTENSIONS
-- =====================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. SECURITY MODULE (RBAC + AUTH)
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


CREATE TABLE user_role (
    user_id UUID REFERENCES app_user(id) ON DELETE CASCADE,
    role_id UUID REFERENCES role(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);


CREATE TABLE role_permission (
    role_id UUID REFERENCES role(id) ON DELETE CASCADE,
    permission_id UUID REFERENCES permission(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);


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


CREATE TABLE password_recovery (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES app_user(id) ON DELETE CASCADE,
    recovery_token VARCHAR(255) NOT NULL UNIQUE,
    is_used BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- 2. ACADEMIC MODULE
-- =====================================================

CREATE TABLE student (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE REFERENCES app_user(id) ON DELETE SET NULL,
    enrollment_number VARCHAR(20) NOT NULL UNIQUE,
    national_id VARCHAR(18) UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    institutional_email VARCHAR(150),
    secondary_email VARCHAR(150),
    phone VARCHAR(20),
    secondary_phone VARCHAR(20),
    birth_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ
);

CREATE INDEX idx_student_enrollment ON student(enrollment_number);


CREATE TABLE teacher (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE REFERENCES app_user(id) ON DELETE SET NULL,
    employee_number VARCHAR(20) UNIQUE,
    national_id VARCHAR(18) UNIQUE,
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


CREATE TABLE study_plan (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    version VARCHAR(20),
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ
);


CREATE TABLE course (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    study_plan_id UUID REFERENCES study_plan(id) ON DELETE SET NULL,
    course_code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    credits INTEGER NOT NULL CHECK (credits > 0),
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ
);

CREATE INDEX idx_course_study_plan ON course(study_plan_id);


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


CREATE TABLE enrollment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES student(id) ON DELETE RESTRICT,
    course_id UUID NOT NULL REFERENCES course(id) ON DELETE RESTRICT,
    academic_period_id UUID NOT NULL REFERENCES academic_period(id) ON DELETE RESTRICT,
    teacher_id UUID NOT NULL REFERENCES teacher(id) ON DELETE RESTRICT,
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
CREATE INDEX idx_enrollment_teacher ON enrollment(teacher_id);
CREATE INDEX idx_enrollment_period ON enrollment(academic_period_id);

-- =====================================================
-- 3. EVALUATION MODULE
-- =====================================================

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
-- 4. PUBLIC WEB PORTAL
-- =====================================================

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

-- =====================================================
-- 5. LOGGING & AUDIT
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