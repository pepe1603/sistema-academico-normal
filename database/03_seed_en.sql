-- =====================================================
-- INITIAL DATA - ACADEMIC SYSTEM
-- Compatible with PostgreSQL 14+
-- =====================================================

-- =====================================================
-- 1. BASE ROLES
-- =====================================================

INSERT INTO role (name, description) VALUES
('ADMIN', 'Acceso total al sistema'),
('TEACHER', 'Gestión académica y calificaciones'),
('STUDENT', 'Consulta académica y calificaciones'),
('CONTROL_ESCOLAR', 'Gestión de kardex, boletas y certificados'),
('DIRECTOR', 'Vista ejecutiva y reportes institucionales');

-- =====================================================
-- 2. BASE PERMISSIONS
-- =====================================================

INSERT INTO permission (code, description, module) VALUES

-- SECURITY
('USER_CREATE', 'Crear usuarios', 'SEGURIDAD'),
('USER_UPDATE', 'Actualizar usuarios', 'SEGURIDAD'),
('USER_DELETE', 'Eliminar usuarios (soft delete)', 'SEGURIDAD'),
('USER_VIEW', 'Consultar usuarios', 'SEGURIDAD'),
('ROLE_MANAGE', 'Gestionar roles y permisos', 'SEGURIDAD'),

-- ACADEMICO
('COURSE_CREATE', 'Crear cursos', 'ACADEMICO'),
('COURSE_UPDATE', 'Actualizar cursos', 'ACADEMICO'),
('COURSE_VIEW', 'Consultar cursos', 'ACADEMICO'),
('ENROLL_STUDENT', 'Inscribir estudiante en curso', 'ACADEMICO'),
('ENROLL_MANAGE', 'Gestionar inscripciones', 'ACADEMICO'),
('GRADE_ASSIGN', 'Asignar calificaciones', 'ACADEMICO'),
('GRADE_VIEW', 'Consultar calificaciones', 'ACADEMICO'),

-- KARDEX Y BOLETAS
('KARDEX_VIEW', 'Consultar kardex', 'KARDEX'),
('KARDEX_GENERATE', 'Generar kardex oficial', 'KARDEX'),
('KARDEX_SIGN', 'Firmar kardex oficial', 'KARDEX'),
('BOLETA_GENERATE', 'Generar boletas', 'BOLETA'),
('BOLETA_VIEW', 'Consultar boletas', 'BOLETA'),
('BOLETA_SIGN', 'Firmar boletas', 'BOLETA'),

-- ASISTENCIA
('ASISTENCIA_TAKE', 'Tomar asistencia', 'ASISTENCIA'),
('ASISTENCIA_VIEW', 'Consultar asistencia', 'ASISTENCIA'),
('ASISTENCIA_JUSTIFY', 'Justificar faltas', 'ASISTENCIA'),

-- CONDUCTA
('CONDUCTA_EVALUATE', 'Evaluar conducta', 'CONDUCTA'),
('CONDUCTA_VIEW', 'Consultar conducta', 'CONDUCTA'),

-- EXTRAORDINARIOS
('EXTRAORDINARIO_MANAGE', 'Gestionar extraordinarios', 'EXTRAORDINARIO'),
('EXTRAORDINARIO_VIEW', 'Consultar extraordinarios', 'EXTRAORDINARIO'),

-- CERTIFICADOS
('CERTIFICADO_GENERATE', 'Generar certificados', 'CERTIFICADO'),
('CERTIFICADO_SIGN', 'Firmar certificados', 'CERTIFICADO'),
('CERTIFICADO_VIEW', 'Consultar certificados', 'CERTIFICADO'),

-- SEMESTRES
('SEMESTER_CREATE', 'Crear semestres académicos', 'SEMESTRE'),
('SEMESTER_MANAGE', 'Gestionar semestres académicos', 'SEMESTRE'),

