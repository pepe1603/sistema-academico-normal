-- =====================================================
-- SEED DATA - ACADEMIC SYSTEM
-- Compatible with PostgreSQL 14+
-- =====================================================


-- =====================================================
-- 1. BASE ROLES
-- =====================================================

INSERT INTO role (name, description)
VALUES
('ADMIN', 'Acceso total al sistema'),
('TEACHER', 'Gestión académica y calificaciones'),
('STUDENT', 'Consulta académica y calificaciones');


-- =====================================================
-- 2. BASE PERMISSIONS
-- =====================================================

INSERT INTO permission (code, description, module) VALUES

-- SECURITY
('USER_CREATE', 'Crear usuarios', 'SECURITY'),
('USER_UPDATE', 'Actualizar usuarios', 'SECURITY'),
('USER_DELETE', 'Eliminar usuarios (soft delete)', 'SECURITY'),
('USER_VIEW', 'Consultar usuarios', 'SECURITY'),

-- ACADEMIC
('COURSE_CREATE', 'Crear cursos', 'ACADEMIC'),
('COURSE_UPDATE', 'Actualizar cursos', 'ACADEMIC'),
('COURSE_VIEW', 'Consultar cursos', 'ACADEMIC'),
('ENROLL_STUDENT', 'Inscribir estudiante en curso', 'ACADEMIC'),
('GRADE_ASSIGN', 'Asignar calificaciones', 'ACADEMIC'),
('GRADE_VIEW', 'Consultar calificaciones', 'ACADEMIC'),

-- DASHBOARD
('DASHBOARD_VIEW', 'Consultar estadísticas del sistema', 'DASHBOARD'),

-- PORTAL
('NEWS_MANAGE', 'Gestionar noticias', 'PORTAL'),
('EVENT_MANAGE', 'Gestionar eventos', 'PORTAL');


-- =====================================================
-- 3. ROLE - PERMISSION ASSIGNMENTS
-- =====================================================

-- ADMIN → todos los permisos
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id
FROM role r
CROSS JOIN permission p
WHERE r.name = 'ADMIN';


-- TEACHER → permisos académicos limitados
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


-- STUDENT → permisos de consulta
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
    'Universidad Tecnológica Demo',
    'Av. Académica 123, Ciudad Universitaria',
    '+52 999 999 9999',
    'contacto@utdemo.edu.mx',
    'https://www.utdemo.edu.mx',
    'Formar profesionales íntegros con excelencia académica y visión tecnológica.',
    'Ser una institución líder en innovación y calidad educativa en la región.',
    'Fundada con el objetivo de transformar la educación superior mediante tecnología.',
    'Integridad, Excelencia, Responsabilidad, Innovación.',
    'https://www.utdemo.edu.mx/logo.png'
);


-- =====================================================
-- 5. STUDY PLAN
-- =====================================================

INSERT INTO study_plan (name, version, description)
VALUES (
    'Ingeniería en Sistemas Computacionales',
    '2025',
    'Plan de estudios orientado a desarrollo de software y bases de datos'
);


-- =====================================================
-- 6. ACADEMIC PERIOD
-- =====================================================

INSERT INTO academic_period (name, start_date, end_date)
VALUES (
    '2025-A',
    '2025-01-15',
    '2025-06-30'
);


-- =====================================================
-- 7. COURSES
-- =====================================================

INSERT INTO course (study_plan_id, course_code, name, credits, description)
SELECT sp.id, 'ISC101', 'Fundamentos de Programación', 8,
'Introducción a la lógica de programación y estructuras básicas'
FROM study_plan sp
WHERE sp.name = 'Ingeniería en Sistemas Computacionales';

INSERT INTO course (study_plan_id, course_code, name, credits, description)
SELECT sp.id, 'ISC102', 'Bases de Datos Relacionales', 8,
'Diseño de bases de datos, modelo relacional y SQL'
FROM study_plan sp
WHERE sp.name = 'Ingeniería en Sistemas Computacionales';


-- =====================================================
-- 8. EVALUATION TYPES (para ISC101)
-- =====================================================

INSERT INTO evaluation_type (course_id, code, name, weight)
SELECT c.id, 'P1', 'Primer Parcial', 20
FROM course c WHERE c.course_code = 'ISC101';

INSERT INTO evaluation_type (course_id, code, name, weight)
SELECT c.id, 'P2', 'Segundo Parcial', 20
FROM course c WHERE c.course_code = 'ISC101';

INSERT INTO evaluation_type (course_id, code, name, weight)
SELECT c.id, 'P3', 'Tercer Parcial', 20
FROM course c WHERE c.course_code = 'ISC101';

INSERT INTO evaluation_type (course_id, code, name, weight)
SELECT c.id, 'FINAL', 'Examen Final', 40
FROM course c WHERE c.course_code = 'ISC101';

-- Extraordinario (peso 0)
INSERT INTO evaluation_type (course_id, code, name, weight)
SELECT c.id, 'EXTRA', 'Examen Extraordinario', 0
FROM course c WHERE c.course_code = 'ISC101';


-- =====================================================
-- 9. INITIAL ADMIN USER
-- Password: bcrypt example (Spring compatible)
-- =====================================================

INSERT INTO app_user (
    username,
    email,
    password_hash,
    is_active,
    created_at
)
VALUES (
    'admin',
    'admin@utdemo.edu.mx',
    '$2a$10$7EqJtq98hPqEX7fNZaFWoOQW6Z9uGq5Q8K4JpN96CBrum1BgFi7qS',
    TRUE,
    now()
);


-- Assign ADMIN role
INSERT INTO user_role (user_id, role_id)
SELECT u.id, r.id
FROM app_user u
JOIN role r ON r.name = 'ADMIN'
WHERE u.username = 'admin';


-- =====================================================
-- 10. SAMPLE NEWS
-- =====================================================

INSERT INTO news (title, content, is_published)
VALUES (
    'Inicio del Periodo Académico 2025-A',
    'Se da inicio oficial al nuevo semestre académico.',
    TRUE
);


-- =====================================================
-- 11. SAMPLE EVENT
-- =====================================================

INSERT INTO event (title, description, event_date, location, is_published)
VALUES (
    'Congreso de Tecnología 2025',
    'Evento anual enfocado en innovación y desarrollo de software.',
    '2025-03-20',
    'Auditorio Principal',
    TRUE
);