create database communtiyy_issue;
use communtiyy_issue;
--admin table--
create table admin (
    admin_id int auto_increment, username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    role VARCHAR(20) DEFAULT 'staff' CHECK (role IN ('staff', 'supervisor', 'manager')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, CONSTRAINT pk_admin PRIMARY KEY (admin_id));

alter table admin add column gender varchar(20) not null;
alter table admin add constraint gender_admin check(gender = 'm' or gender = 'f');
desc admin;
--citizen table--
CREATE TABLE citizen (
    citizen_id int auto_increment, first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL, email VARCHAR(100) NOT NULL UNIQUE, phone_number VARCHAR(10),
    District VARCHAR(200), village VARCHAR(50) NOT NULL,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP, solution VARCHAR(200),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    CONSTRAINT pk_citizen PRIMARY KEY (citizen_id));
alter table citizen add column gender varchar(10);
alter table citizen drop column status;
alter table citizen add column status varchar(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended'));
alter table citizen drop column solution;
alter table citizen add constraint gender check(gender = 'm'or gender = 'f');
alter table citizen add constraint phone_number_length check (length(phone_number) = 10);
desc citizen;

--category table--
create table category (
    category_id int auto_increment, name varchar(50) not null UNIQUE, description varchar(300),department varchar(100),
    created_by int NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_category PRIMARY KEY (category_id), CONSTRAINT fk_category_admin FOREIGN KEY (created_by)
        REFERENCES admin(admin_id));
desc category;

--issue table--
create table issue (
    issue_id int auto_increment, category_id int NOT NULL, citizen_id int NOT NULL, title varchar(100) NOT NULL,
    description varchar(500) NOT NULL,created_by int NOT NULL,CONSTRAINT pk_issue PRIMARY KEY (issue_id),
    CONSTRAINT fk_issue_category FOREIGN KEY (category_id)
        REFERENCES category(category_id),
    CONSTRAINT fk_issue_admin FOREIGN KEY (created_by)
        REFERENCES admin(admin_id), constraint fk_issue_citizen FOREIGN KEY (citizen_id)
        REFERENCES citizen(citizen_id));
    desc issue;
--report table--
create table report (
    report_id int auto_increment, citizen_id int NOT NULL, issue_id int NOT NULL,
    description varchar(1000) NOT NULL,
    location varchar(200),
    status varchar(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'resolved', 'closed', 'rejected')),
    submitted_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_date TIMESTAMP,assigned_to int, satisfaction_rating int(1) CHECK (satisfaction_rating BETWEEN 1 AND 5),
    CONSTRAINT pk_report PRIMARY KEY (report_id), CONSTRAINT fk_report_citizen FOREIGN KEY (citizen_id)
        REFERENCES citizen(citizen_id),CONSTRAINT fk_report_issue FOREIGN KEY (issue_id)
        REFERENCES issue(issue_id),CONSTRAINT fk_report_admin FOREIGN KEY (assigned_to) REFERENCES admin(admin_id) ON DELETE SET NULL);
desc report;
--notification table--
CREATE TABLE notification (
    notification_id int auto_increment, recipient_type varchar(10) NOT NULL CHECK (recipient_type IN ('citizen', 'admin')),
    recipient_id int NOT NULL, report_id int, message varchar(500) NOT NULL,
    notification_type varchar(50) NOT NULL, is_read int(1) DEFAULT 0 CHECK (is_read IN (0, 1)),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, expiry_date TIMESTAMP, CONSTRAINT pk_notification PRIMARY KEY (notification_id),
    CONSTRAINT fk_notification_report FOREIGN KEY (report_id) REFERENCES report(report_id) ON DELETE CASCADE);
desc notification;

--inserting data--

insert into admin (username, email, full_name, role, gender) values
('Johaks', 'john@gmail.com', 'John Steven', 'staff','m'),
('Nicodem', 'paul@gmail.com', 'Nicholas Paul', 'supervisor','m'),
('Jonaims', 'jona@gmail.com', 'Jonathan', 'manager','m');
select * from admin;

insert into citizen (first_name, last_name, email, phone_number, district, village, gender) values
('Mary', 'Johnson', 'mary@gmail.com', '0781056854', 'Wakiso', 'kyebando','m'),
('James', 'Williams', 'james@gmail.com', '0774583728', 'Kampala', 'Bukoto','m'),
('Sarah', 'Brown', 'sarah@gmail.com', '0754576837', 'Kampala', 'Ntinda','m');
delete from citizen where citizen_id in (4,5,6);
select * from citizen;

INSERT INTO category (name, description, department, created_by) VALUES 
('Potholes', 'Road surface damage and potholes', 'Public Works', 1),
('Street Lights', 'Malfunctioning or broken street lights', 'Utilities', 1),
('Garbage Collection', 'Missed garbage pickups or overflowing bins', 'Sanitation', 2);
select * from category;

INSERT INTO issue (category_id, citizen_id, title, description, created_by) VALUES 
(1, 13, 'Large pothole on Main St', 'A dangerous pothole near the intersection of Main and 5th', 1),
(2, 14, 'Flickering street light', 'Light pole #42 flickers all night', 1),
(3, 13, 'Missed garbage pickup', 'Our recycling wasn''t picked up on Tuesday', 2);
select * from issue;

INSERT INTO report (citizen_id, issue_id, description, location, assigned_to) VALUES 
(14, 1, 'The pothole is getting bigger and damaging cars', 'Main St between 5th and 6th', 1),
(13, 2, 'The flickering light makes it hard to sleep', '123 Elm Street', 2),
(15, 3, 'Recycling bins overflowing after missed pickup', '456 Oak Avenue', 3);
update report set status = 'resolved' where report_id = 2;
select * from report;

--VIEWS--
--Active Issues by Category (Natural Join)--
create view active_issues_by_category AS
SELECT c.name AS category_name, COUNT(i.issue_id) AS issue_count
FROM category c
JOIN issue i ON c.category_id = i.category_id
JOIN report r ON i.issue_id = r.issue_id
WHERE r.status != 'closed' AND r.status != 'resolved'
GROUP BY c.name
ORDER BY issue_count DESC;

select * from active_issues_by_category;
-- 2. Citizen Reports with Status (Left Join)--
CREATE VIEW citizen_reports_with_status AS
SELECT 
    ci.first_name, 
    ci.last_name, 
    ci.email, 
    r.report_id, 
    r.description, 
    r.status, 
    r.submitted_date
FROM citizen ci
LEFT JOIN report r ON ci.citizen_id = r.citizen_id
ORDER BY r.submitted_date DESC;
select * from citizen_reports_with_status;

--citizen reports with status resolved--
create view citizen_reports_with_status_resolved as
select 
    ci.first_name, 
    ci.last_name, 
    ci.email, 
    r.report_id, 
    r.description, 
    r.status, 
    r.submitted_date
from citizen ci
left join report r on ci.citizen_id = r.citizen_id
where r.status = 'resolved'
order by r.submitted_date desc;

select * from citizen_reports_with_status_resolved;


-- 3. Admin Workload (Right Join)--
CREATE VIEW admin_workload AS
SELECT 
    a.full_name AS admin_name,
    a.role,
    COUNT(r.report_id) AS assigned_reports,
    SUM(CASE WHEN r.status = 'resolved' THEN 1 ELSE 0 END) AS resolved_reports
FROM admin a
RIGHT JOIN report r ON a.admin_id = r.assigned_to
GROUP BY a.admin_id, a.full_name, a.role
ORDER BY assigned_reports DESC;
select * from admin_workload;

-- 4. Report Details with Full Information (Multiple Joins)--
CREATE VIEW report_details AS
SELECT 
    r.report_id,
    CONCAT(ci.first_name, ' ', ci.last_name) AS citizen_name,
    i.title AS issue_title,
    c.name AS category_name,
    r.description AS report_description,
    r.status,
    r.submitted_date,
    CONCAT(a.full_name, ' (', a.role, ')') AS assigned_admin,
    r.resolved_date,
    r.satisfaction_rating
FROM report r
JOIN citizen ci ON r.citizen_id = ci.citizen_id
JOIN issue i ON r.issue_id = i.issue_id
JOIN category c ON i.category_id = c.category_id
LEFT JOIN admin a ON r.assigned_to = a.admin_id;
select * from report_details;

-- 5. Unassigned Reports (Subquery)--
create view unassigned_reports as
select
    r.report_id,
    c.name AS category,
    i.title AS issue_title,
    r.submitted_date,
    DATEDIFF(NOW(), r.submitted_date) AS days_unassigned
FROM report r
JOIN issue i ON r.issue_id = i.issue_id
JOIN category c ON i.category_id = c.category_id
WHERE r.assigned_to IS NULL AND r.status = 'pending'
ORDER BY days_unassigned DESC;
select * from unassigned_reports;

-- stored procedures.--

--Procedure to assign report to admin with workload balancing--
DELIMITER //
CREATE PROCEDURE assign_report_to_admin(
    IN p_report_id INT,
    IN p_admin_id INT,
    OUT p_result VARCHAR(100)
)
BEGIN
    DECLARE report_status VARCHAR(20);
    DECLARE admin_exists INT;
    DECLARE current_workload INT;
    
    -- Check if report exists and is pending
    SELECT status INTO report_status FROM report WHERE report_id = p_report_id;
    IF report_status IS NULL THEN
        SET p_result = 'Error: Report not found';
    ELSEIF report_status != 'pending' THEN
        SET p_result = 'Error: Report is not in pending status';
    ELSE
        -- Check if admin exists
        SELECT COUNT(*) INTO admin_exists FROM admin WHERE admin_id = p_admin_id;
        IF admin_exists = 0 THEN
            SET p_result = 'Error: Admin not found';
        ELSE
            -- Get admin's current workload
            SELECT COUNT(*) INTO current_workload 
            FROM report 
            WHERE assigned_to = p_admin_id AND status IN ('pending', 'in_progress');
            
            -- Assign report if workload is less than 5
            IF current_workload >= 5 THEN
                SET p_result = 'Error: Admin has too many assigned reports (5 or more)';
            ELSE
                UPDATE report 
                SET assigned_to = p_admin_id, status = 'in_progress'
                WHERE report_id = p_report_id;
                
                -- Create notification
                INSERT INTO notification (recipient_type, recipient_id, report_id, message, notification_type)
                VALUES ('admin', p_admin_id, p_report_id, 
                       CONCAT('You have been assigned report #', p_report_id), 
                       'assignment');
                
                SET p_result = CONCAT('Success: Report #', p_report_id, ' assigned to admin #', p_admin_id);
            END IF;
        END IF;
    END IF;
END //
DELIMITER ;
-- Declare a session variable to hold the output
CALL assign_report_to_admin(1, 2, @result);

-- Retrieve the output message
SELECT @result;


--Procedure to resolve a report--
DELIMITER //
CREATE PROCEDURE resolve_report(
    IN p_report_id INT,
    IN p_solution VARCHAR(500),
    IN p_satisfaction_rating INT,
    OUT p_result VARCHAR(100)
)
BEGIN
    DECLARE report_status VARCHAR(20);
    DECLARE citizen_id_val INT;
    
    -- Check if report exists
    SELECT status, citizen_id INTO report_status, citizen_id_val 
    FROM report 
    WHERE report_id = p_report_id;
    
    IF report_status IS NULL THEN
        SET p_result = 'Error: Report not found';
    ELSEIF report_status = 'resolved' OR report_status = 'closed' THEN
        SET p_result = 'Error: Report is already resolved or closed';
    ELSE
        -- Update report status and solution
        UPDATE report 
        SET 
            status = 'resolved',
            resolved_date = CURRENT_TIMESTAMP,
            satisfaction_rating = p_satisfaction_rating
        WHERE report_id = p_report_id;
        
        -- Update citizen's solution record
        UPDATE citizen
        SET solution = p_solution
        WHERE citizen_id = citizen_id_val;
        
        -- Create notification for citizen
        INSERT INTO notification (
            recipient_type, 
            recipient_id, 
            report_id, 
            message, 
            notification_type,
            expiry_date
        ) VALUES (
            'citizen', 
            citizen_id_val, 
            p_report_id, 
            CONCAT('Your report #', p_report_id, ' has been resolved. Solution: ', p_solution),
            'resolution',
            DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 30 DAY)
        );
        
        SET p_result = CONCAT('Success: Report #', p_report_id, ' marked as resolved');
    END IF;