-- GENERACIONES
('GENERACION_CREATE', 'Crear generaciones', 'GENERACION'),
('GENERACION_VIEW', 'Consultar generaciones', 'GENERACION'),

-- PLANES DE ESTUDIO
('PLAN_CREATE', 'Crear planes de estudio', 'PLAN_ESTUDIO'),
('PLAN_VIEW', 'Consultar planes de estudio', 'PLAN_ESTUDIO'),

-- DASHBOARD
('DASHBOARD_VIEW', 'Consultar estadísticas del sistema', 'DASHBOARD'),
('DASHBOARD_ACADEMICO', 'Dashboard académico', 'DASHBOARD'),
('DASHBOARD_FINANCIERO', 'Dashboard financiero', 'DASHBOARD'),

-- PORTAL
('NEWS_MANAGE', 'Gestionar noticias', 'PORTAL'),
('EVENT_MANAGE', 'Gestionar eventos', 'PORTAL'),
('PORTAL_CONFIG', 'Configurar portal público', 'PORTAL'),

-- TUTORES
('TUTOR_MANAGE', 'Gestionar tutores', 'TUTOR'),
('TUTOR_VIEW', 'Consultar tutores', 'TUTOR'),

-- DOCUMENTOS
('DOCUMENTO_UPLOAD', 'Subir documentos', 'DOCUMENTO'),
('DOCUMENTO_VERIFY', 'Verificar documentos', 'DOCUMENTO'),
('DOCUMENTO_VIEW', 'Consultar documentos', 'DOCUMENTO'),

-- GRUPOS (Gestión de grupos académicos)
('GROUP_MANAGE', 'Gestionar grupos', 'GRUPO'),
('GROUP_VIEW', 'Consultar grupos', 'GRUPO'),
('GROUP_ASSIGN_TEACHER', 'Asignar profesor a grupo', 'GRUPO');

-- =====================================================
-- 3. ROLE - PERMISSION ASSIGNMENTS
-- =====================================================

-- ADMIN → todos los permisos
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r CROSS JOIN permission p WHERE r.name = 'ADMIN';

-- TEACHER → permisos académicos limitados
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r
JOIN permission p ON p.code IN ('COURSE_VIEW', 'GRADE_ASSIGN', 'GRADE_VIEW', 'ASISTENCIA_TAKE', 'ASISTENCIA_VIEW', 'CONDUCTA_EVALUATE', 'CONDUCTA_VIEW', 'DASHBOARD_VIEW')
WHERE r.name = 'TEACHER';

-- STUDENT → permisos de consulta
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r
JOIN permission p ON p.code IN ('COURSE_VIEW', 'GRADE_VIEW', 'KARDEX_VIEW', 'BOLETA_VIEW', 'ASISTENCIA_VIEW', 'CONDUCTA_VIEW')
WHERE r.name = 'STUDENT';

-- CONTROL_ESCOLAR → permisos completos
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r
JOIN permission p ON p.code IN ('COURSE_VIEW', 'COURSE_CREATE', 'COURSE_UPDATE', 'ENROLL_STUDENT', 'ENROLL_MANAGE', 'GRADE_ASSIGN', 'GRADE_VIEW', 'KARDEX_VIEW', 'KARDEX_GENERATE', 'KARDEX_SIGN', 'BOLETA_GENERATE', 'BOLETA_VIEW', 'BOLETA_SIGN', 'ASISTENCIA_TAKE', 'ASISTENCIA_VIEW', 'ASISTENCIA_JUSTIFY', 'CONDUCTA_EVALUATE', 'CONDUCTA_VIEW', 'EXTRAORDINARIO_MANAGE', 'EXTRAORDINARIO_VIEW', 'CERTIFICADO_GENERATE', 'CERTIFICADO_VIEW', 'SEMESTER_MANAGE', 'GENERACION_VIEW', 'PLAN_VIEW', 'DASHBOARD_ACADEMICO', 'TUTOR_MANAGE', 'TUTOR_VIEW', 'DOCUMENTO_VIEW')
WHERE r.name = 'CONTROL_ESCOLAR';

