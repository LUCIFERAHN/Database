CREATE DATABASE LanguageAcademy;
GO

USE LanguageAcademy;
GO

-- جدول دانش‌آموزان
CREATE TABLE Students (
    StudentID INT IDENTITY PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    DateOfBirth DATE NOT NULL,
    Email NVARCHAR(100) UNIQUE,
    Phone NVARCHAR(15),
    RegistrationDate DATE DEFAULT GETDATE()
);

-- جدول مدرسان
CREATE TABLE  Teachers (
    TeacherID INT IDENTITY PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) UNIQUE,
    Phone NVARCHAR(15),
    HireDate DATE DEFAULT GETDATE()
);

-- جدول دوره‌ها
CREATE TABLE Courses (
    CourseID INT IDENTITY PRIMARY KEY,
    CourseName NVARCHAR(100) NOT NULL,
    Language NVARCHAR(50) NOT NULL,
    Level NVARCHAR(50),
    DurationWeeks INT NOT NULL,
    Fee DECIMAL(10, 2) NOT NULL,
    TeacherID INT NOT NULL FOREIGN KEY REFERENCES Instructors(TeacherID)
);

-- جدول ثبت‌نام
CREATE TABLE Enrollments (
    EnrollmentID INT IDENTITY PRIMARY KEY,
    StudentID INT NOT NULL FOREIGN KEY REFERENCES Students(StudentID),
    CourseID INT NOT NULL FOREIGN KEY REFERENCES Courses(CourseID),
    EnrollmentDate DATE DEFAULT GETDATE(),
    Status NVARCHAR(20) DEFAULT 'Active'
);

-- جدول برنامه کلاس‌ها
CREATE TABLE ClassSchedules (
    ScheduleID INT IDENTITY PRIMARY KEY,
    CourseID INT NOT NULL FOREIGN KEY REFERENCES Courses(CourseID),
    ClassDate DATE NOT NULL,
    StartTime TIME NOT NULL,
    EndTime TIME NOT NULL,
    Room NVARCHAR(20)
);

-- جدول پرداخت‌ها
CREATE TABLE Payments (
    PaymentID INT IDENTITY PRIMARY KEY,
    StudentID INT NOT NULL FOREIGN KEY REFERENCES Students(StudentID),
    PaymentDate DATE DEFAULT GETDATE(),
    Amount DECIMAL(10, 2) NOT NULL,
    PaymentMethod NVARCHAR(50),
    Notes NVARCHAR(200)
);

CREATE TABLE Attendance (
    AttendanceID INT IDENTITY PRIMARY KEY,
    ScheduleID INT NOT NULL FOREIGN KEY REFERENCES ClassSchedules(ScheduleID),
    StudentID INT NOT NULL FOREIGN KEY REFERENCES Students(StudentID),
    AttendanceDate DATE NOT NULL,
    Status NVARCHAR(20) DEFAULT 'Present', -- 'Present', 'Absent', 'Excused'
    Notes NVARCHAR(200)
);

CREATE TABLE Feedback (
    FeedbackID INT IDENTITY PRIMARY KEY,
    CourseID INT NOT NULL FOREIGN KEY REFERENCES Courses(CourseID),
    StudentID INT NOT NULL FOREIGN KEY REFERENCES Students(StudentID),
    FeedbackDate DATE DEFAULT GETDATE(),
    Rating INT CHECK (Rating BETWEEN 1 AND 5), -- امتیاز 1 تا 5
    Comments NVARCHAR(500)
);

CREATE TABLE Exams (
    ExamID INT IDENTITY PRIMARY KEY,
    CourseID INT NOT NULL FOREIGN KEY REFERENCES Courses(CourseID),
    ExamName NVARCHAR(100) NOT NULL,
    ExamDate DATE NOT NULL,
    TotalMarks INT NOT NULL
);

