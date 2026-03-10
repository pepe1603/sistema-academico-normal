# Documentación de la Base de Datos - Sistema Académico

Este documento es una guía de referencia para entender la estructura de la base de datos del Sistema Académico. Cada tabla, campo y concepto está descrito en español para facilitar la comprensión del equipo de desarrollo.

---

## Tabla de Contenidos

1. [Módulo de Seguridad](#1-módulo-de-seguridad)
2. [Módulo Académico - Tablas Base](#2-módulo-académico---tablas-base)
3. [Módulo Kardex](#3-módulo-kardex)
4. [Módulo de Boletas (Report Cards)](#4-módulo-de-boletas-report-cards)
5. [Módulo de Asistencia](#5-módulo-de-asistencia)
6. [Módulo de Conducta](#6-módulo-de-conducta)
7. [Módulo de Exámenes Extraordinarios](#7-módulo-de-exámenes-extraordinarios)
8. [Módulo de Certificados](#8-módulo-de-certificados)
9. [Módulo de Tutores (Guardianes)](#9-módulo-de-tutores-guardians)
10. [Módulo de Documentos](#10-módulo-de-documentos)
11. [Módulo de Configuración](#11-módulo-de-configuración)
12. [Módulo del Portal Público](#12-módulo-del-portal-público)
13. [Módulo de Auditoría](#13-módulo-de-auditoría)
14. [Tablas de Relaciones](#14-tablas-de-relaciones)

---

## 1. MÓDULO DE SEGURIDAD

### 1.1 app_user (Usuario de la Aplicación)

**Descripción:** Tabla principal que almacena los usuarios del sistema. Cada registro representa un usuario que puede iniciar sesión.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique identifier for the user | Identificador único del usuario |
| username | VARCHAR(50) | Unique login name | Nombre de usuario único para iniciar sesión |
| email | VARCHAR(150) | User's email address | Correo electrónico del usuario |
| password_hash | TEXT | Hashed password | Contraseña encriptada |
| failed_attempts | INTEGER | Number of failed login attempts | Número de intentos fallidos de inicio de sesión |
| is_locked | BOOLEAN | Account lock status | Estado de bloqueo de la cuenta |
| last_login | TIMESTAMPTZ | Last login timestamp | Fecha y hora del último inicio de sesión |
| is_active | BOOLEAN | Whether the user is active | Si el usuario está activo |
| is_deleted | BOOLEAN | Soft delete flag | Bandera de eliminación suave |
| created_at | TIMESTAMPTZ | Record creation timestamp | Fecha de creación del registro |
| updated_at | TIMESTAMPTZ | Last update timestamp | Fecha de última actualización |
| created_by | UUID | User who created this record | Usuario que creó este registro |
| updated_by | UUID | User who last updated this record | Usuario que actualizó este registro por última vez |

---

### 1.2 role (Rol)

**Descripción:** Define los roles en el sistema (ADMIN, TEACHER, STUDENT, etc.). Los roles agrupan permisos.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique role identifier | Identificador único del rol |
| name | VARCHAR(50) | Role name | Nombre del rol |
| description | TEXT | Role description | Descripción del rol |
| is_active | BOOLEAN | Whether the role is active | Si el rol está activo |
| is_deleted | BOOLEAN | Soft delete flag | Bandera de eliminación suave |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |
| updated_at | TIMESTAMPTZ | Last update timestamp | Fecha de última actualización |

**Roles predefinidos:**
- **ADMIN** - Acceso total al sistema
- **TEACHER** - Gestión académica y calificaciones
- **STUDENT** - Consulta académica y calificaciones
- **CONTROL_ESCOLAR** - Gestión de kardex, boletas y certificados
- **DIRECTOR** - Vista ejecutiva y reportes institucionales

---

### 1.3 permission (Permiso)

**Descripción:** Define permisos individuales que pueden asignarse a los roles. Cada permiso representa una acción específica.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique permission identifier | Identificador único del permiso |
| code | VARCHAR(100) | Unique permission code | Código único del permiso |
| description | TEXT | Permission description | Descripción del permiso |
| module | VARCHAR(100) | Module this permission belongs to | Módulo al que pertenece este permiso |
| is_active | BOOLEAN | Whether the permission is active | Si el permiso está activo |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |

**Módulos de permisos:**
- **SEGURIDAD** - Gestión de usuarios y roles
- **ACADEMICO** - Cursos e inscripciones
- **KARDEX** - Consulta y generación de kardex
- **BOLETA** - Gestión de boletas
- **ASISTENCIA** - Control de asistencia
- **CONDUCTA** - Evaluación de conducta
- **EXTRAORDINARIO** - Exámenes extraordinarios
- **CERTIFICADO** - Generación de certificados
- **SEMESTRE** - Gestión de semestres
- **GENERACION** - Gestión de generaciones
- **PLAN_ESTUDIO** - Planes de estudio
- **DASHBOARD** - Estadísticas
- **PORTAL** - Portal público
- **TUTOR** - Tutores
- **DOCUMENTO** - Documentos de estudiantes

---

### 1.4 user_session (Sesión de Usuario)

**Descripción:** Almacena las sesiones activas de los usuarios (tokens JWT).

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique session identifier | Identificador único de la sesión |
| user_id | UUID | Reference to app_user | Referencia al usuario |
| jwt_token | TEXT | JWT token for authentication | Token JWT para autenticación |
| ip_address | VARCHAR(45) | IP address of the session | Dirección IP de la sesión |
| user_agent | TEXT | Browser/client information | Información del navegador/cliente |
| started_at | TIMESTAMPTZ | Session start time | Hora de inicio de la sesión |
| expires_at | TIMESTAMPTZ | Session expiration time | Hora de expiración de la sesión |
| is_active | BOOLEAN | Whether session is active | Si la sesión está activa |

---

### 1.5 password_recovery (Recuperación de Contraseña)

**Descripción:** Gestiona los tokens para recuperar contraseñas olvidadas.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique recovery request identifier | Identificador único de la solicitud |
| user_id | UUID | Reference to app_user | Referencia al usuario |
| recovery_token | VARCHAR(255) | Unique token for password reset | Token único para restablecer contraseña |
| is_used | BOOLEAN | Whether token has been used | Si el token ha sido usado |
| expires_at | TIMESTAMPTZ | Token expiration time | Hora de expiración del token |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |

---

## 2. MÓDULO ACADÉMICO - TABLAS BASE

### 2.1 generation (Generación)

**Descripción:** Representa una cohorte de estudiantes que ingresan en el mismo año y esperan graduarse juntos.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique generation identifier | Identificador único de la generación |
| name | VARCHAR(100) | Generation name | Nombre de la generación |
| entry_year | INTEGER | Year students enrolled | Año de ingreso de los estudiantes |
| graduation_year | INTEGER | Expected graduation year | Año de graduación esperado |
| status | VARCHAR(20) | Generation status | Estado de la generación |
| start_date | DATE | Generation start date | Fecha de inicio de la generación |
| end_date | DATE | Generation end date | Fecha de fin de la generación |
| is_deleted | BOOLEAN | Soft delete flag | Bandera de eliminación suave |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |
| updated_at | TIMESTAMPTZ | Last update timestamp | Fecha de última actualización |

**Estados posibles:**
- **ACTIVE** - Generación activa
- **GRADUATED** - Generación graduada
- **ARCHIVED** - Generación archivada

---

### 2.2 study_plan (Plan de Estudios)

**Descripción:** Define los programas educativos (carreras) disponibles en la institución.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique study plan identifier | Identificador único del plan de estudios |
| code | VARCHAR(20) | Unique plan code | Código único del plan |
| name | VARCHAR(150) | Study plan name | Nombre del plan de estudios |
| version | VARCHAR(20) | Plan version | Versión del plan |
| description | TEXT | Plan description | Descripción del plan |
| title_degree | VARCHAR(150) | Degree title awarded | Título que se otorga |
| total_credits | INTEGER | Total credits required | Total de créditos requeridos |
| duration_semesters | INTEGER | Duration in semesters | Duración en semestres |
| is_active | BOOLEAN | Whether plan is active | Si el plan está activo |
| is_deleted | BOOLEAN | Soft delete flag | Bandera de eliminación suave |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |
| updated_at | TIMESTAMPTZ | Last update timestamp | Fecha de última actualización |

**Planes de estudios predefinidos:**
- **LEP** - Licenciatura en Educación Primaria
- **LES** - Licenciatura en Educación Secundaria
- **LEI** - Licenciatura en Educación Inicial
- **LENG** - Licenciatura en Inglés

---

### 2.3 semester (Semestre del Plan)

**Descripción:** Define los semestres que conforman un plan de estudios.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique semester identifier | Identificador único del semestre |
| study_plan_id | UUID | Reference to study_plan | Referencia al plan de estudios |
| semester_number | INTEGER | Semester number (1-10) | Número de semestre (1-10) |
| name | VARCHAR(50) | Semester name | Nombre del semestre |
| is_active | BOOLEAN | Whether semester is active | Si el semestre está activo |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |

---

### 2.4 academic_semester (Semestre Académico)

**Descripción:** Representa un período académico real (ej. "2025-1", "2025-2") con fechas específicas.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique academic semester identifier | Identificador único del semestre académico |
| name | VARCHAR(50) | Semester name | Nombre del semestre |
| year | INTEGER | Year | Año |
| period | INTEGER | Period (1 or 2) | Período (1 o 2) |
| start_date | DATE | Semester start date | Fecha de inicio del semestre |
| end_date | DATE | Semester end date | Fecha de fin del semestre |
| classes_start_date | DATE | Classes start date | Fecha de inicio de clases |
| classes_end_date | DATE | Classes end date | Fecha de fin de clases |
| enrollment_deadline | DATE | Enrollment deadline | Fecha límite de inscripción |
| drop_deadline | DATE | Course drop deadline | Fecha límite para dar de baja |
| status | VARCHAR(20) | Semester status | Estado del semestre |
| is_current | BOOLEAN | Is current semester | Si es el semestre actual |
| is_deleted | BOOLEAN | Soft delete flag | Bandera de eliminación suave |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |
| updated_at | TIMESTAMPTZ | Last update timestamp | Fecha de última actualización |

**Estados posibles:**
- **DRAFT** - Borrador
- **OPEN** - Abierto para inscripciones
- **CLOSED** - Cerrado
- **ARCHIVED** - Archivado

---

### 2.5 academic_period (Período Académico - Legacy)

**Descripción:** Tabla de compatibilidad legacy para períodos académicos.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique period identifier | Identificador único del período |
| name | VARCHAR(20) | Period name | Nombre del período |
| start_date | DATE | Period start date | Fecha de inicio |
| end_date | DATE | Period end date | Fecha de fin |
| is_active | BOOLEAN | Whether period is active | Si el período está activo |
| is_deleted | BOOLEAN | Soft delete flag | Bandera de eliminación suave |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |
| updated_at | TIMESTAMPTZ | Last update timestamp | Fecha de última actualización |

---

### 2.5.1 academic_group (Grupo Académico)

**Descripción:** Representa un grupo o sección específica de un curso en un semestre. Permite asignar un profesor a un grupo específico de estudiantes, controlando así qué profesores pueden calificar a qué alumnos.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique group identifier | Identificador único del grupo |
| name | VARCHAR(50) | Group name (A, B, C...) | Nombre del grupo (A, B, C...) |
| academic_semester_id | UUID | Reference to academic_semester | Referencia al semestre académico |
| course_id | UUID | Reference to course | Referencia al curso |
| teacher_id | UUID | Reference to teacher (profesor asignado) | Referencia al profesor |
| capacity | INTEGER | Maximum students capacity | Capacidad máxima de estudiantes |
| is_active | BOOLEAN | Whether group is active | Si el grupo está activo |
| is_deleted | BOOLEAN | Soft delete flag | Bandera de eliminación suave |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |
| updated_at | TIMESTAMPTZ | Last update timestamp | Fecha de última actualización |

**Importante:** Esta tabla permite que un profesor solo pueda calificar a los estudiantes de su grupo asignado.

---

### 2.6 course (Curso/Materia)

**Descripción:** Representa una materia o curso que se imparte en un plan de estudios.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique course identifier | Identificador único del curso |
| study_plan_id | UUID | Reference to study_plan | Referencia al plan de estudios |
| semester_id | UUID | Reference to semester | Referencia al semestre |
| course_code | VARCHAR(20) | Unique course code | Código único del curso |
| name | VARCHAR(150) | Course name | Nombre del curso |
| credits | INTEGER | Course credits | Créditos del curso |
| hours_theory | INTEGER | Theory hours per week | Horas de teoría por semana |
| hours_practice | INTEGER | Practice hours per week | Horas de práctica por semana |
| description | TEXT | Course description | Descripción del curso |
| is_mandatory | BOOLEAN | Is mandatory course | Si es curso obligatorio |
| is_active | BOOLEAN | Whether course is active | Si el curso está activo |
| is_deleted | BOOLEAN | Soft delete flag | Bandera de eliminación suave |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |
| updated_at | TIMESTAMPTZ | Last update timestamp | Fecha de última actualización |

---

### 2.7 teacher (Profesor/Docente)

**Descripción:** Almacena la información de los profesores o docentes de la institución.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique teacher identifier | Identificador único del profesor |
| user_id | UUID | Reference to app_user | Referencia al usuario |
| employee_number | VARCHAR(20) | Unique employee number | Número de empleado único |
| rfc | VARCHAR(13) | RFC (Tax ID) | RFC (Identificador fiscal) |
| curp | VARCHAR(18) | CURP (Mexican ID) | CURP (Identificador mexicano) |
| first_name | VARCHAR(100) | First name | Nombre(s) |
| last_name | VARCHAR(100) | Last name | Apellido(s) |
| institutional_email | VARCHAR(150) | Institutional email | Correo institucional |
| secondary_email | VARCHAR(150) | Secondary email | Correo secundario |
| phone | VARCHAR(20) | Primary phone | Teléfono principal |
| secondary_phone | VARCHAR(20) | Secondary phone | Teléfono secundario |
| is_active | BOOLEAN | Whether teacher is active | Si el profesor está activo |
| is_deleted | BOOLEAN | Soft delete flag | Bandera de eliminación suave |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |
| updated_at | TIMESTAMPTZ | Last update timestamp | Fecha de última actualización |

---

### 2.8 student (Estudiante)

**Descripción:** Almacena la información completa de los estudiantes.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique student identifier | Identificador único del estudiante |
| user_id | UUID | Reference to app_user | Referencia al usuario |
| enrollment_number | VARCHAR(20) | Unique enrollment number | Número de inscripción único |
| curp | VARCHAR(18) | CURP (Unique Mexican ID) | CURP (Identificador único mexicano) |
| first_name | VARCHAR(100) | First name | Nombre(s) |
| last_name | VARCHAR(100) | Last name | Apellido(s) |
| institutional_email | VARCHAR(150) | Institutional email | Correo institucional |
| secondary_email | VARCHAR(150) | Secondary email | Correo secundario |
| phone | VARCHAR(20) | Primary phone | Teléfono principal |
| secondary_phone | VARCHAR(20) | Secondary phone | Teléfono secundario |
| birth_date | DATE | Date of birth | Fecha de nacimiento |
| gender | CHAR(1) | Gender (M/F/O) | Género (M/F/O) |
| enrollment_date | DATE | Date of enrollment | Fecha de inscripción |
| graduation_date | DATE | Date of graduation | Fecha de graduación |
| marital_status | VARCHAR(20) | Marital status | Estado civil |
| birth_place | VARCHAR(200) | Birth place | Lugar de nacimiento |
| nationality | VARCHAR(50) | Nationality | Nacionalidad |
| address_street | VARCHAR(200) | Street address | Calle |
| address_colony | VARCHAR(100) | Colony/neighborhood | Colonia |
| address_municipality | VARCHAR(100) | Municipality | Municipio |
| address_state | VARCHAR(100) | State | Estado |
| address_zip_code | VARCHAR(10) | ZIP code | Código postal |
| blood_type | VARCHAR(5) | Blood type | Tipo de sangre |
| previous_school | TEXT | Previous school | Escuela anterior |
| photo_url | TEXT | Photo URL | URL de foto |
| observations | TEXT | Observations | Observaciones |
| has_scholarship | BOOLEAN | Has scholarship | Tiene beca |
| scholarship_type | VARCHAR(50) | Scholarship type | Tipo de beca |
| generation_id | UUID | Reference to generation | Referencia a la generación |
| is_active | BOOLEAN | Whether student is active | Si el estudiante está activo |
| is_deleted | BOOLEAN | Soft delete flag | Bandera de eliminación suave |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |
| updated_at | TIMESTAMPTZ | Last update timestamp | Fecha de última actualización |

---

### 2.9 enrollment (Inscripción)

**Descripción:** Representa la inscripción de un estudiante en un curso durante un período académico. El profesor se obtiene a través del group_id -> academic_group -> teacher_id.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique enrollment identifier | Identificador único de la inscripción |
| student_id | UUID | Reference to student | Referencia al estudiante |
| course_id | UUID | Reference to course | Referencia al curso |
| academic_period_id | UUID | Reference to academic_period | Referencia al período académico |
| group_id | UUID | Reference to academic_group | Referencia al grupo académico |
| status | VARCHAR(30) | Enrollment status | Estado de la inscripción |
| is_active | BOOLEAN | Whether enrollment is active | Si la inscripción está activa |
| is_deleted | BOOLEAN | Soft delete flag | Bandera de eliminación suave |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |
| updated_at | TIMESTAMPTZ | Last update timestamp | Fecha de última actualización |

**Estados posibles:**
- **ENROLLED** - Inscrito
- **APPROVED** - Aprobado
- **FAILED** - Reprobado
- **WITHDRAWN** - Retirado

---

### 2.10 evaluation_type (Tipo de Evaluación)

**Descripción:** Define los tipos de evaluación de un curso (parciales, proyectos, exámenes, etc.).

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique evaluation type identifier | Identificador único del tipo de evaluación |
| course_id | UUID | Reference to course | Referencia al curso |
| code | VARCHAR(20) | Evaluation type code | Código del tipo de evaluación |
| name | VARCHAR(50) | Evaluation type name | Nombre del tipo de evaluación |
| weight | NUMERIC(5,2) | Weight percentage (0-100) | Porcentaje de peso (0-100) |
| is_active | BOOLEAN | Whether evaluation type is active | Si el tipo de evaluación está activo |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |

**Ejemplos:**
- **P1** - Primer Parcial (25%)
- **P2** - Segundo Parcial (25%)
- **PROY** - Proyecto (30%)
- **PART** - Participación (20%)
- **EXAM** - Examen Final

---

### 2.11 grade (Calificación)

**Descripción:** Almacena las calificaciones de un estudiante en cada tipo de evaluación.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique grade identifier | Identificador único de la calificación |
| enrollment_id | UUID | Reference to enrollment | Referencia a la inscripción |
| evaluation_type_id | UUID | Reference to evaluation_type | Referencia al tipo de evaluación |
| score | NUMERIC(5,2) | Score (0-100) | Puntuación (0-100) |
| recorded_by | UUID | User who recorded the grade | Usuario que registró la calificación |
| recorded_at | TIMESTAMPTZ | Recording timestamp | Fecha de registro |

---

## 3. MÓDULO KARDEX

### 3.1 kardex (Kardex)

**Descripción:** Es el historial académico oficial de un estudiante. Registra cada materia cursada con su resultado final. El profesor se obtiene a través de enrollment -> group_id -> academic_group -> teacher_id.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique kardex identifier | Identificador único del kardex |
| student_id | UUID | Reference to student | Referencia al estudiante |
| course_id | UUID | Reference to course | Referencia al curso |
| academic_semester_id | UUID | Reference to academic_semester | Referencia al semestre académico |
| enrollment_id | UUID | Reference to enrollment | Referencia a la inscripción |
| final_grade | NUMERIC(5,2) | Final grade (0-100) | Calificación final (0-100) |
| letter_grade | VARCHAR(2) | Letter grade (A, B, C, D, F) | Calificación con letra |
| status | VARCHAR(20) | Kardex status | Estado del kardex |
| attempt_number | INTEGER | Attempt number | Número de intento |
| enrollment_date | DATE | Enrollment date | Fecha de inscripción |
| approval_date | DATE | Approval date | Fecha de aprobación |
| registration_date | TIMESTAMPTZ | Registration timestamp | Fecha de registro |
| official_folio | VARCHAR(30) | Official folio number | Número de folio oficial |
| kardex_folio | VARCHAR(30) | Kardex folio | Folio del kardex |
| kardex_sequence | INTEGER | Kardex sequence number | Número de secuencia del kardex |
| is_officialized | BOOLEAN | Is official | Es oficial |
| officialization_date | TIMESTAMPTZ | Officialization date | Fecha de oficialización |
| officialized_by | UUID | User who officialized | Usuario que oficializó |
| observations | TEXT | Observations | Observaciones |
| is_deleted | BOOLEAN | Soft delete flag | Bandera de eliminación suave |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |
| updated_at | TIMESTAMPTZ | Last update timestamp | Fecha de última actualización |

**Estados posibles:**
- **ENROLLED** - Inscrito
- **APPROVED** - Aprobado
- **FAILED** - Reprobado
- **EXTRAORDINARY** - Extraordinario
- **DROPPED** - Dado de baja
- **VALIDATED** - Validado
- **EQUIVALENCE** - Equivalencia

**Conversión de calificaciones:**
- **A** = 90-100 (Excelente)
- **B** = 80-89 (Bueno)
- **C** = 70-79 (Regular)
- **D** = 60-69 (Suficiente)
- **F** = 0-59 (Insuficiente)

---

## 4. MÓDULO DE BOLETAS (REPORT CARDS)

### 4.1 report_card (Boleta de Calificaciones)

**Descripción:** Documento que resume las calificaciones de un estudiante en un semestre específico.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique report card identifier | Identificador único de la boleta |
| student_id | UUID | Referencia al estudiante Reference to student | |
| academic_semester_id | UUID | Reference to academic_semester | Referencia al semestre académico |
| generation_id | UUID | Reference to generation | Referencia a la generación |
| report_card_type | VARCHAR(30) | Type of report card | Tipo de boleta |
| generation_mode | VARCHAR(20) | ONLINE (estudiante) vs OFFICIAL (oficial) | Modo de generación: EN_LÍNEA (estudiante) vs OFICIAL |
| overall_average | NUMERIC(5,2) | Overall average (0-100) | Promedio general (0-100) |
| average_letter | VARCHAR(2) | Letter average | Promedio con letra |
| attendance_average | NUMERIC(5,2) | Attendance average | Promedio de asistencia |
| total_credits_enrolled | INTEGER | Total credits enrolled | Total de créditos inscritos |
| total_credits_approved | INTEGER | Total credits approved | Total de créditos aprobados |
| total_subjects | INTEGER | Total subjects | Total de materias |
| total_subjects_approved | INTEGER | Total subjects approved | Total de materias aprobadas |
| status | VARCHAR(20) | Report card status | Estado de la boleta |
| issue_date | DATE | Issue date | Fecha de emisión |
| delivery_date | DATE | Delivery date | Fecha de entrega |
| origin_semester_id | UUID | Origin semester | Semestre de origen |
| destination_semester_id | UUID | Destination semester | Semestre de destino |
| folio | VARCHAR(30) | Unique folio | Folio único |
| series | VARCHAR(20) | Series | Serie |
| observations | TEXT | Observations | Observaciones |
| is_signed | BOOLEAN | Is signed | Está firmada |
| signed_by | UUID | User who signed | Usuario que firmó |
| signed_at | TIMESTAMPTZ | Signing timestamp | Fecha de firma |
| signed_seal_url | TEXT | URL of seal image | URL de imagen del sello |
| is_deleted | BOOLEAN | Soft delete flag | Bandera de eliminación suave |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |
| updated_at | TIMESTAMPTZ | Last update timestamp | Fecha de última actualización |

**Tipos de boleta:**
- **ORDINARY** - Ordinaria
- **EXTRAORDINARY** - Extraordinaria
- **SPECIAL** - Especial
- **PARTIAL_CERTIFICATE** - Certificado parcial
- **FINAL_CERTIFICATE** - Certificado final

**Modo de generación:**
- **ONLINE** - Boleta vista por el estudiante en su portal (sin firma ni sello)
- **OFFICIAL** - Boleta oficial generada por control escolar (con firma y sello)

**Estados posibles:**
- **PENDING** - Pendiente de generar
- **ISSUED** - Emitida
- **DELIVERED** - Entregada
- **ARCHIVED** - Archivada
- **CANCELLED** - Cancelada

---

### 4.2 report_card_detail (Detalle de Boleta)

**Descripción:** Detalle de cada materia en la boleta.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique detail identifier | Identificador único del detalle |
| report_card_id | UUID | Reference to report_card | Referencia a la boleta |
| kardex_id | UUID | Reference to kardex | Referencia al kardex |
| course_id | UUID | Reference to course | Referencia al curso |
| subject_name | VARCHAR(150) | Subject name | Nombre de la materia |
| subject_code | VARCHAR(20) | Subject code | Código de la materia |
| credits | INTEGER | Credits | Créditos |
| grade | NUMERIC(5,2) | Grade (0-100) | Calificación (0-100) |
| grade_letter | VARCHAR(2) | Letter grade | Calificación con letra |
| subject_status | VARCHAR(20) | Subject status | Estado de la materia |
| attendance_percentage | NUMERIC(5,2) | Attendance percentage | Porcentaje de asistencia |
| total_attendances | INTEGER | Total attendances | Total de asistencia |
| classes_attended | INTEGER | Classes attended | Clases asistidas |
| observations | TEXT | Observations | Observaciones |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |

---

## 5. MÓDULO DE ASISTENCIA

### 5.1 attendance (Asistencia - Diaria)

**Descripción:** Registro diario de asistencia de cada estudiante a clase.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique attendance identifier | Identificador único de la asistencia |
| enrollment_id | UUID | Reference to enrollment | Referencia a la inscripción |
| attendance_date | DATE | Date of attendance | Fecha de asistencia |
| status | VARCHAR(20) | Attendance status | Estado de asistencia |
| class_time | VARCHAR(10) | Class time | Hora de clase |
| subject_code | VARCHAR(20) | Subject code | Código de la materia |
| observations | TEXT | Observations | Observaciones |
| justified_by | UUID | User who justified | Usuario que justificó |
| justification_date | TIMESTAMPTZ | Justification date | Fecha de justificación |
| recorded_by | UUID | User who recorded | Usuario que registró |
| recorded_at | TIMESTAMPTZ | Recording timestamp | Fecha de registro |

**Estados posibles:**
- **PRESENT** - Presente
- **ABSENT** - Ausente
- **JUSTIFIED** - Justificado
- **LATE** - Tarde

---

### 5.2 attendance_period (Período de Asistencia)

**Descripción:** Resumen de asistencia de un estudiante en un período (semestre).

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique attendance period identifier | Identificador único del período de asistencia |
| enrollment_id | UUID | Reference to enrollment | Referencia a la inscripción |
| academic_semester_id | UUID | Reference to academic_semester | Referencia al semestre académico |
| total_classes | INTEGER | Total classes | Total de clases |
| total_present | INTEGER | Total present | Total de presentes |
| total_absent | INTEGER | Total absent | Total de ausentes |
| total_justified | INTEGER | Total justified | Total de justificados |
| total_late | INTEGER | Total late | Total de tardanzas |
| attendance_percentage | NUMERIC(5,2) | Attendance percentage | Porcentaje de asistencia |
| attendance_status | VARCHAR(20) | Attendance status | Estado de asistencia |
| observations | TEXT | Observations | Observaciones |
| updated_at | TIMESTAMPTZ | Last update timestamp | Fecha de última actualización |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |

**Estados de asistencia:**
- **IN_RANGE** - Dentro del rango
- **AT_RISK** - En riesgo (60-79%)
- **INSUFFICIENT** - Insuficiente (<60%)

---

## 6. MÓDULO DE CONDUCTA

### 6.1 conduct (Conducta)

**Descripción:** Evalúa la conducta de un estudiante en un período académico.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique conduct identifier | Identificador único de la conducta |
| enrollment_id | UUID | Reference to enrollment | Referencia a la inscripción |
| academic_semester_id | UUID | Reference to academic_semester | Referencia al semestre académico |
| grade | VARCHAR(2) | Conduct grade | Calificación de conducta |
| observations | TEXT | Observations | Observaciones |
| warnings | INTEGER | Number of warnings | Número de amonestaciones |
| congratulations | INTEGER | Number of congratulations | Número de felicitaciones |
| registration_date | TIMESTAMPTZ | Registration timestamp | Fecha de registro |
| recorded_by | UUID | User who recorded | Usuario que registró |
| updated_at | TIMESTAMPTZ | Last update timestamp | Fecha de última actualización |

---

### 6.2 conduct_incident (Incidente de Conducta)

**Descripción:** Registra incidentes específicos de conducta.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique incident identifier | Identificador único del incidente |
| enrollment_id | UUID | Reference to enrollment | Referencia a la inscripción |
| incident_type | VARCHAR(50) | Type of incident | Tipo de incidente |
| description | TEXT | Incident description | Descripción del incidente |
| incident_date | DATE | Date of incident | Fecha del incidente |
| severity | VARCHAR(20) | Severity level | Nivel de severidad |
| actions_taken | TEXT | Actions taken | Acciones tomadas |
| attention_date | DATE | Date attention was given | Fecha de atención |
| recorded_by | UUID | User who recorded | Usuario que registró |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |

**Tipos de incidente:**
- **WARNING** - Amonestación
- **CONGRATULATION** - FelicitaciÃ³n
- **CALL_ATTENTION** - Llamada de atención
- **SUSPENSION** - Suspensión
- **OTHER** - Otro

**Niveles de severidad:**
- **MINOR** - Menor
- **MODERATE** - Moderado
- **SERIOUS** - Grave

---

## 7. MÓDULO DE EXÁMENES EXTRAORDINARIOS

### 7.1 extraordinary_exam (Examen Extraordinario)

**Descripción:** Gestiona los exámenes extraordinarios para materias no aprobadas.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique exam identifier | Identificador único del examen |
| student_id | UUID | Reference to student | Referencia al estudiante |
| course_id | UUID | Reference to course | Referencia al curso |
| academic_semester_id | UUID | Reference to academic_semester | Referencia al semestre académico |
| attempt_number | INTEGER | Attempt number | Número de intento |
| status | VARCHAR(20) | Exam status | Estado del examen |
| scheduled_date | DATE | Scheduled date | Fecha programada |
| application_date | DATE | Application date | Fecha de aplicación |
| application_time | VARCHAR(10) | Application time | Hora de aplicación |
| application_location | VARCHAR(100) | Application location | Lugar de aplicación |
| previous_grade | NUMERIC(5,2) | Previous grade | Calificación anterior |
| grade | NUMERIC(5,2) | Exam grade | Calificación del examen |
| grade_letter | VARCHAR(2) | Letter grade | Calificación con letra |
| examiner_id | UUID | Reference to teacher (examiner) | Referencia al profesor (examinador) |
| observation | TEXT | Observation | Observación |
| cost | DECIMAL(10,2) | Exam cost | Costo del examen |
| payment_receipt | VARCHAR(100) | Payment receipt | Recibo de pago |
| payment_folio | VARCHAR(50) | Payment folio | Folio de pago |
| is_deleted | BOOLEAN | Soft delete flag | Bandera de eliminación suave |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |
| updated_at | TIMESTAMPTZ | Last update timestamp | Fecha de última actualización |

**Estados posibles:**
- **SCHEDULED** - Programado
- **APPLIED** - Aplicado
- **APPROVED** - Aprobado
- **FAILED** - Reprobado
- **CANCELLED** - Cancelado
- **NO_SHOW** - No se presentó

---

### 7.2 retake_exam (Examen de Repetición)

**Descripción:** Gestiona los exámenes de repetición (recursamiento).

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique retake exam identifier | Identificador único del examen de repetición |
| student_id | UUID | Reference to student | Referencia al estudiante |
| course_id | UUID | Reference to course | Referencia al curso |
| academic_semester_id | UUID | Reference to academic_semester | Referencia al semestre académico |
| origin_semester_id | UUID | Origin semester | Semestre de origen |
| previous_average | NUMERIC(5,2) | Previous average | Promedio anterior |
| status | VARCHAR(20) | Retake status | Estado de la repetición |
| is_deleted | BOOLEAN | Soft delete flag | Bandera de eliminación suave |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |
| updated_at | TIMESTAMPTZ | Last update timestamp | Fecha de última actualización |

---

## 8. MÓDULO DE CERTIFICADOS

### 8.1 certificate (Certificado)

**Descripción:** Gestiona los certificados académicos de los estudiantes.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique certificate identifier | Identificador único del certificado |
| student_id | UUID | Reference to student | Referencia al estudiante |
| generation_id | UUID | Reference to generation | Referencia a la generación |
| certificate_type | VARCHAR(50) | Type of certificate | Tipo de certificado |
| official_folio | VARCHAR(50) | Official folio | Folio oficial |
| internal_folio | VARCHAR(50) | Internal folio | Folio interno |
| series | VARCHAR(20) | Series | Serie |
| final_average | NUMERIC(5,2) | Final average | Promedio final |
| total_credits | INTEGER | Total credits | Total de créditos |
| total_subjects | INTEGER | Total subjects | Total de materias |
| issue_date | DATE | Issue date | Fecha de emisión |
| delivery_date | DATE | Delivery date | Fecha de entrega |
| status | VARCHAR(20) | Certificate status | Estado del certificado |
| director_signer | UUID | Director signer | Firma del director |
| secretary_signer | UUID | Secretary signer | Firma del secretario |
| record_number | VARCHAR(30) | Record number | Número de registro |
| record_book | VARCHAR(20) | Record book | Libro de registro |
| record_page | VARCHAR(20) | Record page | Página de registro |
| observations | TEXT | Observations | Observaciones |
| is_deleted | BOOLEAN | Soft delete flag | Bandera de eliminación suave |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |
| updated_at | TIMESTAMPTZ | Last update timestamp | Fecha de última actualización |

**Tipos de certificado:**
- **PARTIAL** - Parcial
- **TOTAL** - Total
- **TITLE** - Título
- **DIPLOMA** - Diploma
- **CONSTANCIA** - Constancia

**Estados posibles:**
- **REQUESTED** - Solicitado
- **IN_PROCESS** - En proceso
- **ISSUED** - Emitido
- **DELIVERED** - Entregado
- **CANCELLED** - Cancelado

---

## 9. MÓDULO DE TUTORES (GUARDIANS)

### 9.1 guardian (Tutor)

**Descripción:** Almacena la información de los tutores o padres de familia de los estudiantes.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique guardian identifier | Identificador único del tutor |
| student_id | UUID | Reference to student | Referencia al estudiante |
| full_name | VARCHAR(200) | Full name | Nombre completo |
| relationship | VARCHAR(50) | Relationship to student | Relación con el estudiante |
| curp | VARCHAR(18) | CURP | CURP |
| primary_phone | VARCHAR(20) | Primary phone | Teléfono principal |
| secondary_phone | VARCHAR(20) | Secondary phone | Teléfono secundario |
| email | VARCHAR(150) | Email | Correo electrónico |
| occupation | VARCHAR(100) | Occupation | Ocupación |
| company | VARCHAR(150) | Company | Empresa |
| address | TEXT | Address | Dirección |
| is_emergency_contact | BOOLEAN | Is emergency contact | Es contacto de emergencia |
| is_active | BOOLEAN | Whether guardian is active | Si el tutor está activo |
| is_deleted | BOOLEAN | Soft delete flag | Bandera de eliminación suave |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |
| updated_at | TIMESTAMPTZ | Last update timestamp | Fecha de última actualización |

**Tipos de relación:**
- **FATHER** - Padre
- **MOTHER** - Madre
- **GUARDIAN** - Tutor
- **SIBLING** - Hermano/a
- **OTHER** - Otro

---

## 10. MÓDULO DE DOCUMENTOS

### 10.1 student_document (Documento del Estudiante)

**Descripción:** Gestiona los documentos subidos por los estudiantes (CURP, INE, fotos, etc.).

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique document identifier | Identificador único del documento |
| student_id | UUID | Reference to student | Referencia al estudiante |
| document_type | VARCHAR(50) | Type of document | Tipo de documento |
| original_name | VARCHAR(200) | Original file name | Nombre original del archivo |
| file_name | VARCHAR(200) | Stored file name | Nombre del archivo guardado |
| file_path | TEXT | File path | Ruta del archivo |
| file_size_bytes | BIGINT | File size in bytes | Tamaño del archivo en bytes |
| mime_type | VARCHAR(100) | MIME type | Tipo MIME |
| document_number | VARCHAR(50) | Document number | Número de documento |
| issue_date | DATE | Issue date | Fecha de emisión |
| expiration_date | DATE | Expiration date | Fecha de expiración |
| is_verified | BOOLEAN | Is verified | Está verificado |
| verified_by | UUID | User who verified | Usuario que verificó |
| verification_date | TIMESTAMPTZ | Verification date | Fecha de verificación |
| observations | TEXT | Observations | Observaciones |
| is_active | BOOLEAN | Whether document is active | Si el documento está activo |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |
| updated_at | TIMESTAMPTZ | Last update timestamp | Fecha de última actualización |

**Tipos de documento:**
- **CURP** - CURP
- **BIRTH_CERTIFICATE** - Acta de nacimiento
- **PHOTO** - Foto
- **HIGH_SCHOOL_CERTIFICATE** - Certificado de secundaria
- **HIGH_SCHOOL_KARDEX** - Kardex de secundaria
- **IDENTIFICATION** - Identificación
- **PROOF_OF_ADDRESS** - Comprobante de domicilio
- **PAYMENT** - Pago
- **OTHER** - Otro

---

## 11. MÓDULO DE CONFIGURACIÓN

### 11.1 system_configuration (Configuración del Sistema)

**Descripción:** Almacena la configuración global del sistema.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique configuration identifier | Identificador único de la configuración |
| config_key | VARCHAR(50) | Configuration key | Clave de configuración |
| config_value | TEXT | Configuration value | Valor de configuración |
| description | TEXT | Configuration description | Descripción de la configuración |
| data_type | VARCHAR(20) | Data type | Tipo de dato |
| module | VARCHAR(50) | Module | Módulo |
| is_active | BOOLEAN | Whether configuration is active | Si la configuración está activa |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |
| updated_at | TIMESTAMPTZ | Last update timestamp | Fecha de última actualización |

**Tipos de datos:**
- **STRING** - Texto
- **NUMBER** - Número
- **BOOLEAN** - Booleano
- **JSON** - JSON

---

## 12. MÓDULO DEL PORTAL PÚBLICO

### 12.1 institution (Institución)

**Descripción:** Información de la institución educativa.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique institution identifier | Identificador único de la institución |
| name | VARCHAR(200) | Institution name | Nombre de la institución |
| address | TEXT | Address | Dirección |
| phone | VARCHAR(20) | Phone | Teléfono |
| email | VARCHAR(150) | Email | Correo electrónico |
| website | VARCHAR(200) | Website | Sitio web |
| mission | TEXT | Mission | Misión |
| vision | TEXT | Vision | Visión |
| history | TEXT | History | Historia |
| values | TEXT | Values | Valores |
| logo_url | TEXT | Logo URL | URL del logotipo |
| is_active | BOOLEAN | Whether institution is active | Si la institución está activa |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |

---

### 12.2 news (Noticias)

**Descripción:** Noticias publicadas en el portal público.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique news identifier | Identificador único de la noticia |
| title | VARCHAR(200) | News title | Título de la noticia |
| content | TEXT | News content | Contenido de la noticia |
| image_url | TEXT | Image URL | URL de la imagen |
| is_published | BOOLEAN | Is published | Está publicada |
| is_deleted | BOOLEAN | Soft delete flag | Bandera de eliminación suave |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |
| updated_at | TIMESTAMPTZ | Last update timestamp | Fecha de última actualización |

---

### 12.3 event (Evento)

**Descripción:** Eventos del portal público.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique event identifier | Identificador único del evento |
| title | VARCHAR(200) | Event title | Título del evento |
| description | TEXT | Event description | Descripción del evento |
| event_date | DATE | Event date | Fecha del evento |
| location | VARCHAR(200) | Event location | Lugar del evento |
| is_published | BOOLEAN | Is published | Está publicado |
| is_deleted | BOOLEAN | Soft delete flag | Bandera de eliminación suave |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |
| updated_at | TIMESTAMPTZ | Last update timestamp | Fecha de última actualización |

---

### 12.4 portal_advertisement (Publicidad del Portal)

**Descripción:** Anuncios y banners del portal público.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique advertisement identifier | Identificador único del anuncio |
| title | VARCHAR(200) | Advertisement title | Título del anuncio |
| description | TEXT | Advertisement description | Descripción del anuncio |
| image_url | TEXT | Image URL | URL de la imagen |
| link_url | VARCHAR(500) | Link URL | URL del enlace |
| position | VARCHAR(20) | Position on page | Posición en la página |
| display_order | INTEGER | Display order | Orden de visualización |
| is_published | BOOLEAN | Is published | Está publicado |
| start_date | DATE | Start date | Fecha de inicio |
| end_date | DATE | End date | Fecha de fin |
| is_deleted | BOOLEAN | Soft delete flag | Bandera de eliminación suave |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |
| updated_at | TIMESTAMPTZ | Last update timestamp | Fecha de última actualización |

**Posiciones:**
- **BANNER** - Banner principal
- **SIDEBAR** - Barra lateral
- **FOOTER** - Pie de página

---

### 12.5 portal_contact (Contacto del Portal)

**Descripción:** Mensajes de contacto enviados desde el portal público.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique contact message identifier | Identificador único del mensaje |
| full_name | VARCHAR(150) | Full name | Nombre completo |
| email | VARCHAR(150) | Email | Correo electrónico |
| phone | VARCHAR(20) | Phone | Teléfono |
| subject | VARCHAR(200) | Subject | Asunto |
| message | TEXT | Message | Mensaje |
| is_read | BOOLEAN | Is read | Ha sido leído |
| is_responded | BOOLEAN | Is responded | Ha sido respondido |
| response | TEXT | Response | Respuesta |
| response_date | TIMESTAMPTZ | Response date | Fecha de respuesta |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |

---

### 12.6 educational_resource (Recurso Educativo)

**Descripción:** Recursos educativos publicados en el portal.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique resource identifier | Identificador único del recurso |
| title | VARCHAR(200) | Resource title | Título del recurso |
| description | TEXT | Resource description | Descripción del recurso |
| resource_type | VARCHAR(50) | Resource type | Tipo de recurso |
| resource_url | TEXT | Resource URL | URL del recurso |
| course_id | UUID | Reference to course | Referencia al curso |
| is_published | BOOLEAN | Is published | Está publicado |
| is_deleted | BOOLEAN | Soft delete flag | Bandera de eliminación suave |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |
| updated_at | TIMESTAMPTZ | Last update timestamp | Fecha de última actualización |

**Tipos de recurso:**
- **PDF** - Documento PDF
- **VIDEO** - Video
- **LINK** - Enlace
- **DOCUMENT** - Documento
- **PRESENTATION** - Presentación

---

## 13. MÓDULO DE AUDITORÍA

### 13.1 access_audit (Auditoría de Accesos)

**Descripción:** Registra todos los accesos y acciones de los usuarios en el sistema.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| id | UUID | Unique audit entry identifier | Identificador único de la entrada de auditoría |
| user_id | UUID | Reference to app_user | Referencia al usuario |
| action | VARCHAR(100) | Action performed | Acción realizada |
| module | VARCHAR(100) | Module where action occurred | Módulo donde ocurrió la acción |
| ip_address | VARCHAR(45) | IP address | Dirección IP |
| success | BOOLEAN | Whether action was successful | Si la acción fue exitosa |
| metadata | JSONB | Additional metadata | Metadatos adicionales |
| created_at | TIMESTAMPTZ | Creation timestamp | Fecha de creación |

---

## 14. TABLAS DE RELACIONES

### 14.1 user_role (Usuario-Rol)

**Descripción:** Relación muchos a muchos entre usuarios y roles.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| user_id | UUID | Reference to app_user | Referencia al usuario |
| role_id | UUID | Reference to role | Referencia al rol |

---

### 14.2 role_permission (Rol-Permiso)

**Descripción:** Relación muchos a muchos entre roles y permisos.

| Campo | Tipo | Descripción | Descripción en Español |
|-------|------|--------------|----------------------|
| role_id | UUID | Reference to role | Referencia al rol |
| permission_id | UUID | Reference to permission | Referencia al permiso |

---

## FUNCIONES Y PROCEDIMIENTOS IMPORTANTES

### fn_set_updated_at()
Función genérica que actualiza automáticamente el campo `updated_at` cuando se modifica un registro.

### fn_validate_course_weight()
Valida que la suma de los pesos de evaluación de un curso no exceda el 100%.

### fn_generate_enrollment_number(p_year)
Genera números de inscripción en formato: `ENE-YYYY-NNNN`

### fn_generate_employee_number(p_year)
Genera números de empleado en formato: `EMP-YYYY-NNNN`

### fn_generate_course_code(p_prefix, p_semester)
Genera códigos de curso en formato: `XXNNN` (2 letras + 3 dígitos)

### fn_generate_kardex_folio()
Genera folios de kardex en formato: `KX-YYYYMMDD-NNNN`

### fn_generate_report_card_folio(p_year)
Genera folios de boleta en formato: `RC-YYYY-NNNN`

### fn_generate_certificate_folio(p_year)
Genera folios de certificado en formato: `CERT-YYYY-NNNN`

### sp_enroll_student()
Procedimiento para inscribir a un estudiante en un curso.

### fn_grade_to_letter()
Convierte calificaciones numéricas a letras:
- A = 90-100
- B = 80-89
- C = 70-79
- D = 60-69
- F = 0-59

### fn_calculate_kardex_average()
Calcula el promedio del kardex de un estudiante.

### sp_generate_report_card()
Genera automáticamente una boleta de calificaciones.

### sp_close_academic_semester()
Cierra un semestre académico y calcula los promedios finales.

---

## VISTAS IMPORTANTES

### v_kardex_oficial
Vista del kardex oficial de estudiantes.

### v_resumen_academico
Resumen académico por estudiante (total de materias, promedio, créditos).

### v_boletas_periodo
Boletas emitidas por período.

### v_asistencia_concentrado
Concentrado de asistencia por estudiante.

### v_extraordinarios_estudiante
Exámenes extraordinarios por estudiante.

### v_student_transcript
Transcripción de calificaciones del estudiante.

### v_student_gpa
Promedio general del estudiante.

### v_course_approval_rate
Tasa de aprobación por curso.

### v_teacher_performance
Rendimiento de profesores.

---

## GLOSARIO DE TÉRMINOS

| Término | Definición |
|---------|------------|
| **Soft Delete** | Eliminación lógica que marca registros como eliminados sin borrarlos físicamente |
| **UUID** | Identificador único universal (formato: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx) |
| **TIMESTAMPTZ** | Fecha y hora con zona horaria |
| **Kardex** | Historial académico oficial de un estudiante |
| **Boleta** | Documento con calificaciones de un período específico |
| **CURP** | Clave Única de Registro de Población (identificador mexicano) |
| **Creditos** | Unidades de valor que representan el trabajo académico requerido |
| **JWT** | JSON Web Token (estándar para autenticación) |

---

*Documento generado automáticamente para el Sistema Académico - Escuela Normal Emiliano Zapata*