-- DIRECTOR → permisos de vista y reportes
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r
JOIN permission p ON p.code IN ('COURSE_VIEW', 'GRADE_VIEW', 'KARDEX_VIEW', 'BOLETA_VIEW', 'ASISTENCIA_VIEW', 'CONDUCTA_VIEW', 'EXTRAORDINARIO_VIEW', 'CERTIFICADO_VIEW', 'GENERACION_VIEW', 'PLAN_VIEW', 'DASHBOARD_VIEW', 'DASHBOARD_ACADEMICO', 'NEWS_MANAGE', 'EVENT_MANAGE', 'USER_VIEW')
WHERE r.name = 'DIRECTOR';

-- =====================================================
-- 4. INSTITUTION DATA
-- =====================================================

INSERT INTO institution (name, address, phone, email, website, mission, vision, history, values, logo_url)
VALUES (
    'Escuela Normal Emiliano Zapata',
    'Av. principal S/N, Col. Centro',
    '+52 999 999 9999',
    'contacto@enez.edu.mx',
    'https://www.enez.edu.mx',
    'Formar profesionales de la educación con excelencia académica, compromiso social y valores éticos.',
    'Ser una institución líder en la formación de educadores de calidad, contribuyendo al desarrollo integral de la sociedad.',
    'Institución de educación superior comprometida con la excelencia académica desde su fundación.',
    'Integridad, Excelencia, Compromiso, Innovación, Servicio.',
    NULL
);

-- =====================================================
-- 5. ACADEMIC SEMESTERS
-- =====================================================

INSERT INTO academic_semester (name, year, period, start_date, end_date, classes_start_date, classes_end_date, enrollment_deadline, drop_deadline, status, is_current)
VALUES 
('2025-1', 2025, 1, '2025-01-15', '2025-06-30', '2025-01-20', '2025-06-15', '2025-02-15', '2025-03-31', 'OPEN', TRUE),
('2025-2', 2025, 2, '2025-08-15', '2025-12-20', '2025-08-20', '2025-12-10', '2025-09-15', '2025-10-31', 'DRAFT', FALSE),
('2024-2', 2024, 2, '2024-08-15', '2024-12-20', '2024-08-20', '2024-12-10', '2024-09-15', '2024-10-31', 'CLOSED', FALSE),
('2024-1', 2024, 1, '2024-01-15', '2024-06-30', '2024-01-20', '2024-06-15', '2024-02-15', '2024-03-31', 'ARCHIVED', FALSE);

-- =====================================================
-- 6. GENERATIONS
-- =====================================================

INSERT INTO generation (name, entry_year, graduation_year, status, start_date, end_date)
VALUES 
('Generación 2025', 2025, 2029, 'ACTIVE', '2025-01-15', '2029-06-30'),
('Generación 2024', 2024, 2028, 'ACTIVE', '2024-01-15', '2028-06-30'),
('Generación 2023', 2023, 2027, 'GRADUATED', '2023-01-15', '2027-06-30');

-- =====================================================
-- 7. STUDY PLANS (Plans for Teacher Education)
-- =====================================================

INSERT INTO study_plan (code, name, version, description, title_degree, total_credits, duration_semesters)
VALUES
('LEP', 'Licenciatura en Educación Primaria', '2024', 'Plan de estudios para formación de docentes de educación primaria', 'Licenciado/a en Educación Primaria', 240, 8),
('LES', 'Licenciatura en Educación Secundaria', '2024', 'Plan de estudios para formación de docentes de educación secundaria en matemáticas', 'Licenciado/a en Educación Secundaria con especialización en Matemáticas', 260, 8),
('LEI', 'Licenciatura en Educación Inicial', '2024', 'Plan de estudios para formación de docentes de educación inicial', 'Licenciado/a en Educación Inicial', 220, 8),
('LENG', 'Licenciatura en Inglés', '2024', 'Plan de estudios para formación de docentes de inglés', 'Licenciado/a en la Enseñanza del Inglés', 240, 8);