-- جدول ثبت نمرات دانش‌آموزان
CREATE TABLE ExamResults (
    ResultID INT IDENTITY PRIMARY KEY,
    ExamID INT NOT NULL FOREIGN KEY REFERENCES Exams(ExamID),
    StudentID INT NOT NULL FOREIGN KEY REFERENCES Students(StudentID),
    ObtainedMarks INT CHECK (ObtainedMarks >= 0),
    Comments NVARCHAR(200)
);


CREATE TABLE Salaries (
    SalaryID INT IDENTITY PRIMARY KEY, -- شناسه حقوق
    TeacherID INT NOT NULL FOREIGN KEY REFERENCES Instructors(TeacherID), -- مدرس
    PaymentDate DATE DEFAULT GETDATE(), -- تاریخ پرداخت
    Amount DECIMAL(10, 2) NOT NULL, -- مبلغ پرداختی
    PaymentMethod NVARCHAR(50), -- روش پرداخت (مثلاً نقدی، حواله بانکی)
    Period NVARCHAR(20) NOT NULL, -- دوره پرداخت (مثلاً ماهانه یا هفتگی)
    Notes NVARCHAR(200) -- توضیحات اضافی
   
);

ALTER TABLE Salaries
ADD 
    BaseSalary DECIMAL(10, 2) NOT NULL, -- حقوق پایه
    OvertimePay DECIMAL(10, 2) DEFAULT 0, -- مبلغ اضافه‌کاری
    Deductions DECIMAL(10, 2) DEFAULT 0, -- کسر حقوق (مثل مالیات یا جرائم)
    FinalSalary AS (BaseSalary + OvertimePay - Deductions) PERSISTED; -- حقوق نهایی محاسبه‌شده


CREATE TABLE Overtime (
    OvertimeID INT IDENTITY PRIMARY KEY,
    TeacherID INT NOT NULL FOREIGN KEY REFERENCES Instructors(TeacherID),
    OvertimeDate DATE NOT NULL, -- تاریخ اضافه‌کاری
    HoursWorked DECIMAL(5, 2) NOT NULL, -- تعداد ساعت‌های اضافه‌کاری
    HourlyRate DECIMAL(10, 2) NOT NULL, -- نرخ هر ساعت
    OvertimePay AS (HoursWorked * HourlyRate) PERSISTED -- مبلغ اضافه‌کاری محاسبه‌شده
);


CREATE TABLE TeachingHours (
    TeachingID INT IDENTITY PRIMARY KEY,
    TeacherID INT NOT NULL FOREIGN KEY REFERENCES Instructors(TeacherID),
    ClassDate DATE NOT NULL,
    Hours DECIMAL(5, 2) NOT NULL, -- تعداد ساعت‌های تدریس‌شده
    HourlyRate DECIMAL(10, 2) NOT NULL, -- نرخ تدریس هر ساعت
    TotalPay AS (Hours * HourlyRate) PERSISTED -- مبلغ کل تدریس محاسبه‌شده
);


CREATE VIEW FullSalaryDetails AS
SELECT 
    S.SalaryID,
    I.FirstName + ' ' + I.LastName AS InstructorName,
    S.PaymentDate,
    S.BaseSalary,
    ISNULL(OT.TotalOvertimePay, 0) AS TotalOvertimePay,
    ISNULL(DT.TotalDeductions, 0) AS TotalDeductions,
    S.FinalSalary + ISNULL(OT.TotalOvertimePay, 0) - ISNULL(DT.TotalDeductions, 0) AS NetSalary,
    S.Notes
FROM Salaries S
JOIN Instructors I ON S.TeacherID = I.TeacherID
LEFT JOIN (
    SELECT TeacherID, SUM(OvertimePay) AS TotalOvertimePay
    FROM Overtime
    GROUP BY TeacherID
) OT ON S.TeacherID = OT.TeacherID
LEFT JOIN (
    SELECT TeacherID, SUM(Amount) AS TotalDeductions
    FROM SalaryDeductions
    GROUP BY TeacherID
) DT ON S.TeacherID = DT.TeacherID;


