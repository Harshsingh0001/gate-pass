-- Gate Pass System Database Setup
-- Run this file in MySQL Workbench or MySQL Command Line

CREATE DATABASE IF NOT EXISTS gate_pass_system;
USE gate_pass_system;

-- Visitors Table
CREATE TABLE IF NOT EXISTS visitors (
  id INT AUTO_INCREMENT PRIMARY KEY,
  visitor_id VARCHAR(20) UNIQUE NOT NULL,
  full_name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  contact_number VARCHAR(20) NOT NULL,
  purpose VARCHAR(255) NOT NULL,
  host_name VARCHAR(100) NOT NULL,
  status ENUM('active', 'expired', 'denied') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_visitor_id (visitor_id),
  INDEX idx_email (email)
);

-- Admins Table
CREATE TABLE IF NOT EXISTS admins (
  id INT AUTO_INCREMENT PRIMARY KEY,
  admin_id VARCHAR(20) UNIQUE NOT NULL,
  admin_name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  contact_number VARCHAR(20) NOT NULL,
  department VARCHAR(100) NOT NULL,
  employee_id VARCHAR(50) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  status ENUM('active', 'inactive') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_admin_id (admin_id),
  INDEX idx_email (email)
);

-- Security Staff Table
CREATE TABLE IF NOT EXISTS security_staff (
  id INT AUTO_INCREMENT PRIMARY KEY,
  security_id VARCHAR(20) UNIQUE NOT NULL,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  contact_number VARCHAR(20) NOT NULL,
  password VARCHAR(255) NOT NULL,
  status ENUM('active', 'inactive') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_security_id (security_id),
  INDEX idx_email (email)
);

-- QR Codes Table
CREATE TABLE IF NOT EXISTS qr_codes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  visitor_id VARCHAR(20) NOT NULL,
  qr_data JSON NOT NULL,
  generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP NULL,
  verified BOOLEAN DEFAULT FALSE,
  FOREIGN KEY (visitor_id) REFERENCES visitors(visitor_id) ON DELETE CASCADE,
  INDEX idx_visitor_id (visitor_id),
  INDEX idx_expires_at (expires_at)
);

-- Visitor Logs Table
CREATE TABLE IF NOT EXISTS visitor_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  visitor_id VARCHAR(20) NOT NULL,
  action ENUM('CHECK_IN', 'CHECK_OUT') NOT NULL,
  gate VARCHAR(50) NOT NULL,
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (visitor_id) REFERENCES visitors(visitor_id) ON DELETE CASCADE,
  INDEX idx_visitor_id (visitor_id),
  INDEX idx_timestamp (timestamp)
);

-- Insert test data (optional)
INSERT INTO admins (admin_id, admin_name, email, contact_number, department, employee_id, password, status)
VALUES ('ADM001', 'Admin User', 'admin@example.com', '1234567890', 'Management', 'EMP001', '$2a$10$n9qo8uLOickgx2ZMRZoMyeIjZAgcg7b3XeKeUxWdeS86E36gZvQm2', 'active');

-- Password for admin is: admin123 (bcrypt hashed)
-- You can use this to login after backend is running

SHOW TABLES;