-- =====================================================
-- 8. SEMESTERS BY STUDY PLAN
-- =====================================================

-- Semesters for LEP (Licenciatura en Educación Primaria)
INSERT INTO semester (study_plan_id, semester_number, name) 
SELECT sp.id, 1, 'Primer Semestre' FROM study_plan sp WHERE sp.code = 'LEP';
INSERT INTO semester (study_plan_id, semester_number, name) 
SELECT sp.id, 2, 'Segundo Semestre' FROM study_plan sp WHERE sp.code = 'LEP';
INSERT INTO semester (study_plan_id, semester_number, name) 
SELECT sp.id, 3, 'Tercer Semestre' FROM study_plan sp WHERE sp.code = 'LEP';
INSERT INTO semester (study_plan_id, semester_number, name) 
SELECT sp.id, 4, 'Cuarto Semestre' FROM study_plan sp WHERE sp.code = 'LEP';
INSERT INTO semester (study_plan_id, semester_number, name) 
SELECT sp.id, 5, 'Quinto Semestre' FROM study_plan sp WHERE sp.code = 'LEP';
INSERT INTO semester (study_plan_id, semester_number, name) 
SELECT sp.id, 6, 'Sexto Semestre' FROM study_plan sp WHERE sp.code = 'LEP';
INSERT INTO semester (study_plan_id, semester_number, name) 
SELECT sp.id, 7, 'Séptimo Semestre' FROM study_plan sp WHERE sp.code = 'LEP';
INSERT INTO semester (study_plan_id, semester_number, name) 
SELECT sp.id, 8, 'Octavo Semestre' FROM study_plan sp WHERE sp.code = 'LEP';

-- Semesters for LES
INSERT INTO semester (study_plan_id, semester_number, name) 
SELECT sp.id, 1, 'Primer Semestre' FROM study_plan sp WHERE sp.code = 'LES';
INSERT INTO semester (study_plan_id, semester_number, name) 
SELECT sp.id, 2, 'Segundo Semestre' FROM study_plan sp WHERE sp.code = 'LES';
INSERT INTO semester (study_plan_id, semester_number, name) 
SELECT sp.id, 3, 'Tercer Semestre' FROM study_plan sp WHERE sp.code = 'LES';
INSERT INTO semester (study_plan_id, semester_number, name) 
SELECT sp.id, 4, 'Cuarto Semestre' FROM study_plan sp WHERE sp.code = 'LES';
INSERT INTO semester (study_plan_id, semester_number, name) 
SELECT sp.id, 5, 'Quinto Semestre' FROM study_plan sp WHERE sp.code = 'LES';
INSERT INTO semester (study_plan_id, semester_number, name) 
SELECT sp.id, 6, 'Sexto Semestre' FROM study_plan sp WHERE sp.code = 'LES';
INSERT INTO semester (study_plan_id, semester_number, name) 
SELECT sp.id, 7, 'Séptimo Semestre' FROM study_plan sp WHERE sp.code = 'LES';
INSERT INTO semester (study_plan_id, semester_number, name) 
SELECT sp.id, 8, 'Octavo Semestre' FROM study_plan sp WHERE sp.code = 'LES';

-- =====================================================
-- 9. COURSES (Using function fn_generate_course_code)
-- =====================================================

-- Courses for LEP - Semestre 1
INSERT INTO course (study_plan_id, semester_id, course_code, name, credits, hours_theory, hours_practice, description, is_mandatory)
SELECT sp.id, s.id, 'LEP101', 'Introducción a la Educación', 8, 4, 2, 'Fundamentos de la educación y la pedagogía', TRUE
FROM study_plan sp, semester s WHERE sp.code = 'LEP' AND s.semester_number = 1 AND s.study_plan_id = sp.id;

