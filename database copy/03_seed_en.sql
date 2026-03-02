-- =====================================================
-- 1. BASE ROLES
-- =====================================================

INSERT INTO role (name, description)
VALUES
('ADMIN', 'Full system access'),
('TEACHER', 'Academic management access'),
('STUDENT', 'Academic consultation access');


-- =====================================================
-- 2. BASE PERMISSIONS
-- =====================================================

INSERT INTO permission (code, description, module) VALUES
-- User Management
('USER_CREATE', 'Create users', 'SECURITY'),
('USER_UPDATE', 'Update users', 'SECURITY'),
('USER_DELETE', 'Soft delete users', 'SECURITY'),
('USER_VIEW', 'View users', 'SECURITY'),

-- Academic
('COURSE_CREATE', 'Create courses', 'ACADEMIC'),
('COURSE_UPDATE', 'Update courses', 'ACADEMIC'),
('COURSE_VIEW', 'View courses', 'ACADEMIC'),
('ENROLL_STUDENT', 'Enroll student into course', 'ACADEMIC'),
('GRADE_ASSIGN', 'Assign grades', 'ACADEMIC'),
('GRADE_VIEW', 'View grades', 'ACADEMIC'),

-- Dashboard
('DASHBOARD_VIEW', 'View dashboard statistics', 'DASHBOARD'),

-- Portal
('NEWS_MANAGE', 'Manage news content', 'PORTAL'),
('EVENT_MANAGE', 'Manage events', 'PORTAL');


-- =====================================================
-- 3. ROLE-PERMISSION ASSIGNMENT
-- =====================================================

-- ADMIN gets everything
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id
FROM role r, permission p
WHERE r.name = 'ADMIN';

-- TEACHER permissions
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id
FROM role r
JOIN permission p ON p.code IN (
    'COURSE_VIEW',
    'GRADE_ASSIGN',
    'GRADE_VIEW',
    'DASHBOARD_VIEW'
)
WHERE r.name = 'TEACHER';

-- STUDENT permissions
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id
FROM role r
JOIN permission p ON p.code IN (
    'COURSE_VIEW',
    'GRADE_VIEW'
)
WHERE r.name = 'STUDENT';


-- =====================================================
-- 4. INSTITUTION DATA
-- =====================================================

INSERT INTO institution (
    name,
    address,
    phone,
    email,
    website,
    mission,
    vision,
    history,
    values,
    logo_url
)
VALUES (
    'Demo University',
    '123 Academic Avenue',
    '+52 000 000 0000',
    'info@demouniversity.edu',
    'https://www.demouniversity.edu',
    'To provide quality education with innovation and integrity.',
    'To be a regional leader in academic excellence.',
    'Founded with the purpose of transforming education through technology.',
    'Integrity, Excellence, Responsibility, Innovation.',
    'https://www.demouniversity.edu/logo.png'
);


-- =====================================================
-- 5. STUDY PLAN
-- =====================================================

INSERT INTO study_plan (name, version, description)
VALUES ('Computer Science', '2025', 'Bachelor in Computer Science');


-- =====================================================
-- 6. ACADEMIC PERIOD
-- =====================================================

INSERT INTO academic_period (name, start_date, end_date)
VALUES ('2025-1', '2025-01-15', '2025-06-30');


-- =====================================================
-- 7. COURSES
-- =====================================================

INSERT INTO course (study_plan_id, course_code, name, credits, description)
SELECT sp.id, 'CS101', 'Introduction to Programming', 8, 'Programming fundamentals'
FROM study_plan sp
WHERE sp.name = 'Computer Science';

INSERT INTO course (study_plan_id, course_code, name, credits, description)
SELECT sp.id, 'CS102', 'Database Systems', 8, 'Relational database design and SQL'
FROM study_plan sp
WHERE sp.name = 'Computer Science';


-- =====================================================
-- 8. EVALUATION TYPES (P1, P2, P3, FINAL, EXTRA)
-- =====================================================

INSERT INTO evaluation_type (course_id, code, name, weight)
SELECT c.id, 'P1', 'Partial Exam 1', 20
FROM course c WHERE c.course_code = 'CS101';

INSERT INTO evaluation_type (course_id, code, name, weight)
SELECT c.id, 'P2', 'Partial Exam 2', 20
FROM course c WHERE c.course_code = 'CS101';

INSERT INTO evaluation_type (course_id, code, name, weight)
SELECT c.id, 'P3', 'Partial Exam 3', 20
FROM course c WHERE c.course_code = 'CS101';

INSERT INTO evaluation_type (course_id, code, name, weight)
SELECT c.id, 'FINAL', 'Final Exam', 40
FROM course c WHERE c.course_code = 'CS101';

-- Extra exam optional (weight 0 by default)
INSERT INTO evaluation_type (course_id, code, name, weight)
SELECT c.id, 'EXTRA', 'Extraordinary Exam', 0
FROM course c WHERE c.course_code = 'CS101';


-- =====================================================
-- 9. ADMIN USER (Initial Access)
-- Password example hashed with BCrypt
-- =====================================================

INSERT INTO app_user (
    username,
    email,
    password_hash,
    is_active
)
VALUES (
    'admin',
    'admin@demouniversity.edu',
    '$2a$10$7EqJtq98hPqEX7fNZaFWoOQW6Z9uGq5Q8K4JpN96CBrum1BgFi7qS',
    TRUE
);

-- Assign ADMIN role to admin user
INSERT INTO user_role (user_id, role_id)
SELECT u.id, r.id
FROM app_user u, role r
WHERE u.username = 'admin'
AND r.name = 'ADMIN';


-- =====================================================
-- 10. SAMPLE NEWS
-- =====================================================

INSERT INTO news (title, content)
VALUES (
    'Welcome to the 2025 Academic Period',
    'The new academic semester has officially started.'
);

-- =====================================================
-- 11. SAMPLE EVENT
-- =====================================================

INSERT INTO event (title, description, event_date, location)
VALUES (
    'Technology Conference 2025',
    'Annual academic technology conference.',
    '2025-03-15',
    'Main Auditorium'
);