END //
DELIMITER ;



-- 3. Procedure to get reports by status with pagination
DELIMITER //
CREATE PROCEDURE get_reports_by_status(
    IN p_status VARCHAR(20),
    IN p_limit INT,
    IN p_offset INT
)
BEGIN
    -- Validate status
    IF p_status NOT IN ('pending', 'in_progress', 'resolved', 'closed', 'rejected') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid status value';
    ELSE
        -- Get paginated reports
        SELECT 
            r.report_id,
            CONCAT(ci.first_name, ' ', ci.last_name) AS citizen_name,
            i.title AS issue_title,
            c.name AS category,
            r.status,
            r.submitted_date,
            r.resolved_date
        FROM report r
        JOIN citizen ci ON r.citizen_id = ci.citizen_id
        JOIN issue i ON r.issue_id = i.issue_id
        JOIN category c ON i.category_id = c.category_id
        WHERE r.status = p_status
        ORDER BY r.submitted_date DESC
        LIMIT p_limit OFFSET p_offset;
    END IF;
END //
DELIMITER ;


--triggers--    
-- 1. Trigger to update citizen status based on reports
DELIMITER //
CREATE TRIGGER update_citizen_status
AFTER UPDATE ON report
FOR EACH ROW
BEGIN
    DECLARE report_count INT;
    DECLARE rejected_count INT;
    
    IF NEW.status = 'rejected' AND OLD.status != 'rejected' THEN
        -- Count total reports and rejected reports for this citizen
        SELECT 
            COUNT(*),
            SUM(CASE WHEN status = 'rejected' THEN 1 ELSE 0 END)
        INTO report_count, rejected_count
        FROM report
        WHERE citizen_id = NEW.citizen_id;
        
        -- If more than 50% reports are rejected, suspend the citizen
        IF report_count > 0 AND (rejected_count / report_count) > 0.5 THEN
            UPDATE citizen
            SET status = 'suspended'
            WHERE citizen_id = NEW.citizen_id;
            
            -- Notify citizen about suspension
            INSERT INTO notification (
                recipient_type, 
                recipient_id, 
                message, 
                notification_type,
                expiry_date
            ) VALUES (
                'citizen', 
                NEW.citizen_id, 
                'Your account has been suspended due to excessive report rejections.',
                'account_status',
                DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 30 DAY)
            );
        END IF;
    END IF;