INSERT INTO course (study_plan_id, semester_id, course_code, name, credits, hours_theory, hours_practice, description, is_mandatory)
SELECT sp.id, s.id, 'LEP102', 'Psicología del Desarrollo', 6, 3, 2, 'Teorías del desarrollo humano y aprendizaje', TRUE
FROM study_plan sp, semester s WHERE sp.code = 'LEP' AND s.semester_number = 1 AND s.study_plan_id = sp.id;

INSERT INTO course (study_plan_id, semester_id, course_code, name, credits, hours_theory, hours_practice, description, is_mandatory)
SELECT sp.id, s.id, 'LEP103', 'Didáctica General', 8, 4, 2, 'Métodos y técnicas de enseñanza-aprendizaje', TRUE
FROM study_plan sp, semester s WHERE sp.code = 'LEP' AND s.semester_number = 1 AND s.study_plan_id = sp.id;

INSERT INTO course (study_plan_id, semester_id, course_code, name, credits, hours_theory, hours_practice, description, is_mandatory)
SELECT sp.id, s.id, 'LEP104', 'Matemáticas para Maestros I', 6, 3, 2, 'Fundamentos matemáticos para la enseñanza', TRUE
FROM study_plan sp, semester s WHERE sp.code = 'LEP' AND s.semester_number = 1 AND s.study_plan_id = sp.id;

INSERT INTO course (study_plan_id, semester_id, course_code, name, credits, hours_theory, hours_practice, description, is_mandatory)
SELECT sp.id, s.id, 'LEP105', 'Lenguaje y Comunicación', 6, 3, 2, 'Desarrollo de competencias lingüísticas', TRUE
FROM study_plan sp, semester s WHERE sp.code = 'LEP' AND s.semester_number = 1 AND s.study_plan_id = sp.id;

-- Courses for LEP - Semestre 2
INSERT INTO course (study_plan_id, semester_id, course_code, name, credits, hours_theory, hours_practice, description, is_mandatory)
SELECT sp.id, s.id, 'LEP201', 'Psicología Educativa', 6, 3, 2, 'Teorías del aprendizaje y motivación', TRUE
FROM study_plan sp, semester s WHERE sp.code = 'LEP' AND s.semester_number = 2 AND s.study_plan_id = sp.id;

INSERT INTO course (study_plan_id, semester_id, course_code, name, credits, hours_theory, hours_practice, description, is_mandatory)
SELECT sp.id, s.id, 'LEP202', 'Diseño Curricular', 8, 4, 2, 'Fundamentos y diseño de programas educativos', TRUE
FROM study_plan sp, semester s WHERE sp.code = 'LEP' AND s.semester_number = 2 AND s.study_plan_id = sp.id;

INSERT INTO course (study_plan_id, semester_id, course_code, name, credits, hours_theory, hours_practice, description, is_mandatory)
SELECT sp.id, s.id, 'LEP203', 'Matemáticas para Maestros II', 6, 3, 2, 'Aritmética y geometría para la enseñanza', TRUE
FROM study_plan sp, semester s WHERE sp.code = 'LEP' AND s.semester_number = 2 AND s.study_plan_id = sp.id;

INSERT INTO course (study_plan_id, semester_id, course_code, name, credits, hours_theory, hours_practice, description, is_mandatory)
SELECT sp.id, s.id, 'LEP204', 'Expresión Oral y Escrita', 6, 3, 2, 'Comunicación académica y pedagógica', TRUE
FROM study_plan sp, semester s WHERE sp.code = 'LEP' AND s.semester_number = 2 AND s.study_plan_id = sp.id;

-- Courses for LES - Semestre 1
INSERT INTO course (study_plan_id, semester_id, course_code, name, credits, hours_theory, hours_practice, description, is_mandatory)
SELECT sp.id, s.id, 'LES101', 'Introducción a la Educación Secundaria', 8, 4, 2, 'Fundamentos de la educación en secundaria', TRUE
FROM study_plan sp, semester s WHERE sp.code = 'LES' AND s.semester_number = 1 AND s.study_plan_id = sp.id;

INSERT INTO course (study_plan_id, semester_id, course_code, name, credits, hours_theory, hours_practice, description, is_mandatory)
SELECT sp.id, s.id, 'LES102', 'Álgebra Superior', 8, 4, 2, 'Álgebra para la enseñanza en secundaria', TRUE
FROM study_plan sp, semester s WHERE sp.code = 'LES' AND s.semester_number = 1 AND s.study_plan_id = sp.id;

INSERT INTO course (study_plan_id, semester_id, course_code, name, credits, hours_theory, hours_practice, description, is_mandatory)
SELECT sp.id, s.id, 'LES103', 'Geometría y Trigonometría', 8, 4, 2, 'Geometría euclidiana y trigonometría', TRUE
FROM study_plan sp, semester s WHERE sp.code = 'LES' AND s.semester_number = 1 AND s.study_plan_id = sp.id;

INSERT INTO course (study_plan_id, semester_id, course_code, name, credits, hours_theory, hours_practice, description, is_mandatory)
SELECT sp.id, s.id, 'LES104', 'Didáctica de las Matemáticas', 8, 4, 2, 'Metodología para enseñar matemáticas', TRUE
FROM study_plan sp, semester s WHERE sp.code = 'LES' AND s.semester_number = 1 AND s.study_plan_id = sp.id;

-- =====================================================
-- 10. EVALUATION TYPES
-- =====================================================

-- Evaluation types for LEP101
INSERT INTO evaluation_type (course_id, code, name, weight)
SELECT c.id, 'P1', 'Primer Parcial', 25 FROM course c WHERE c.course_code = 'LEP101';

INSERT INTO evaluation_type (course_id, code, name, weight)
SELECT c.id, 'P2', 'Segundo Parcial', 25 FROM course c WHERE c.course_code = 'LEP101';

INSERT INTO evaluation_type (course_id, code, name, weight)
SELECT c.id, 'PROY', 'Proyecto', 30 FROM course c WHERE c.course_code = 'LEP101';

INSERT INTO evaluation_type (course_id, code, name, weight)
SELECT c.id, 'PART', 'Participación', 20 FROM course c WHERE c.course_code = 'LEP101';

-- Evaluation types for LEP102
INSERT INTO evaluation_type (course_id, code, name, weight)
SELECT c.id, 'P1', 'Primer Parcial', 30 FROM course c WHERE c.course_code = 'LEP102';

INSERT INTO evaluation_type (course_id, code, name, weight)
SELECT c.id, 'P2', 'Segundo Parcial', 30 FROM course c WHERE c.course_code = 'LEP102';

INSERT INTO evaluation_type (course_id, code, name, weight)
SELECT c.id, 'EXAM', 'Examen Final', 40 FROM course c WHERE c.course_code = 'LEP102';

-- Evaluation types for LES102 (Math course)
INSERT INTO evaluation_type (course_id, code, name, weight)
SELECT c.id, 'P1', 'Primer Parcial', 20 FROM course c WHERE c.course_code = 'LES102';

INSERT INTO evaluation_type (course_id, code, name, weight)
SELECT c.id, 'P2', 'Segundo Parcial', 20 FROM course c WHERE c.course_code = 'LES102';

INSERT INTO evaluation_type (course_id, code, name, weight)
SELECT c.id, 'P3', 'Tercer Parcial', 20 FROM course c WHERE c.course_code = 'LES102';

INSERT INTO evaluation_type (course_id, code, name, weight)
SELECT c.id, 'FINAL', 'Examen Final', 40 FROM course c WHERE c.course_code = 'LES102';