END //
DELIMITER ;

-- 2. Trigger to validate report assignment
DELIMITER //
CREATE TRIGGER validate_report_assignment
BEFORE UPDATE ON report
FOR EACH ROW
BEGIN
    -- Only check when assigned_to is being changed
    IF NEW.assigned_to IS NOT NULL AND (OLD.assigned_to IS NULL OR NEW.assigned_to != OLD.assigned_to) THEN
        DECLARE admin_role VARCHAR(20);
        DECLARE current_workload INT;
        
        -- Get admin role
        SELECT role INTO admin_role FROM admin WHERE admin_id = NEW.assigned_to;
        
        -- Check if admin exists
        IF admin_role IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid admin ID for assignment';
        ELSE
            -- Get current workload
            SELECT COUNT(*) INTO current_workload 
            FROM report 
            WHERE assigned_to = NEW.assigned_to AND status IN ('pending', 'in_progress');
            
            -- Check workload limits based on role
            IF admin_role = 'staff' AND current_workload >= 5 THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Staff member cannot have more than 5 active reports';
            ELSEIF admin_role = 'supervisor' AND current_workload >= 10 THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Supervisor cannot have more than 10 active reports';
            END IF;
        END IF;
    END IF;
END //
DELIMITER ;

-- 3. Trigger to log status changes
DELIMITER //
CREATE TRIGGER log_report_status_change
AFTER UPDATE ON report
FOR EACH ROW
BEGIN
    IF NEW.status != OLD.status THEN
        INSERT INTO notification (
            recipient_type,
            recipient_id,
            report_id,
            message,
            notification_type
        ) VALUES (
            'citizen',
            NEW.citizen_id,
            NEW.report_id,
            CONCAT('Your report status changed from ', OLD.status, ' to ', NEW.status),
            'status_change'
        );
        
        -- If assigned, also notify the admin
        IF NEW.assigned_to IS NOT NULL THEN
            INSERT INTO notification (
                recipient_type,
                recipient_id,
                report_id,
                message,
                notification_type
            ) VALUES (
                'admin',
                NEW.assigned_to,
                NEW.report_id,
                CONCAT('Report #', NEW.report_id, ' status changed from ', OLD.status, ' to ', NEW.status),
                'status_change'
            );
        END IF;
    END IF;
END //
DELIMITER ;

-- Use stored procedures
CALL assign_report_to_admin(3, 2, @result);
SELECT @result;

CALL resolve_report(1, 'Pothole filled with asphalt patch', 4, @result);
SELECT @result;

-- Query views
SELECT * FROM active_issues_by_category;
SELECT * FROM citizen_reports_with_status;
SELECT * FROM admin_workload;
SELECT * FROM report_details;
SELECT * FROM unassigned_reports;