-- =====================================================
-- 11. ACADEMIC PERIODS (legacy compatibility)
-- =====================================================

INSERT INTO academic_period (name, start_date, end_date) VALUES
('2025-1', '2025-01-15', '2025-06-30'),
('2025-2', '2025-08-15', '2025-12-20'),
('2024-2', '2024-08-15', '2024-12-20'),
('2024-1', '2024-01-15', '2024-06-30');

-- =====================================================
-- 11.1 ACADEMIC GROUPS (Grupos - secciones de un curso)
-- =====================================================

-- Grupos para el semestre 2025-1
-- Grupo A de LEP101 - Introducción a la Educación
INSERT INTO academic_group (name, academic_semester_id, course_id, capacity)
SELECT 'A', acs.id, c.id, 30
FROM academic_semester acs, course c 
WHERE acs.name = '2025-1' AND c.course_code = 'LEP101';

-- Grupo A de LEP102 - Psicología del Desarrollo
INSERT INTO academic_group (name, academic_semester_id, course_id, capacity)
SELECT 'A', acs.id, c.id, 30
FROM academic_semester acs, course c 
WHERE acs.name = '2025-1' AND c.course_code = 'LEP102';

-- Grupo A de LEP103 - Didáctica General
INSERT INTO academic_group (name, academic_semester_id, course_id, capacity)
SELECT 'A', acs.id, c.id, 30
FROM academic_semester acs, course c 
WHERE acs.name = '2025-1' AND c.course_code = 'LEP103';

-- Grupo A de LES101 - Introducción a la Educación Secundaria
INSERT INTO academic_group (name, academic_semester_id, course_id, capacity)
SELECT 'A', acs.id, c.id, 25
FROM academic_semester acs, course c 
WHERE acs.name = '2025-1' AND c.course_code = 'LES101';

-- Grupo A de LES102 - Álgebra Superior
INSERT INTO academic_group (name, academic_semester_id, course_id, capacity)
SELECT 'A', acs.id, c.id, 25
FROM academic_semester acs, course c 
WHERE acs.name = '2025-1' AND c.course_code = 'LES102';

-- =====================================================
-- 12. SYSTEM CONFIGURATION
-- =====================================================

INSERT INTO system_configuration (config_key, config_value, description, data_type, module) VALUES
-- Generales
('INSTITUCION_NOMBRE', 'Escuela Normal Emiliano Zapata', 'Nombre oficial', 'STRING', 'GENERAL'),
('INSTITUCION_CLAVE', 'ENEZ', 'Clave institucional', 'STRING', 'GENERAL'),
('NIVEL_EDUCATIVO', 'LICENCIATURA', 'Nivel educativo', 'STRING', 'GENERAL'),
('TIPO_INSTITUCION', 'ESCUELA_NORMAL', 'Tipo de institución', 'STRING', 'GENERAL'),

-- Académico
('PROMEDIO_MINIMO_APROBATORIO', '70', 'Promedio mínimo para aprobar', 'NUMBER', 'ACADEMICO'),
('ASISTENCIA_MINIMA_PORCENTAJE', '80', 'Porcentaje mínimo de asistencia', 'NUMBER', 'ACADEMICO'),
('CREDITOS_TITULACION', '240', 'Créditos para titulación', 'NUMBER', 'ACADEMICO'),
('DURACION_CARRERA_SEMESTRES', '8', 'Duración de la carrera en semestres', 'NUMBER', 'ACADEMICO'),

-- Extraordinarios
('EXTRAORDINARIO_COSTO', '500.00', 'Costo examen extraordinario', 'NUMBER', 'EXTRAORDINARIO'),
('EXTRAORDINARIO_MAXIMO_INTENTOS', '3', 'Máximo intentos por materia', 'NUMBER', 'EXTRAORDINARIO'),

-- Certificados
('CERTIFICADO_COSTO', '350.00', 'Costo certificado', 'NUMBER', 'CERTIFICADO'),
('CERTIFICADO_TIEMPO_ENTREGA_DIAS', '30', 'Días para entrega', 'NUMBER', 'CERTIFICADO'),

-- Portal
('PORTAL_PUBLICO_ACTIVO', 'true', 'Portal activo', 'BOOLEAN', 'PORTAL'),
('NOTICIAS_POR_PAGINA', '10', 'Noticias por página', 'NUMBER', 'PORTAL');

-- =====================================================
-- 13. ADMIN USER
-- Password: admin123 (bcrypt)
-- =====================================================

INSERT INTO app_user (username, email, password_hash, is_active, created_at)
VALUES ('admin', 'admin@enez.edu.mx', '$2a$10$7EqJtq98hPqEX7fNZaFWoOQW6Z9uGq5Q8K4JpN96CBrum1BgFi7qS', TRUE, now());

-- Assign ADMIN role
INSERT INTO user_role (user_id, role_id)
SELECT u.id, r.id FROM app_user u JOIN role r ON r.name = 'ADMIN' WHERE u.username = 'admin';

-- =====================================================
-- 14. NEWS
-- =====================================================

INSERT INTO news (title, content, is_published) VALUES
('Inicio del Semestre 2025-1', 'Se da inicio oficial al nuevo semestre académico. Bienvenidos estudiantes.', TRUE),
('Convocatoria de Inscripción 2025', 'Inscripciones abiertas para nuevo ingreso. Consulta los requisitos.', TRUE),
('Premio a la Excelencia Académica', 'Convocatoria para estudiantes con promedio mayor a 90.', TRUE),
('Semana de la Educación 2025', 'Evento académico con conferencias y talleres pedagógicos.', TRUE);

-- =====================================================
-- 15. EVENTS
-- =====================================================

INSERT INTO event (title, description, event_date, location, is_published) VALUES
('Semana Pedagógica', 'Evento académico con conferencias y talleres sobre metodología educativa.', '2025-03-15', 'Auditorio Principal', TRUE),
('Feria de Proyectos', 'Presentaciones de proyectos finales de semestre.', '2025-06-10', 'Plantel Central', TRUE),
('Conferencia: Futuro de la Educación', 'Charla con especialistas en educación.', '2025-04-20', 'Sala de Videoconferencias', TRUE),
('Congreso de Educación Normal', 'Encuentro de escuelas normales de la región.', '2025-05-15', 'Auditorio Principal', TRUE);

-- =====================================================
-- 16. PORTAL ADVERTISEMENTS
-- =====================================================

INSERT INTO portal_advertisement (title, description, image_url, link_url, position, display_order, is_published, start_date, end_date)
VALUES 
('Admisiones 2025', 'Inscripciones abiertas para nuevo ingreso', '/images/banners/admision2025.jpg', '/admisiones', 'BANNER', 1, TRUE, '2025-01-01', '2025-03-31'),
('Becas Disponibles', 'Programas de beca para estudiantes', '/images/banners/becas.jpg', '/becas', 'SIDEBAR', 1, TRUE, NULL, NULL);

-- =====================================================
-- 17. EDUCATIONAL RESOURCES
-- =====================================================

INSERT INTO educational_resource (title, description, resource_type, resource_url, is_published) VALUES
('Manual de Didáctica General', 'Guía completa de métodos de enseñanza', 'PDF', '/recursos/lep103/manual.pdf', TRUE),
('Video: Estrategias de Aprendizaje', 'Tutorial sobre estrategias didácticas', 'VIDEO', 'https://youtube.com/watch?v=ejemplo', TRUE),
('Recursos para Matemáticas', 'Materiales para la enseñanza de matemáticas', 'LINK', 'https://www.math.edu.mx/', TRUE);
