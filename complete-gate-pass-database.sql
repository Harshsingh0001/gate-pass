-- ===============================================
-- DIGITAL GATE PASS SYSTEM - COMPLETE DATABASE
-- Created: September 12, 2025
-- Version: 2.0
-- Description: Complete database schema for Digital Gate Pass System
-- Features: Users, Visitors, QR Codes, Security, Emergency, Audit Trail
-- ===============================================

-- Drop database if exists and create new
DROP DATABASE IF EXISTS gate_pass_system;
CREATE DATABASE gate_pass_system 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE gate_pass_system;

-- ===============================================
-- CORE USER MANAGEMENT TABLES
-- ===============================================

-- Users Table (System Users: Admin, Security, Staff, Hosts)
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role ENUM('admin', 'security', 'visitor', 'host', 'staff', 'super_admin') NOT NULL DEFAULT 'visitor',
    
    -- Contact Information
    phone VARCHAR(20),
    address TEXT,
    department VARCHAR(100),
    position VARCHAR(100),
    employee_id VARCHAR(50),
    
    -- Profile
    profile_photo VARCHAR(500),
    bio TEXT,
    
    -- Security & Status
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret VARCHAR(32),
    
    -- Login Tracking
    last_login TIMESTAMP NULL,
    login_count INT DEFAULT 0,
    failed_login_attempts INT DEFAULT 0,
    account_locked_until TIMESTAMP NULL,
    password_reset_token VARCHAR(255),
    password_reset_expires TIMESTAMP NULL,
    
    -- Preferences
    timezone VARCHAR(50) DEFAULT 'UTC',
    language VARCHAR(10) DEFAULT 'en',
    notifications_enabled BOOLEAN DEFAULT TRUE,
    email_notifications BOOLEAN DEFAULT TRUE,
    sms_notifications BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    -- Indexes
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_active (is_active),
    INDEX idx_employee_id (employee_id),
    INDEX idx_department (department),
    INDEX idx_created (created_at)
);

-- User Sessions Table
CREATE TABLE user_sessions (
    session_id VARCHAR(128) PRIMARY KEY,
    user_id INT NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    device_info JSON,
    location_info JSON,
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user (user_id),
    INDEX idx_expires (expires_at),
    INDEX idx_active (is_active)
);

-- ===============================================
-- VISITOR MANAGEMENT TABLES
-- ===============================================

-- Visitors Table
CREATE TABLE visitors (
    visitor_id VARCHAR(15) PRIMARY KEY, -- V001, V002, etc.
    
    -- Personal Information
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20) NOT NULL,
    date_of_birth DATE,
    gender ENUM('male', 'female', 'other', 'prefer_not_to_say'),
    nationality VARCHAR(100),
    
    -- Identification
    id_type ENUM('drivers_license', 'passport', 'national_id', 'voter_id', 'other') NOT NULL,
    id_number VARCHAR(100) NOT NULL,
    id_expiry_date DATE,
    
    -- Organization
    company VARCHAR(255),
    position VARCHAR(100),
    company_address TEXT,
    
    -- Visit Information
    purpose_of_visit TEXT NOT NULL,
    visit_type ENUM('business', 'interview', 'delivery', 'maintenance', 'meeting', 
                   'consultation', 'training', 'event', 'personal', 'other') DEFAULT 'business',
    visit_frequency ENUM('first_time', 'regular', 'frequent') DEFAULT 'first_time',
    
    -- Emergency Contact
    emergency_contact_name VARCHAR(255),
    emergency_contact_relationship VARCHAR(100),
    emergency_contact_phone VARCHAR(20),
    emergency_contact_email VARCHAR(255),
    
    -- Media & Documentation
    visitor_photo VARCHAR(500),
    id_photo_front VARCHAR(500),
    id_photo_back VARCHAR(500),
    signature_image VARCHAR(500),
    
    -- Security & Status
    is_blacklisted BOOLEAN DEFAULT FALSE,
    blacklist_reason TEXT,
    blacklisted_by INT,
    blacklisted_at TIMESTAMP NULL,
    risk_level ENUM('low', 'medium', 'high') DEFAULT 'low',
    
    -- Preferences
    preferred_language VARCHAR(10) DEFAULT 'en',
    special_requirements TEXT,
    medical_conditions TEXT,
    dietary_restrictions TEXT,
    
    -- Visit Statistics
    total_visits INT DEFAULT 0,
    last_visit_date DATE,
    average_visit_duration_minutes INT,
    
    -- Notes
    internal_notes TEXT,
    public_notes TEXT,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    FOREIGN KEY (blacklisted_by) REFERENCES users(user_id),
    
    -- Indexes
    INDEX idx_name (full_name),
    INDEX idx_phone (phone),
    INDEX idx_email (email),
    INDEX idx_company (company),
    INDEX idx_blacklisted (is_blacklisted),
    INDEX idx_visit_type (visit_type),
    INDEX idx_created (created_at),
    INDEX idx_last_visit (last_visit_date)
);

-- Visitor History Table (for tracking changes)
CREATE TABLE visitor_history (
    history_id INT PRIMARY KEY AUTO_INCREMENT,
    visitor_id VARCHAR(15) NOT NULL,
    field_name VARCHAR(100) NOT NULL,
    old_value TEXT,
    new_value TEXT,
    changed_by INT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    change_reason TEXT,
    
    FOREIGN KEY (visitor_id) REFERENCES visitors(visitor_id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by) REFERENCES users(user_id),
    
    INDEX idx_visitor (visitor_id),
    INDEX idx_changed_at (changed_at),
    INDEX idx_field (field_name)
);

-- ===============================================
-- HOST MANAGEMENT TABLES
-- ===============================================

-- Hosts Table (Employees who can receive visitors)
CREATE TABLE hosts (
    host_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    
    -- Employee Information
    employee_id VARCHAR(50) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    alternate_phone VARCHAR(20),
    
    -- Organization
    department VARCHAR(100) NOT NULL,
    position VARCHAR(100),
    manager_id INT,
    cost_center VARCHAR(50),
    
    -- Location
    office_location VARCHAR(150),
    building VARCHAR(50),
    floor INT,
    room_number VARCHAR(20),
    desk_number VARCHAR(20),
    
    -- Visitor Management Settings
    can_approve_visits BOOLEAN DEFAULT TRUE,
    requires_approval_from_manager BOOLEAN DEFAULT FALSE,
    max_daily_visitors INT DEFAULT 20,
    max_concurrent_visitors INT DEFAULT 5,
    auto_approve_known_visitors BOOLEAN DEFAULT FALSE,
    
    -- Working Hours
    working_hours_start TIME DEFAULT '09:00:00',
    working_hours_end TIME DEFAULT '17:00:00',
    working_days JSON, -- ["monday", "tuesday", etc.]
    timezone VARCHAR(50) DEFAULT 'UTC',
    
    -- Notification Preferences
    notification_preferences JSON,
    email_notifications BOOLEAN DEFAULT TRUE,
    sms_notifications BOOLEAN DEFAULT FALSE,
    in_app_notifications BOOLEAN DEFAULT TRUE,
    
    -- Security Clearance
    security_clearance_level ENUM('basic', 'confidential', 'secret', 'top_secret') DEFAULT 'basic',
    can_escort_visitors BOOLEAN DEFAULT TRUE,
    authorized_areas TEXT, -- JSON array of area codes
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    is_available BOOLEAN DEFAULT TRUE,
    out_of_office_message TEXT,
    return_date DATE,
    
    -- Backup Host
    backup_host_id INT,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (manager_id) REFERENCES hosts(host_id),
    FOREIGN KEY (backup_host_id) REFERENCES hosts(host_id),
    
    -- Indexes
    INDEX idx_user (user_id),
    INDEX idx_employee_id (employee_id),
    INDEX idx_department (department),
    INDEX idx_email (email),
    INDEX idx_active (is_active),
    INDEX idx_available (is_available),
    INDEX idx_manager (manager_id)
);

-- Host Availability Schedule
CREATE TABLE host_availability (
    availability_id INT PRIMARY KEY AUTO_INCREMENT,
    host_id INT NOT NULL,
    date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    status ENUM('available', 'busy', 'out_of_office', 'meeting') DEFAULT 'available',
    notes TEXT,
    
    FOREIGN KEY (host_id) REFERENCES hosts(host_id) ON DELETE CASCADE,
    
    UNIQUE KEY unique_host_datetime (host_id, date, start_time),
    INDEX idx_host (host_id),
    INDEX idx_date (date),
    INDEX idx_status (status)
);

-- ===============================================
-- GATE PASS SYSTEM TABLES
-- ===============================================

-- Gate Passes Table
CREATE TABLE gate_passes (
    pass_id VARCHAR(20) PRIMARY KEY, -- GP001, GP002, etc.
    visitor_id VARCHAR(15) NOT NULL,
    host_id INT NOT NULL,
    
    -- QR Code Information
    qr_code_data TEXT NOT NULL,
    qr_code_hash VARCHAR(64) NOT NULL UNIQUE,
    qr_image_path VARCHAR(500),
    qr_version INT DEFAULT 1, -- for regeneration tracking
    
    -- Pass Status
    status ENUM('draft', 'pending', 'approved', 'active', 'expired', 
               'revoked', 'completed', 'cancelled', 'suspended') DEFAULT 'draft',
    status_reason TEXT,
    
    -- Visit Schedule
    visit_date DATE NOT NULL,
    scheduled_time_in TIME,
    scheduled_time_out TIME,
    estimated_duration_minutes INT,
    
    -- Actual Visit Times
    actual_time_in TIMESTAMP NULL,
    actual_time_out TIMESTAMP NULL,
    actual_duration_minutes INT,
    
    -- Access Control
    entry_gate VARCHAR(50),
    exit_gate VARCHAR(50),
    allowed_gates TEXT, -- JSON array of gate names
    destination VARCHAR(255),
    authorized_areas TEXT, -- JSON array of area codes
    
    -- Escort Information
    escort_required BOOLEAN DEFAULT FALSE,
    escort_name VARCHAR(255),
    escort_phone VARCHAR(20),
    escort_id INT,
    escort_assigned_at TIMESTAMP NULL,
    
    -- Vehicle Information
    has_vehicle BOOLEAN DEFAULT FALSE,
    vehicle_make VARCHAR(100),
    vehicle_model VARCHAR(100),
    vehicle_color VARCHAR(50),
    license_plate VARCHAR(20),
    parking_spot VARCHAR(50),
    
    -- Security Level
    security_level ENUM('basic', 'standard', 'high', 'maximum') DEFAULT 'standard',
    requires_background_check BOOLEAN DEFAULT FALSE,
    background_check_status ENUM('not_required', 'pending', 'approved', 'rejected') DEFAULT 'not_required',
    
    -- Approval Workflow
    requires_approval BOOLEAN DEFAULT FALSE,
    approval_level_required ENUM('host', 'manager', 'security', 'admin') DEFAULT 'host',
    approved_by INT,
    approved_at TIMESTAMP NULL,
    approval_notes TEXT,
    rejected_by INT,
    rejected_at TIMESTAMP NULL,
    rejection_reason TEXT,
    
    -- Pass Validity
    valid_from TIMESTAMP NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    auto_extend BOOLEAN DEFAULT FALSE,
    max_extensions INT DEFAULT 1,
    current_extensions INT DEFAULT 0,
    
    -- Additional Information
    visit_purpose_detailed TEXT,
    materials_brought TEXT,
    equipment_needed TEXT,
    special_instructions TEXT,
    accessibility_requirements TEXT,
    
    -- Pass Generation
    generated_by INT,
    generation_method ENUM('web_form', 'mobile_app', 'kiosk', 'admin_panel', 'api') DEFAULT 'web_form',
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    FOREIGN KEY (visitor_id) REFERENCES visitors(visitor_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id) REFERENCES hosts(host_id) ON DELETE CASCADE,
    FOREIGN KEY (approved_by) REFERENCES users(user_id),
    FOREIGN KEY (rejected_by) REFERENCES users(user_id),
    FOREIGN KEY (generated_by) REFERENCES users(user_id),
    FOREIGN KEY (escort_id) REFERENCES hosts(host_id),
    
    -- Indexes
    INDEX idx_visitor (visitor_id),
    INDEX idx_host (host_id),
    INDEX idx_status (status),
    INDEX idx_visit_date (visit_date),
    INDEX idx_qr_hash (qr_code_hash),
    INDEX idx_valid_period (valid_from, expires_at),
    INDEX idx_created (created_at),
    INDEX idx_security_level (security_level)
);

-- Pass Templates Table (for recurring visits)
CREATE TABLE pass_templates (
    template_id INT PRIMARY KEY AUTO_INCREMENT,
    template_name VARCHAR(255) NOT NULL,
    created_by INT NOT NULL,
    host_id INT NOT NULL,
    
    -- Template Configuration
    visit_type VARCHAR(50),
    purpose_template TEXT,
    default_duration_minutes INT DEFAULT 120,
    default_security_level ENUM('basic', 'standard', 'high', 'maximum') DEFAULT 'standard',
    
    -- Access Settings
    authorized_areas TEXT, -- JSON array
    allowed_gates TEXT, -- JSON array
    escort_required BOOLEAN DEFAULT FALSE,
    
    -- Approval Settings
    requires_approval BOOLEAN DEFAULT FALSE,
    approval_level ENUM('host', 'manager', 'security', 'admin') DEFAULT 'host',
    
    -- Usage Tracking
    times_used INT DEFAULT 0,
    last_used_at TIMESTAMP NULL,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (created_by) REFERENCES users(user_id),
    FOREIGN KEY (host_id) REFERENCES hosts(host_id),
    
    INDEX idx_created_by (created_by),
    INDEX idx_host (host_id),
    INDEX idx_active (is_active)
);

-- ===============================================
-- ACCESS CONTROL & SECURITY TABLES
-- ===============================================

-- Access Logs Table
CREATE TABLE access_logs (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    pass_id VARCHAR(20) NOT NULL,
    visitor_id VARCHAR(15) NOT NULL,
    
    -- Access Event Details
    action_type ENUM('entry', 'exit', 'scan', 'verification', 'denied', 'timeout', 'override') NOT NULL,
    access_point VARCHAR(100) NOT NULL, -- Gate A, Door B1, etc.
    direction ENUM('in', 'out', 'scan_only') NOT NULL,
    
    -- Verification Details
    verification_method ENUM('qr_scan', 'manual_entry', 'biometric', 'rfid_card', 'facial_recognition', 'override') DEFAULT 'qr_scan',
    verification_status ENUM('success', 'failed', 'expired', 'invalid', 'blocked', 'override_required') DEFAULT 'success',
    verification_score DECIMAL(3,2), -- For biometric/facial recognition confidence
    
    -- Security Personnel
    security_officer_id INT,
    override_authorized_by INT,
    override_reason TEXT,
    
    -- Device Information
    device_id VARCHAR(100),
    device_type ENUM('scanner', 'tablet', 'kiosk', 'mobile', 'desktop', 'api') DEFAULT 'scanner',
    device_location VARCHAR(100),
    
    -- Technical Details
    ip_address VARCHAR(45),
    user_agent TEXT,
    request_headers JSON,
    response_data JSON,
    
    -- Media Capture
    photo_taken VARCHAR(500),
    video_clip VARCHAR(500),
    biometric_data JSON,
    
    -- Failure Information
    failure_code VARCHAR(20),
    failure_reason TEXT,
    retry_count INT DEFAULT 0,
    
    -- Additional Context
    weather_conditions VARCHAR(100),
    crowd_level ENUM('low', 'medium', 'high'),
    additional_notes TEXT,
    
    -- Processing Time
    processing_time_ms INT,
    
    -- Timestamp
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (pass_id) REFERENCES gate_passes(pass_id) ON DELETE CASCADE,
    FOREIGN KEY (visitor_id) REFERENCES visitors(visitor_id) ON DELETE CASCADE,
    FOREIGN KEY (security_officer_id) REFERENCES users(user_id),
    FOREIGN KEY (override_authorized_by) REFERENCES users(user_id),
    
    -- Indexes
    INDEX idx_pass (pass_id),
    INDEX idx_visitor (visitor_id),
    INDEX idx_timestamp (timestamp),
    INDEX idx_action (action_type),
    INDEX idx_access_point (access_point),
    INDEX idx_officer (security_officer_id),
    INDEX idx_verification (verification_method, verification_status),
    INDEX idx_device (device_id)
);

-- Security Alerts Table
CREATE TABLE security_alerts (
    alert_id INT PRIMARY KEY AUTO_INCREMENT,
    
    -- Alert Classification
    alert_type ENUM('expired_pass', 'blacklisted_visitor', 'multiple_failed_attempts', 
                   'tailgating_detected', 'unauthorized_area_access', 'suspicious_behavior',
                   'device_malfunction', 'network_connectivity', 'system_breach', 
                   'emergency_button', 'fire_alarm', 'intrusion_detected', 'other') NOT NULL,
    
    severity ENUM('informational', 'low', 'medium', 'high', 'critical', 'emergency') NOT NULL,
    priority INT DEFAULT 3, -- 1=highest, 5=lowest
    
    -- Alert Details
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    long_description TEXT,
    
    -- Location & Context
    location VARCHAR(100),
    building VARCHAR(50),
    floor INT,
    room VARCHAR(50),
    coordinates POINT,
    
    -- Related Records
    visitor_id VARCHAR(15),
    pass_id VARCHAR(20),
    access_log_id INT,
    device_id VARCHAR(100),
    
    -- Personnel Involved
    triggered_by_system BOOLEAN DEFAULT TRUE,
    triggered_by_user_id INT,
    detected_by_device VARCHAR(100),
    
    -- Response & Assignment
    assigned_to_user_id INT,
    escalated_to_user_id INT,
    response_team_ids JSON, -- Array of user IDs
    
    -- Status & Resolution
    status ENUM('new', 'acknowledged', 'investigating', 'escalated', 'resolved', 
               'false_positive', 'cancelled', 'archived') DEFAULT 'new',
    acknowledgment_required BOOLEAN DEFAULT TRUE,
    auto_resolved BOOLEAN DEFAULT FALSE,
    
    -- Response Time Tracking
    response_time_target_minutes INT,
    acknowledged_at TIMESTAMP NULL,
    response_started_at TIMESTAMP NULL,
    resolved_at TIMESTAMP NULL,
    
    -- Resolution Details
    resolution_summary TEXT,
    resolution_actions_taken TEXT,
    preventive_measures TEXT,
    
    -- Follow-up
    follow_up_required BOOLEAN DEFAULT FALSE,
    follow_up_date DATE,
    follow_up_assigned_to INT,
    follow_up_notes TEXT,
    
    -- Notification Status
    notifications_sent JSON, -- Track which notifications were sent
    escalation_sent BOOLEAN DEFAULT FALSE,
    
    -- Risk Assessment
    risk_score INT, -- 1-10
    potential_impact TEXT,
    likelihood_of_recurrence ENUM('low', 'medium', 'high'),
    
    -- External References
    incident_number VARCHAR(50),
    police_report_number VARCHAR(50),
    insurance_claim_number VARCHAR(50),
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (visitor_id) REFERENCES visitors(visitor_id),
    FOREIGN KEY (pass_id) REFERENCES gate_passes(pass_id),
    FOREIGN KEY (access_log_id) REFERENCES access_logs(log_id),
    FOREIGN KEY (triggered_by_user_id) REFERENCES users(user_id),
    FOREIGN KEY (assigned_to_user_id) REFERENCES users(user_id),
    FOREIGN KEY (escalated_to_user_id) REFERENCES users(user_id),
    FOREIGN KEY (follow_up_assigned_to) REFERENCES users(user_id),
    
    -- Indexes
    INDEX idx_type (alert_type),
    INDEX idx_severity (severity),
    INDEX idx_status (status),
    INDEX idx_location (location),
    INDEX idx_created (created_at),
    INDEX idx_priority (priority),
    INDEX idx_assigned (assigned_to_user_id),
    INDEX idx_coordinates (coordinates),
    SPATIAL INDEX spatial_coordinates (coordinates)
);

-- Security Zones Table
CREATE TABLE security_zones (
    zone_id INT PRIMARY KEY AUTO_INCREMENT,
    zone_code VARCHAR(20) UNIQUE NOT NULL,
    zone_name VARCHAR(255) NOT NULL,
    
    -- Zone Details
    description TEXT,
    building VARCHAR(50),
    floor INT,
    area_type ENUM('lobby', 'office', 'laboratory', 'server_room', 'warehouse', 
                  'cafeteria', 'parking', 'restricted', 'classified', 'other') DEFAULT 'office',
    
    -- Security Level
    security_level ENUM('public', 'restricted', 'confidential', 'secret', 'top_secret') DEFAULT 'restricted',
    clearance_required VARCHAR(100),
    
    -- Access Control
    requires_escort BOOLEAN DEFAULT FALSE,
    max_occupancy INT,
    visitor_access_allowed BOOLEAN DEFAULT TRUE,
    time_restrictions JSON, -- {"monday": {"start": "09:00", "end": "17:00"}, ...}
    
    -- Monitoring
    has_cameras BOOLEAN DEFAULT FALSE,
    camera_ids JSON,
    has_motion_sensors BOOLEAN DEFAULT FALSE,
    has_access_control BOOLEAN DEFAULT TRUE,
    
    -- Emergency Information
    evacuation_route TEXT,
    assembly_point VARCHAR(100),
    emergency_contact_id INT,
    special_hazards TEXT,
    
    -- Geographic Information
    coordinates POLYGON,
    entrance_points JSON, -- Array of entrance coordinates
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    is_operational BOOLEAN DEFAULT TRUE,
    maintenance_mode BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (emergency_contact_id) REFERENCES users(user_id),
    
    INDEX idx_code (zone_code),
    INDEX idx_building (building, floor),
    INDEX idx_security_level (security_level),
    INDEX idx_active (is_active),
    SPATIAL INDEX spatial_coordinates (coordinates)
);

-- ===============================================
-- EMERGENCY MANAGEMENT TABLES
-- ===============================================

-- Emergency Events Table
CREATE TABLE emergency_events (
    emergency_id INT PRIMARY KEY AUTO_INCREMENT,
    
    -- Emergency Classification
    emergency_type ENUM('fire', 'medical', 'security_breach', 'natural_disaster', 
                       'bomb_threat', 'chemical_spill', 'power_outage', 'elevator_entrapment',
                       'lockdown', 'evacuation', 'shelter_in_place', 'other') NOT NULL,
    
    severity ENUM('minor', 'moderate', 'major', 'critical', 'catastrophic') NOT NULL,
    status ENUM('initiated', 'active', 'escalated', 'contained', 'resolved', 'cancelled') NOT NULL,
    
    -- Emergency Details
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    
    -- Location & Scope
    primary_location VARCHAR(100),
    affected_buildings JSON, -- Array of building codes
    affected_zones JSON, -- Array of zone IDs
    affected_coordinates POLYGON,
    
    -- Personnel & Response
    initiated_by_user_id INT NOT NULL,
    incident_commander_id INT,
    response_team_members JSON, -- Array of user IDs
    external_responders JSON, -- Fire, Police, Ambulance, etc.
    
    -- Visitor & Occupant Information
    total_occupants_estimated INT DEFAULT 0,
    total_visitors_inside INT DEFAULT 0,
    total_staff_inside INT DEFAULT 0,
    evacuated_count INT DEFAULT 0,
    missing_count INT DEFAULT 0,
    injured_count INT DEFAULT 0,
    fatality_count INT DEFAULT 0,
    
    -- Communication & Instructions
    emergency_announcement TEXT,
    public_address_message TEXT,
    evacuation_routes JSON,
    assembly_points JSON,
    
    -- External Agencies
    fire_department_notified BOOLEAN DEFAULT FALSE,
    police_notified BOOLEAN DEFAULT FALSE,
    ambulance_requested BOOLEAN DEFAULT FALSE,
    utility_companies_notified BOOLEAN DEFAULT FALSE,
    
    -- Timeline
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    first_responder_arrival TIMESTAMP NULL,
    all_clear_time TIMESTAMP NULL,
    incident_resolution_time TIMESTAMP NULL,
    
    -- Damage & Impact Assessment
    property_damage_estimate DECIMAL(15,2),
    business_continuity_impact TEXT,
    environmental_impact TEXT,
    
    -- Documentation
    incident_photos JSON, -- Array of file paths
    incident_videos JSON,
    witness_statements TEXT,
    
    -- Post-Incident
    post_incident_review_required BOOLEAN DEFAULT TRUE,
    lessons_learned TEXT,
    action_items JSON,
    preventive_measures TEXT,
    
    -- Reporting
    regulatory_reporting_required BOOLEAN DEFAULT FALSE,
    insurance_claim_filed BOOLEAN DEFAULT FALSE,
    media_response_required BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (initiated_by_user_id) REFERENCES users(user_id),
    FOREIGN KEY (incident_commander_id) REFERENCES users(user_id),
    
    INDEX idx_type (emergency_type),
    INDEX idx_severity (severity),
    INDEX idx_status (status),
    INDEX idx_start_time (start_time),
    INDEX idx_location (primary_location),
    SPATIAL INDEX spatial_affected_area (affected_coordinates)
);

-- Emergency Contacts Table
CREATE TABLE emergency_contacts (
    contact_id INT PRIMARY KEY AUTO_INCREMENT,
    contact_type ENUM('fire_department', 'police', 'ambulance', 'hospital', 'poison_control',
                     'utility_electric', 'utility_gas', 'utility_water', 'security_company',
                     'building_management', 'insurance', 'media_relations', 'legal', 'other') NOT NULL,
    
    organization_name VARCHAR(255) NOT NULL,
    contact_person VARCHAR(255),
    primary_phone VARCHAR(20) NOT NULL,
    emergency_phone VARCHAR(20),
    email VARCHAR(255),
    address TEXT,
    
    -- Service Details
    service_area TEXT,
    response_time_minutes INT,
    availability_24_7 BOOLEAN DEFAULT FALSE,
    service_level_agreement TEXT,
    
    -- Contact Preferences
    preferred_contact_method ENUM('phone', 'email', 'radio', 'app') DEFAULT 'phone',
    escalation_contacts JSON,
    
    is_active BOOLEAN DEFAULT TRUE,
    priority_order INT DEFAULT 1,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_type (contact_type),
    INDEX idx_active (is_active),
    INDEX idx_priority (priority_order)
);

-- ===============================================
-- VISITOR TRACKING & LOCATION TABLES
-- ===============================================

-- Real-time Visitor Tracking
CREATE TABLE visitor_tracking (
    tracking_id INT PRIMARY KEY AUTO_INCREMENT,
    visitor_id VARCHAR(15) NOT NULL,
    pass_id VARCHAR(20) NOT NULL,
    
    -- Current Location
    current_zone_id INT,
    current_building VARCHAR(50),
    current_floor INT,
    current_room VARCHAR(50),
    last_seen_access_point VARCHAR(100),
    coordinates POINT,
    
    -- Status Information
    is_inside_premises BOOLEAN DEFAULT FALSE,
    current_status ENUM('checked_in', 'in_transit', 'at_destination', 'checked_out', 'missing', 'emergency') DEFAULT 'checked_in',
    
    -- Timing
    check_in_time TIMESTAMP NULL,
    expected_checkout_time TIMESTAMP NULL,
    actual_checkout_time TIMESTAMP NULL,
    last_movement_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Host & Escort Information
    currently_with_host BOOLEAN DEFAULT FALSE,
    escort_id INT,
    escort_status ENUM('assigned', 'with_visitor', 'completed', 'unavailable'),
    
    -- Emergency Information
    emergency_evacuation_status ENUM('unknown', 'safe', 'evacuating', 'evacuated', 'missing', 'injured') DEFAULT 'unknown',
    emergency_contact_notified BOOLEAN DEFAULT FALSE,
    medical_attention_required BOOLEAN DEFAULT FALSE,
    
    -- Device Tracking (if applicable)
    visitor_device_mac VARCHAR(17),
    bluetooth_beacon_id VARCHAR(50),
    wifi_connection_status BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (visitor_id) REFERENCES visitors(visitor_id) ON DELETE CASCADE,
    FOREIGN KEY (pass_id) REFERENCES gate_passes(pass_id) ON DELETE CASCADE,
    FOREIGN KEY (current_zone_id) REFERENCES security_zones(zone_id),
    FOREIGN KEY (escort_id) REFERENCES hosts(host_id),
    
    UNIQUE KEY unique_visitor_pass (visitor_id, pass_id),
    INDEX idx_visitor (visitor_id),
    INDEX idx_pass (pass_id),
    INDEX idx_inside (is_inside_premises),
    INDEX idx_status (current_status),
    INDEX idx_zone (current_zone_id),
    INDEX idx_updated (last_updated),
    SPATIAL INDEX spatial_coordinates (coordinates)
);

-- Location History (for analytics and compliance)
CREATE TABLE location_history (
    history_id INT PRIMARY KEY AUTO_INCREMENT,
    visitor_id VARCHAR(15) NOT NULL,
    pass_id VARCHAR(20) NOT NULL,
    
    zone_id INT,
    access_point VARCHAR(100),
    coordinates POINT,
    movement_type ENUM('entry', 'exit', 'movement', 'static'),
    
    -- Timing
    entry_time TIMESTAMP NOT NULL,
    exit_time TIMESTAMP NULL,
    duration_minutes INT,
    
    -- Context
    accompanied_by INT, -- host/escort user_id
    purpose_in_zone TEXT,
    
    -- Verification
    verified_by_device VARCHAR(100),
    verification_method VARCHAR(50),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (visitor_id) REFERENCES visitors(visitor_id) ON DELETE CASCADE,
    FOREIGN KEY (pass_id) REFERENCES gate_passes(pass_id) ON DELETE CASCADE,
    FOREIGN KEY (zone_id) REFERENCES security_zones(zone_id),
    FOREIGN KEY (accompanied_by) REFERENCES users(user_id),
    
    INDEX idx_visitor (visitor_id),
    INDEX idx_pass (pass_id),
    INDEX idx_zone (zone_id),
    INDEX idx_entry_time (entry_time),
    SPATIAL INDEX spatial_coordinates (coordinates)
);

-- ===============================================
-- COMMUNICATION & NOTIFICATION TABLES
-- ===============================================

-- Notifications Table
CREATE TABLE notifications (
    notification_id INT PRIMARY KEY AUTO_INCREMENT,
    
    -- Recipient Information
    recipient_id INT NOT NULL,
    recipient_type ENUM('user', 'host', 'security', 'admin', 'emergency_contact') DEFAULT 'user',
    recipient_email VARCHAR(255),
    recipient_phone VARCHAR(20),
    
    -- Notification Details
    notification_type ENUM('visitor_pre_arrival', 'visitor_arrival', 'visitor_departure', 
                          'visitor_late', 'visitor_no_show', 'pass_approved', 'pass_rejected',
                          'pass_expiring', 'pass_expired', 'security_alert', 'emergency',
                          'system_maintenance', 'device_offline', 'other') NOT NULL,
    
    category ENUM('informational', 'warning', 'alert', 'emergency', 'system') DEFAULT 'informational',
    priority ENUM('low', 'normal', 'high', 'urgent', 'emergency') DEFAULT 'normal',
    
    -- Content
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    rich_content JSON, -- HTML, images, buttons, etc.
    
    -- Related Records
    visitor_id VARCHAR(15),
    pass_id VARCHAR(20),
    alert_id INT,
    emergency_id INT,
    
    -- Delivery Configuration
    delivery_methods JSON, -- ["web", "email", "sms", "push", "voice"]
    delivery_preferences JSON,
    
    -- Delivery Status
    is_sent BOOLEAN DEFAULT FALSE,
    delivery_attempts INT DEFAULT 0,
    max_delivery_attempts INT DEFAULT 3,
    
    -- Channel-specific Status
    web_delivered BOOLEAN DEFAULT FALSE,
    email_delivered BOOLEAN DEFAULT FALSE,
    sms_delivered BOOLEAN DEFAULT FALSE,
    push_delivered BOOLEAN DEFAULT FALSE,
    voice_delivered BOOLEAN DEFAULT FALSE,
    
    -- User Interaction
    is_read BOOLEAN DEFAULT FALSE,
    is_acknowledged BOOLEAN DEFAULT FALSE,
    action_taken BOOLEAN DEFAULT FALSE,
    user_response TEXT,
    
    -- Scheduling
    scheduled_delivery_time TIMESTAMP NULL,
    delivered_at TIMESTAMP NULL,
    expires_at TIMESTAMP NULL,
    
    -- Retry & Error Handling
    last_delivery_attempt TIMESTAMP NULL,
    delivery_error_message TEXT,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP NULL,
    acknowledged_at TIMESTAMP NULL,
    
    FOREIGN KEY (recipient_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (visitor_id) REFERENCES visitors(visitor_id),
    FOREIGN KEY (pass_id) REFERENCES gate_passes(pass_id),
    FOREIGN KEY (alert_id) REFERENCES security_alerts(alert_id),
    FOREIGN KEY (emergency_id) REFERENCES emergency_events(emergency_id),
    
    -- Indexes
    INDEX idx_recipient (recipient_id),
    INDEX idx_type (notification_type),
    INDEX idx_category (category),
    INDEX idx_priority (priority),
    INDEX idx_sent (is_sent),
    INDEX idx_read (is_read),
    INDEX idx_created (created_at),
    INDEX idx_scheduled (scheduled_delivery_time)
);

-- Notification Templates
CREATE TABLE notification_templates (
    template_id INT PRIMARY KEY AUTO_INCREMENT,
    template_name VARCHAR(255) NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    language VARCHAR(10) DEFAULT 'en',
    
    -- Template Content
    subject_template TEXT NOT NULL,
    body_template TEXT NOT NULL,
    html_template TEXT,
    sms_template TEXT,
    
    -- Template Variables
    available_variables JSON,
    required_variables JSON,
    
    -- Usage Tracking
    times_used INT DEFAULT 0,
    last_used_at TIMESTAMP NULL,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    is_default BOOLEAN DEFAULT FALSE,
    
    created_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (created_by) REFERENCES users(user_id),
    
    INDEX idx_type (notification_type),
    INDEX idx_active (is_active),
    INDEX idx_language (language)
);

-- ===============================================
-- SYSTEM CONFIGURATION & SETTINGS TABLES
-- ===============================================

-- System Settings
CREATE TABLE system_settings (
    setting_id INT PRIMARY KEY AUTO_INCREMENT,
    category VARCHAR(50) NOT NULL,
    setting_key VARCHAR(100) NOT NULL,
    setting_value TEXT NOT NULL,
    setting_type ENUM('string', 'integer', 'float', 'boolean', 'json', 'text', 'file') DEFAULT 'string',
    
    -- Metadata
    display_name VARCHAR(255),
    description TEXT,
    help_text TEXT,
    
    -- Validation
    validation_rules JSON,
    default_value TEXT,
    possible_values JSON,
    
    -- Access Control
    is_public BOOLEAN DEFAULT FALSE,
    is_readonly BOOLEAN DEFAULT FALSE,
    is_system BOOLEAN DEFAULT FALSE,
    required_role VARCHAR(20) DEFAULT 'admin',
    
    -- Organization
    display_order INT DEFAULT 0,
    group_name VARCHAR(100),
    
    -- Change Tracking
    updated_by INT,
    previous_value TEXT,
    change_reason TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (updated_by) REFERENCES users(user_id),
    
    UNIQUE KEY unique_category_key (category, setting_key),
    INDEX idx_category (category),
    INDEX idx_key (setting_key),
    INDEX idx_public (is_public),
    INDEX idx_system (is_system)
);

-- Device Registry & Management
CREATE TABLE device_registry (
    device_id VARCHAR(100) PRIMARY KEY,
    device_name VARCHAR(255) NOT NULL,
    device_type ENUM('qr_scanner', 'tablet', 'kiosk', 'mobile_app', 'desktop_app', 
                    'api_client', 'camera', 'sensor', 'badge_reader') NOT NULL,
    
    -- Location & Installation
    location VARCHAR(100) NOT NULL,
    building VARCHAR(50),
    floor INT,
    zone_id INT,
    installation_date DATE,
    
    -- Network Configuration
    ip_address VARCHAR(45),
    mac_address VARCHAR(17),
    network_name VARCHAR(100),
    
    -- Device Specifications
    manufacturer VARCHAR(100),
    model VARCHAR(100),
    serial_number VARCHAR(100),
    firmware_version VARCHAR(50),
    hardware_version VARCHAR(50),
    
    -- Capabilities
    capabilities JSON, -- {"qr_scan": true, "photo": true, "biometric": false, ...}
    supported_protocols JSON,
    
    -- Configuration
    configuration JSON,
    custom_settings JSON,
    
    -- Security
    api_key_hash VARCHAR(255),
    certificate_fingerprint VARCHAR(255),
    last_security_update TIMESTAMP NULL,
    
    -- Status & Health
    is_active BOOLEAN DEFAULT TRUE,
    status ENUM('online', 'offline', 'maintenance', 'error', 'upgrading') DEFAULT 'offline',
    health_score INT DEFAULT 100, -- 0-100
    last_ping TIMESTAMP NULL,
    
    -- Maintenance
    maintenance_schedule JSON,
    last_maintenance_date DATE,
    next_maintenance_date DATE,
    maintenance_notes TEXT,
    
    -- Performance Metrics
    total_scans_processed INT DEFAULT 0,
    successful_scans INT DEFAULT 0,
    failed_scans INT DEFAULT 0,
    average_response_time_ms INT,
    uptime_percentage DECIMAL(5,2) DEFAULT 100.00,
    
    -- Timestamps
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_activity TIMESTAMP NULL,
    
    FOREIGN KEY (zone_id) REFERENCES security_zones(zone_id),
    
    INDEX idx_type (device_type),
    INDEX idx_location (location),
    INDEX idx_zone (zone_id),
    INDEX idx_status (status),
    INDEX idx_active (is_active),
    INDEX idx_last_ping (last_ping)
);

-- ===============================================
-- AUDIT TRAIL & COMPLIANCE TABLES
-- ===============================================

-- Comprehensive Audit Logs
CREATE TABLE audit_logs (
    audit_id INT PRIMARY KEY AUTO_INCREMENT,
    
    -- Transaction Information
    transaction_id VARCHAR(36) NOT NULL, -- UUID for transaction grouping
    sequence_number INT NOT NULL,
    
    -- Record Information
    table_name VARCHAR(64) NOT NULL,
    record_id VARCHAR(50) NOT NULL,
    action ENUM('create', 'read', 'update', 'delete', 'login', 'logout', 'export', 'import') NOT NULL,
    
    -- Change Details
    field_name VARCHAR(100),
    old_value TEXT,
    new_value TEXT,
    change_summary TEXT,
    
    -- Full Record Snapshots (for critical tables)
    old_record_snapshot JSON,
    new_record_snapshot JSON,
    
    -- User & Session Context
    user_id INT,
    impersonated_by_user_id INT, -- If admin is acting as another user
    session_id VARCHAR(128),
    
    -- Request Context
    ip_address VARCHAR(45),
    user_agent TEXT,
    request_method VARCHAR(10),
    request_url VARCHAR(500),
    request_headers JSON,
    request_body JSON,
    response_status_code INT,
    
    -- Business Context
    business_justification TEXT,
    approval_reference VARCHAR(100),
    compliance_tags JSON, -- ["GDPR", "SOX", "HIPAA", etc.]
    
    -- Risk Assessment
    risk_level ENUM('low', 'medium', 'high', 'critical') DEFAULT 'low',
    sensitive_data_involved BOOLEAN DEFAULT FALSE,
    data_classification ENUM('public', 'internal', 'confidential', 'restricted') DEFAULT 'internal',
    
    -- Blockchain-style Integrity
    previous_hash VARCHAR(64),
    current_hash VARCHAR(64),
    merkle_tree_hash VARCHAR(64),
    block_number INT,
    
    -- Timestamps
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (impersonated_by_user_id) REFERENCES users(user_id),
    
    -- Indexes
    INDEX idx_transaction (transaction_id),
    INDEX idx_table_record (table_name, record_id),
    INDEX idx_action (action),
    INDEX idx_user (user_id),
    INDEX idx_timestamp (timestamp),
    INDEX idx_hash (current_hash),
    INDEX idx_risk_level (risk_level),
    INDEX idx_compliance_tags ((CAST(compliance_tags AS CHAR(255) ARRAY)))
);

-- Data Retention Policies
CREATE TABLE data_retention_policies (
    policy_id INT PRIMARY KEY AUTO_INCREMENT,
    policy_name VARCHAR(255) NOT NULL,
    table_name VARCHAR(64) NOT NULL,
    
    -- Retention Rules
    retention_period_days INT NOT NULL,
    retention_criteria JSON, -- Conditions for retention
    
    -- Archival Settings
    archive_before_delete BOOLEAN DEFAULT TRUE,
    archive_location VARCHAR(500),
    archive_format ENUM('json', 'xml', 'csv', 'parquet') DEFAULT 'json',
    
    -- Legal & Compliance
    legal_basis TEXT,
    compliance_requirements JSON, -- ["GDPR", "SOX", etc.]
    data_subject_rights JSON, -- Right to erasure, portability, etc.
    
    -- Processing
    last_processed_date DATE,
    next_processing_date DATE,
    processing_schedule ENUM('daily', 'weekly', 'monthly', 'quarterly', 'annually') DEFAULT 'monthly',
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    
    created_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (created_by) REFERENCES users(user_id),
    
    UNIQUE KEY unique_table_policy (table_name, policy_name),
    INDEX idx_table (table_name),
    INDEX idx_next_processing (next_processing_date),
    INDEX idx_active (is_active)
);

-- ===============================================
-- SAMPLE DATA INSERTION
-- ===============================================

-- Insert System Settings
INSERT INTO system_settings (category, setting_key, setting_value, setting_type, display_name, description, is_system) VALUES
('general', 'system_name', 'Digital Gate Pass System', 'string', 'System Name', 'Name displayed in the application header', FALSE),
('general', 'company_name', 'Your Company Name', 'string', 'Company Name', 'Company name for branding and reports', FALSE),
('general', 'company_logo', '/assets/images/logo.png', 'file', 'Company Logo', 'Company logo file path', FALSE),
('general', 'timezone', 'UTC', 'string', 'System Timezone', 'Default timezone for the system', FALSE),
('general', 'date_format', 'YYYY-MM-DD', 'string', 'Date Format', 'Default date display format', FALSE),
('general', 'time_format', '24', 'string', 'Time Format', '12 or 24 hour time format', FALSE),

('security', 'max_pass_duration_hours', '24', 'integer', 'Max Pass Duration', 'Maximum duration for a gate pass in hours', TRUE),
('security', 'qr_code_refresh_minutes', '15', 'integer', 'QR Code Refresh', 'QR code refresh interval in minutes', TRUE),
('security', 'require_photo_capture', 'true', 'boolean', 'Require Photo', 'Require photo capture for all visitors', FALSE),
('security', 'enable_biometric_verification', 'false', 'boolean', 'Biometric Verification', 'Enable fingerprint/face verification', FALSE),
('security', 'auto_expire_passes', 'true', 'boolean', 'Auto Expire Passes', 'Automatically expire passes after time limit', TRUE),
('security', 'lockdown_mode', 'false', 'boolean', 'Lockdown Mode', 'Enable emergency lockdown mode', FALSE),
('security', 'max_failed_attempts', '3', 'integer', 'Max Failed Attempts', 'Maximum failed login attempts before lockout', TRUE),
('security', 'session_timeout_minutes', '480', 'integer', 'Session Timeout', 'Session timeout in minutes (8 hours default)', TRUE),

('limits', 'max_daily_visitors_global', '1000', 'integer', 'Max Daily Visitors', 'Maximum total visitors per day', FALSE),
('limits', 'max_concurrent_visitors', '500', 'integer', 'Max Concurrent Visitors', 'Maximum visitors in premises at once', FALSE),
('limits', 'max_visitors_per_host', '20', 'integer', 'Max Visitors Per Host', 'Maximum visitors per host per day', FALSE),
('limits', 'visitor_registration_cutoff_hours', '2', 'integer', 'Registration Cutoff', 'Hours before visit when registration closes', FALSE),

('features', 'visitor_self_registration', 'true', 'boolean', 'Visitor Self Registration', 'Allow visitors to self-register', FALSE),
('features', 'require_host_approval', 'false', 'boolean', 'Require Host Approval', 'Require host approval for all visits', FALSE),
('features', 'enable_vehicle_registration', 'true', 'boolean', 'Vehicle Registration', 'Enable vehicle information capture', FALSE),
('features', 'enable_recurring_visits', 'true', 'boolean', 'Recurring Visits', 'Enable recurring visit templates', FALSE),
('features', 'enable_visitor_feedback', 'true', 'boolean', 'Visitor Feedback', 'Enable visitor feedback collection', FALSE),

('notifications', 'email_notifications_enabled', 'true', 'boolean', 'Email Notifications', 'Enable email notifications', FALSE),
('notifications', 'sms_notifications_enabled', 'false', 'boolean', 'SMS Notifications', 'Enable SMS notifications', FALSE),
('notifications', 'push_notifications_enabled', 'true', 'boolean', 'Push Notifications', 'Enable browser push notifications', FALSE),
('notifications', 'notification_sender_email', 'noreply@company.com', 'string', 'Sender Email', 'Email address for outgoing notifications', FALSE),
('notifications', 'emergency_notification_email', 'emergency@company.com', 'string', 'Emergency Email', 'Email for emergency notifications', FALSE),
('notifications', 'emergency_notification_phone', '+1-555-EMERGENCY', 'string', 'Emergency Phone', 'Phone number for emergency notifications', FALSE),

('compliance', 'data_retention_days', '2555', 'integer', 'Data Retention Period', 'Days to retain visitor data (7 years default)', FALSE),
('compliance', 'audit_log_retention_days', '3650', 'integer', 'Audit Log Retention', 'Days to retain audit logs (10 years default)', TRUE),
('compliance', 'enable_data_encryption', 'true', 'boolean', 'Data Encryption', 'Enable database encryption for sensitive data', TRUE),
('compliance', 'enable_audit_logging', 'true', 'boolean', 'Audit Logging', 'Enable comprehensive audit logging', TRUE),
('compliance', 'gdpr_compliance_mode', 'true', 'boolean', 'GDPR Compliance', 'Enable GDPR compliance features', FALSE);

-- Insert Default Users
INSERT INTO users (email, username, password_hash, full_name, role, phone, department, employee_id, is_active, is_verified) VALUES
('admin@company.com', 'admin', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'System Administrator', 'super_admin', '+1-555-0001', 'IT Security', 'ADMIN001', TRUE, TRUE),
('security@company.com', 'security', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Security Guard', 'security', '+1-555-0002', 'Security', 'SEC001', TRUE, TRUE),
('sarah.wilson@company.com', 'sarah.wilson', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Sarah Wilson', 'host', '+1-555-0199', 'Human Resources', 'HR001', TRUE, TRUE),
('mike.johnson@company.com', 'mike.johnson', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Mike Johnson', 'host', '+1-555-0298', 'Operations', 'OPS001', TRUE, TRUE),
('reception@company.com', 'reception', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Reception Desk', 'staff', '+1-555-0300', 'Front Desk', 'REC001', TRUE, TRUE);

-- Insert Sample Hosts
INSERT INTO hosts (user_id, employee_id, full_name, email, phone, department, position, office_location, building, floor, room_number, max_daily_visitors, can_approve_visits) VALUES
(3, 'HR001', 'Sarah Wilson', 'sarah.wilson@company.com', '+1-555-0199', 'Human Resources', 'Senior HR Manager', 'Building A, Floor 3, Room 301', 'A', 3, '301', 25, TRUE),
(4, 'OPS001', 'Mike Johnson', 'mike.johnson@company.com', '+1-555-0298', 'Operations', 'Operations Director', 'Building A, Floor 2, Room 205', 'A', 2, '205', 30, TRUE),
(NULL, 'FIN001', 'Jennifer Davis', 'jennifer.davis@company.com', '+1-555-0397', 'Finance', 'Finance Manager', 'Building B, Floor 1, Room 102', 'B', 1, '102', 15, TRUE),
(NULL, 'IT001', 'Robert Chen', 'robert.chen@company.com', '+1-555-0496', 'IT', 'IT Director', 'Building A, Floor 4, Room 401', 'A', 4, '401', 20, TRUE),
(5, 'REC001', 'Reception Desk', 'reception@company.com', '+1-555-0300', 'Front Desk', 'Receptionist', 'Main Lobby', 'A', 1, 'Lobby', 100, TRUE);

-- Insert Sample Security Zones
INSERT INTO security_zones (zone_code, zone_name, description, building, floor, area_type, security_level, visitor_access_allowed) VALUES
('LOBBY', 'Main Lobby', 'Public reception and waiting area', 'A', 1, 'lobby', 'public', TRUE),
('OFFICE-A2', 'Office Area A2', 'General office space - Floor 2', 'A', 2, 'office', 'restricted', TRUE),
('OFFICE-A3', 'Office Area A3', 'HR and Administration - Floor 3', 'A', 3, 'office', 'restricted', TRUE),
('OFFICE-A4', 'Office Area A4', 'IT Department - Floor 4', 'A', 4, 'office', 'confidential', FALSE),
('SERVER', 'Server Room', 'IT Server and Network Equipment', 'A', 4, 'server_room', 'secret', FALSE),
('PARKING', 'Visitor Parking', 'Designated visitor parking area', 'EXT', 0, 'parking', 'public', TRUE);

-- Insert Sample Visitors
INSERT INTO visitors (visitor_id, full_name, email, phone, company, id_type, id_number, purpose_of_visit, visit_type, emergency_contact_name, emergency_contact_phone, total_visits) VALUES
('V001', 'John Doe', 'john.doe@email.com', '+1-555-0123', 'ABC Corporation', 'drivers_license', 'DL123456789', 'Quarterly business review meeting with HR department to discuss partnership opportunities and contract renewals', 'business', 'Jane Doe', '+1-555-0124', 1),
('V002', 'Jane Smith', 'jane.smith@email.com', '+1-555-0234', 'XYZ Solutions', 'passport', 'P987654321', 'Job interview for Senior Software Developer position in the IT department', 'interview', 'Bob Smith', '+1-555-0235', 0),
('V003', 'Robert Brown', 'robert.brown@delivery.com', '+1-555-0345', 'FastDelivery Inc', 'drivers_license', 'DL987654321', 'Package delivery for Operations department - urgent medical supplies', 'delivery', 'Mary Brown', '+1-555-0346', 15),
('V004', 'Alice Johnson', 'alice.johnson@consulting.com', '+1-555-0456', 'Business Consulting LLC', 'drivers_license', 'DL456789123', 'Digital transformation consultation meeting with senior management', 'consultation', 'Charlie Johnson', '+1-555-0457', 3),
('V005', 'Michael Davis', 'michael.davis@tech.com', '+1-555-0567', 'TechRepair Services', 'national_id', 'ID789123456', 'Network equipment maintenance and server room upgrades', 'maintenance', 'Lisa Davis', '+1-555-0568', 8);

-- Insert Sample Gate Passes
INSERT INTO gate_passes (pass_id, visitor_id, host_id, qr_code_data, qr_code_hash, status, visit_date, scheduled_time_in, scheduled_time_out, destination, security_level, approved_by, approved_at, valid_from, expires_at, generated_by) VALUES
('GP2025091201', 'V001', 1, '{"id":"V001","name":"John Doe","timestamp":"2025-09-12T14:30:00Z","type":"gate_pass","purpose":"Business Meeting","host":"Sarah Wilson","location":"Building A, Floor 3","security_level":"standard","validUntil":"2025-09-12T23:59:59Z"}', 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6', 'active', '2025-09-12', '14:30:00', '17:30:00', 'Building A, Floor 3, Room 301', 'standard', 1, '2025-09-12 09:00:00', '2025-09-12 14:00:00', '2025-09-12 23:59:59', 1),
('GP2025091202', 'V002', 1, '{"id":"V002","name":"Jane Smith","timestamp":"2025-09-12T16:00:00Z","type":"gate_pass","purpose":"Interview","host":"Sarah Wilson","location":"Building A, Floor 3","security_level":"standard","validUntil":"2025-09-12T23:59:59Z"}', 'b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a1', 'approved', '2025-09-12', '16:00:00', '18:00:00', 'Building A, Floor 3, Room 301', 'standard', 1, '2025-09-12 10:00:00', '2025-09-12 15:30:00', '2025-09-12 23:59:59', 1),
('GP2025091203', 'V003', 5, '{"id":"V003","name":"Robert Brown","timestamp":"2025-09-12T13:15:00Z","type":"gate_pass","purpose":"Delivery","host":"Reception","location":"Main Lobby","security_level":"basic","validUntil":"2025-09-12T23:59:59Z"}', 'c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a1b2', 'completed', '2025-09-12', '13:15:00', '14:15:00', 'Main Lobby, Reception Desk', 'basic', 2, '2025-09-12 08:00:00', '2025-09-12 13:00:00', '2025-09-12 23:59:59', 5);

-- Insert Sample Access Logs
INSERT INTO access_logs (pass_id, visitor_id, action_type, access_point, direction, verification_method, verification_status, security_officer_id, device_id, device_type, processing_time_ms) VALUES
('GP2025091201', 'V001', 'entry', 'Gate A', 'in', 'qr_scan', 'success', 2, 'SCANNER001', 'scanner', 1250, '2025-09-12 14:32:15'),
('GP2025091203', 'V003', 'entry', 'Main Entrance', 'in', 'qr_scan', 'success', 2, 'SCANNER001', 'scanner', 890, '2025-09-12 13:17:22'),
('GP2025091203', 'V003', 'exit', 'Main Entrance', 'out', 'manual', 'success', 2, 'TABLET001', 'tablet', 2100, '2025-09-12 14:05:18');

-- Insert Sample Visitor Tracking
INSERT INTO visitor_tracking (visitor_id, pass_id, current_zone_id, current_building, current_floor, is_inside_premises, check_in_time, currently_with_host) VALUES
('V001', 'GP2025091201', 3, 'A', 3, TRUE, '2025-09-12 14:32:15', TRUE),
('V002', 'GP2025091202', NULL, NULL, NULL, FALSE, NULL, FALSE),
('V003', 'GP2025091203', NULL, NULL, NULL, FALSE, '2025-09-12 14:05:18', FALSE);

-- Insert Sample Devices
INSERT INTO device_registry (device_id, device_name, device_type, location, building, zone_id, ip_address, status, capabilities, total_scans_processed, successful_scans, failed_scans) VALUES
('SCANNER001', 'Gate A QR Scanner', 'qr_scanner', 'Gate A - Main Entrance', 'A', 1, '192.168.1.101', 'online', '{"qr_scan": true, "photo": true, "rfid": false, "biometric": false}', 1247, 1199, 48),
('TABLET001', 'Security Desk Tablet', 'tablet', 'Security Control Room', 'A', 1, '192.168.1.102', 'online', '{"qr_scan": true, "manual_entry": true, "photo": true, "video": true}', 856, 832, 24),
('KIOSK001', 'Lobby Check-in Kiosk', 'kiosk', 'Main Lobby', 'A', 1, '192.168.1.103', 'online', '{"self_registration": true, "qr_generate": true, "photo": true, "print": true}', 342, 338, 4);

-- Insert Sample Emergency Contacts
INSERT INTO emergency_contacts (contact_type, organization_name, contact_person, primary_phone, emergency_phone, email, response_time_minutes) VALUES
('fire_department', 'City Fire Department', 'Fire Chief Johnson', '+1-555-FIRE', '+1-911', 'dispatch@cityfire.gov', 8),
('police', 'City Police Department', 'Police Chief Smith', '+1-555-POLICE', '+1-911', 'dispatch@citypolice.gov', 6),
('ambulance', 'City Emergency Medical Services', 'EMS Director Brown', '+1-555-AMBULANCE', '+1-911', 'dispatch@cityems.gov', 10),
('hospital', 'City General Hospital', 'Dr. Sarah Johnson', '+1-555-HOSPITAL', '+1-555-ER', 'emergency@cityhospital.com', 15),
('security_company', 'SecureCorp Security Services', 'Security Manager Wilson', '+1-555-SECURE', '+1-555-SECURE', 'emergency@securecorp.com', 5);

-- Insert Sample Notification Templates
INSERT INTO notification_templates (template_name, notification_type, subject_template, body_template, sms_template, is_active, is_default) VALUES
('Visitor Arrival', 'visitor_arrival', 'Your visitor {{visitor_name}} has arrived', 'Hello {{host_name}},\n\nYour visitor {{visitor_name}} from {{company}} has arrived and checked in at {{entry_time}}.\n\nPurpose: {{purpose}}\nLocation: {{location}}\n\nPlease meet them at the reception area.', '{{visitor_name}} from {{company}} has arrived. Please meet them at reception.', TRUE, TRUE),
('Visitor Late', 'visitor_late', 'Visitor {{visitor_name}} is running late', 'Hello {{host_name}},\n\nYour visitor {{visitor_name}} was scheduled to arrive at {{scheduled_time}} but has not yet checked in.\n\nYou may want to contact them to confirm their arrival time.', '{{visitor_name}} is late for {{scheduled_time}} appointment. Please check with them.', TRUE, TRUE),
('Pass Approved', 'pass_approved', 'Your gate pass has been approved', 'Dear {{visitor_name}},\n\nYour gate pass ({{pass_id}}) has been approved for {{visit_date}}.\n\nPlease present the QR code upon arrival.\n\nHost: {{host_name}}\nLocation: {{destination}}', 'Your gate pass for {{visit_date}} has been approved. Present QR code on arrival.', TRUE, TRUE),
('Security Alert', 'security_alert', 'Security Alert: {{alert_title}}', 'SECURITY ALERT\n\nType: {{alert_type}}\nSeverity: {{severity}}\nLocation: {{location}}\n\nDescription: {{description}}\n\nImmediate attention required.', 'SECURITY ALERT: {{alert_type}} at {{location}}. Immediate attention required.', TRUE, TRUE);

-- ===============================================
-- VIEWS FOR REPORTING AND DASHBOARDS
-- ===============================================

-- Active Visitors Dashboard View
CREATE VIEW v_dashboard_active_visitors AS
SELECT 
    v.visitor_id,
    v.full_name AS visitor_name,
    v.company,
    v.phone,
    gp.pass_id,
    gp.status AS pass_status,
    gp.visit_date,
    gp.scheduled_time_in,
    gp.actual_time_in,
    h.full_name AS host_name,
    h.department,
    h.office_location,
    vt.current_building,
    vt.current_floor,
    vt.current_zone_id,
    sz.zone_name AS current_zone_name,
    vt.is_inside_premises,
    vt.currently_with_host,
    TIMESTAMPDIFF(MINUTE, gp.actual_time_in, NOW()) AS minutes_inside,
    gp.security_level,
    CASE 
        WHEN gp.expires_at < NOW() THEN 'expired'
        WHEN gp.expires_at < DATE_ADD(NOW(), INTERVAL 1 HOUR) THEN 'expiring_soon'
        ELSE 'valid'
    END AS pass_validity_status
FROM visitors v
JOIN gate_passes gp ON v.visitor_id = gp.visitor_id
JOIN hosts h ON gp.host_id = h.host_id
LEFT JOIN visitor_tracking vt ON v.visitor_id = vt.visitor_id AND gp.pass_id = vt.pass_id
LEFT JOIN security_zones sz ON vt.current_zone_id = sz.zone_id
WHERE gp.status IN ('active', 'approved') 
  AND gp.visit_date = CURDATE()
  AND gp.expires_at > NOW()
ORDER BY gp.actual_time_in DESC;

-- Security Dashboard Statistics
CREATE VIEW v_security_dashboard AS
SELECT 
    -- Current Status
    (SELECT COUNT(*) FROM v_dashboard_active_visitors WHERE is_inside_premises = TRUE) AS visitors_currently_inside,
    (SELECT COUNT(*) FROM gate_passes WHERE status = 'pending' AND visit_date = CURDATE()) AS pending_approvals,
    (SELECT COUNT(*) FROM security_alerts WHERE status IN ('new', 'acknowledged', 'investigating')) AS open_security_alerts,
    
    -- Today's Activity
    (SELECT COUNT(*) FROM access_logs WHERE DATE(timestamp) = CURDATE()) AS todays_total_scans,
    (SELECT COUNT(*) FROM access_logs WHERE DATE(timestamp) = CURDATE() AND action_type = 'entry') AS todays_entries,
    (SELECT COUNT(*) FROM access_logs WHERE DATE(timestamp) = CURDATE() AND action_type = 'exit') AS todays_exits,
    (SELECT COUNT(*) FROM access_logs WHERE DATE(timestamp) = CURDATE() AND verification_status = 'failed') AS todays_failed_scans,
    
    -- System Health
    (SELECT COUNT(*) FROM device_registry WHERE status = 'offline') AS offline_devices,
    (SELECT COUNT(*) FROM device_registry WHERE status = 'online') AS online_devices,
    (SELECT ROUND(AVG(health_score), 1) FROM device_registry WHERE is_active = TRUE) AS average_device_health,
    
    -- Alert Statistics
    (SELECT COUNT(*) FROM security_alerts WHERE status IN ('new', 'acknowledged') AND severity IN ('high', 'critical', 'emergency')) AS high_priority_alerts,
    (SELECT COUNT(*) FROM security_alerts WHERE created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)) AS alerts_last_24h,
    
    -- Visitor Statistics
    (SELECT COUNT(DISTINCT visitor_id) FROM gate_passes WHERE visit_date = CURDATE()) AS unique_visitors_today,
    (SELECT COUNT(*) FROM gate_passes WHERE visit_date = CURDATE() AND status = 'completed') AS completed_visits_today,
    (SELECT ROUND(AVG(actual_duration_minutes), 0) FROM gate_passes WHERE visit_date = CURDATE() AND status = 'completed' AND actual_duration_minutes IS NOT NULL) AS avg_visit_duration_today;

-- Host Dashboard Statistics
CREATE VIEW v_host_dashboard AS
SELECT 
    h.host_id,
    h.full_name AS host_name,
    h.department,
    
    -- Today's Visitors
    (SELECT COUNT(*) FROM gate_passes gp WHERE gp.host_id = h.host_id AND gp.visit_date = CURDATE()) AS todays_visitors,
    (SELECT COUNT(*) FROM gate_passes gp WHERE gp.host_id = h.host_id AND gp.visit_date = CURDATE() AND gp.status = 'pending') AS pending_approvals,
    (SELECT COUNT(*) FROM gate_passes gp JOIN visitor_tracking vt ON gp.pass_id = vt.pass_id WHERE gp.host_id = h.host_id AND vt.is_inside_premises = TRUE) AS current_visitors,
    
    -- This Week's Activity
    (SELECT COUNT(*) FROM gate_passes gp WHERE gp.host_id = h.host_id AND gp.visit_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)) AS this_week_visitors,
    
    -- Next Scheduled Visitors
    (SELECT COUNT(*) FROM gate_passes gp WHERE gp.host_id = h.host_id AND gp.visit_date = CURDATE() AND gp.scheduled_time_in > CURRENT_TIME AND gp.status IN ('approved', 'pending')) AS upcoming_today
FROM hosts h
WHERE h.is_active = TRUE
ORDER BY todays_visitors DESC;

-- Visitor Analytics View
CREATE VIEW v_visitor_analytics AS
SELECT 
    v.visitor_id,
    v.full_name,
    v.company,
    v.visit_frequency,
    v.total_visits,
    v.last_visit_date,
    
    -- Current Visit Info (if any)
    gp_current.pass_id AS current_pass_id,
    gp_current.status AS current_status,
    gp_current.visit_date AS current_visit_date,
    
    -- Visit History Summary
    (SELECT COUNT(*) FROM gate_passes gp WHERE gp.visitor_id = v.visitor_id) AS total_gate_passes,
    (SELECT COUNT(*) FROM gate_passes gp WHERE gp.visitor_id = v.visitor_id AND gp.status = 'completed') AS completed_visits,
    (SELECT AVG(gp.actual_duration_minutes) FROM gate_passes gp WHERE gp.visitor_id = v.visitor_id AND gp.actual_duration_minutes IS NOT NULL) AS avg_visit_duration,
    
    -- Risk Assessment
    v.risk_level,
    v.is_blacklisted,
    
    -- Last Activity
    (SELECT MAX(al.timestamp) FROM access_logs al WHERE al.visitor_id = v.visitor_id) AS last_access_log_time,
    
    -- Classification
    CASE 
        WHEN v.total_visits = 0 THEN 'new'
        WHEN v.total_visits BETWEEN 1 AND 3 THEN 'occasional'
        WHEN v.total_visits BETWEEN 4 AND 10 THEN 'regular'
        WHEN v.total_visits > 10 THEN 'frequent'
    END AS visitor_classification
FROM visitors v
LEFT JOIN gate_passes gp_current ON v.visitor_id = gp_current.visitor_id 
    AND gp_current.visit_date = CURDATE() 
    AND gp_current.status IN ('active', 'approved', 'pending')
ORDER BY v.last_visit_date DESC;

-- ===============================================
-- STORED PROCEDURES FOR BUSINESS LOGIC
-- ===============================================

DELIMITER //

-- Generate unique visitor ID
CREATE PROCEDURE sp_generate_visitor_id(OUT new_visitor_id VARCHAR(15))
BEGIN
    DECLARE last_num INT DEFAULT 0;
    DECLARE current_year CHAR(4);
    DECLARE current_month CHAR(2);
    
    SET current_year = YEAR(CURDATE());
    SET current_month = LPAD(MONTH(CURDATE()), 2, '0');
    
    SELECT COALESCE(MAX(CAST(SUBSTRING(visitor_id, 8) AS UNSIGNED)), 0) INTO last_num 
    FROM visitors 
    WHERE visitor_id LIKE CONCAT('V', current_year, current_month, '%');
    
    SET new_visitor_id = CONCAT('V', current_year, current_month, LPAD(last_num + 1, 3, '0'));
END //

-- Generate unique gate pass ID
CREATE PROCEDURE sp_generate_pass_id(OUT new_pass_id VARCHAR(20))
BEGIN
    DECLARE last_num INT DEFAULT 0;
    DECLARE current_date CHAR(8);
    
    SET current_date = DATE_FORMAT(CURDATE(), '%Y%m%d');
    
    SELECT COALESCE(MAX(CAST(SUBSTRING(pass_id, 11) AS UNSIGNED)), 0) INTO last_num 
    FROM gate_passes 
    WHERE pass_id LIKE CONCAT('GP', current_date, '%');
    
    SET new_pass_id = CONCAT('GP', current_date, LPAD(last_num + 1, 2, '0'));
END //

-- Check visitor into premises with comprehensive validation
CREATE PROCEDURE sp_check_in_visitor(
    IN p_pass_id VARCHAR(20),
    IN p_access_point VARCHAR(100),
    IN p_security_officer_id INT,
    IN p_verification_method VARCHAR(20),
    IN p_device_id VARCHAR(100),
    OUT p_result VARCHAR(20),
    OUT p_message TEXT,
    OUT p_visitor_name VARCHAR(255)
)
BEGIN
    DECLARE v_visitor_id VARCHAR(15);
    DECLARE v_host_id INT;
    DECLARE v_status VARCHAR(20);
    DECLARE v_expires_at TIMESTAMP;
    DECLARE v_visitor_name VARCHAR(255);
    DECLARE v_is_blacklisted BOOLEAN DEFAULT FALSE;
    DECLARE v_zone_id INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_result = 'ERROR';
        SET p_message = 'Database error occurred during check-in process';
        SET p_visitor_name = '';
    END;
    
    START TRANSACTION;
    
    -- Get pass and visitor information
    SELECT gp.visitor_id, gp.host_id, gp.status, gp.expires_at, v.full_name, v.is_blacklisted
    INTO v_visitor_id, v_host_id, v_status, v_expires_at, v_visitor_name, v_is_blacklisted
    FROM gate_passes gp
    JOIN visitors v ON gp.visitor_id = v.visitor_id
    WHERE gp.pass_id = p_pass_id;
    
    -- Get zone for access point
    SELECT zone_id INTO v_zone_id FROM security_zones WHERE zone_name = p_access_point LIMIT 1;
    
    SET p_visitor_name = v_visitor_name;
    
    -- Validation checks
    IF v_visitor_id IS NULL THEN
        SET p_result = 'INVALID_PASS';
        SET p_message = 'Pass ID not found in system';
        
        -- Log failed attempt
        INSERT INTO access_logs (pass_id, visitor_id, action_type, access_point, direction, 
                               verification_method, verification_status, failure_reason, 
                               security_officer_id, device_id)
        VALUES (p_pass_id, '', 'denied', p_access_point, 'in', 
                p_verification_method, 'invalid', 'Pass ID not found', 
                p_security_officer_id, p_device_id);
        
    ELSEIF v_is_blacklisted = TRUE THEN
        SET p_result = 'BLACKLISTED';
        SET p_message = CONCAT('Visitor ', v_visitor_name, ' is blacklisted and cannot enter');
        
        -- Create security alert
        INSERT INTO security_alerts (alert_type, severity, title, description, visitor_id, pass_id, location, triggered_by_user_id)
        VALUES ('blacklisted_visitor', 'high', 'Blacklisted Visitor Attempted Entry', 
                CONCAT('Blacklisted visitor ', v_visitor_name, ' attempted to enter at ', p_access_point), 
                v_visitor_id, p_pass_id, p_access_point, p_security_officer_id);
        
    ELSEIF v_expires_at < NOW() THEN
        SET p_result = 'EXPIRED';
        SET p_message = CONCAT('Pass expired at ', DATE_FORMAT(v_expires_at, '%Y-%m-%d %H:%i'));
        
        UPDATE gate_passes SET status = 'expired' WHERE pass_id = p_pass_id;
        
    ELSEIF v_status NOT IN ('approved', 'active') THEN
        SET p_result = 'NOT_APPROVED';
        SET p_message = CONCAT('Pass status is "', v_status, '" - approval required');
        
    ELSE
        -- Successful check-in
        UPDATE gate_passes 
        SET actual_time_in = NOW(), 
            entry_gate = p_access_point,
            status = 'active'
        WHERE pass_id = p_pass_id;
        
        -- Log successful access
        INSERT INTO access_logs (pass_id, visitor_id, action_type, access_point, direction, 
                               verification_method, verification_status, security_officer_id, device_id)
        VALUES (p_pass_id, v_visitor_id, 'entry', p_access_point, 'in', 
                p_verification_method, 'success', p_security_officer_id, p_device_id);
        
        -- Update visitor tracking
        INSERT INTO visitor_tracking (visitor_id, pass_id, current_zone_id, current_building, 
                                    is_inside_premises, check_in_time, currently_with_host)
        VALUES (v_visitor_id, p_pass_id, v_zone_id, 'A', TRUE, NOW(), FALSE)
        ON DUPLICATE KEY UPDATE
            current_zone_id = v_zone_id,
            is_inside_premises = TRUE,
            check_in_time = NOW(),
            current_status = 'checked_in';
        
        -- Create notification for host
        INSERT INTO notifications (recipient_id, notification_type, title, message, priority, visitor_id, pass_id)
        SELECT u.user_id, 'visitor_arrival', 
               CONCAT('Visitor Arrived: ', v_visitor_name),
               CONCAT(v_visitor_name, ' has checked in at ', p_access_point, ' at ', TIME(NOW())),
               'normal', v_visitor_id, p_pass_id
        FROM hosts h
        LEFT JOIN users u ON h.email = u.email
        WHERE h.host_id = v_host_id AND u.user_id IS NOT NULL;
        
        -- Update visitor statistics
        UPDATE visitors 
        SET total_visits = total_visits + 1, 
            last_visit_date = CURDATE()
        WHERE visitor_id = v_visitor_id;
        
        SET p_result = 'SUCCESS';
        SET p_message = CONCAT('Welcome ', v_visitor_name, '! Check-in successful at ', TIME(NOW()));
    END IF;
    
    COMMIT;
END //

-- Emergency evacuation procedure
CREATE PROCEDURE sp_initiate_emergency(
    IN p_emergency_type VARCHAR(50),
    IN p_severity VARCHAR(20),
    IN p_location VARCHAR(100),
    IN p_description TEXT,
    IN p_initiated_by_user_id INT,
    OUT p_emergency_id INT,
    OUT p_visitors_inside INT
)
BEGIN
    DECLARE v_affected_buildings JSON;
    DECLARE v_total_visitors INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_emergency_id = -1;
        SET p_visitors_inside = -1;
    END;
    
    START TRANSACTION;
    
    -- Count current visitors inside
    SELECT COUNT(*) INTO v_total_visitors
    FROM visitor_tracking 
    WHERE is_inside_premises = TRUE;
    
    -- Create emergency record
    INSERT INTO emergency_events (emergency_type, severity, status, title, description, 
                                 primary_location, initiated_by_user_id, total_visitors_inside)
    VALUES (p_emergency_type, p_severity, 'initiated', 
            CONCAT(UPPER(p_emergency_type), ' Emergency'), p_description,
            p_location, p_initiated_by_user_id, v_total_visitors);
    
    SET p_emergency_id = LAST_INSERT_ID();
    SET p_visitors_inside = v_total_visitors;
    
    -- Create high-priority security alert
    INSERT INTO security_alerts (alert_type, severity, title, description, location, 
                                triggered_by_user_id, priority)
    VALUES ('emergency', 'emergency', 
            CONCAT('EMERGENCY: ', UPPER(p_emergency_type)),
            CONCAT('Emergency situation initiated: ', p_description),
            p_location, p_initiated_by_user_id, 1);
    
    -- Send emergency notifications to all security and admin users
    INSERT INTO notifications (recipient_id, notification_type, title, message, priority, emergency_id)
    SELECT user_id, 'emergency',
           CONCAT('EMERGENCY ALERT: ', UPPER(p_emergency_type)),
           CONCAT('Emergency declared at ', p_location, '. Immediate response required. Total visitors inside: ', v_total_visitors),
           'emergency', p_emergency_id
    FROM users 
    WHERE role IN ('admin', 'security', 'super_admin') AND is_active = TRUE;
    
    -- Update visitor tracking for emergency status
    UPDATE visitor_tracking 
    SET emergency_evacuation_status = 'unknown'
    WHERE is_inside_premises = TRUE;
    
    COMMIT;
END //

DELIMITER ;

-- ===============================================
-- TRIGGERS FOR AUTOMATION
-- ===============================================

DELIMITER //

-- Auto-expire passes trigger
CREATE TRIGGER tr_auto_expire_passes
    BEFORE UPDATE ON gate_passes
    FOR EACH ROW
BEGIN
    IF NEW.expires_at < NOW() AND OLD.status IN ('approved', 'active') THEN
        SET NEW.status = 'expired';
    END IF;
END //

-- Audit trail trigger for sensitive tables
CREATE TRIGGER tr_audit_gate_passes
    AFTER UPDATE ON gate_passes
    FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (table_name, record_id, action, old_record_snapshot, new_record_snapshot, user_id, risk_level)
    VALUES (
        'gate_passes',
        NEW.pass_id,
        'update',
        JSON_OBJECT('status', OLD.status, 'actual_time_in', OLD.actual_time_in, 'actual_time_out', OLD.actual_time_out),
        JSON_OBJECT('status', NEW.status, 'actual_time_in', NEW.actual_time_in, 'actual_time_out', NEW.actual_time_out),
        NEW.approved_by,
        CASE NEW.security_level 
            WHEN 'maximum' THEN 'critical'
            WHEN 'high' THEN 'high'
            ELSE 'medium'
        END
    );
END //

-- Security alert auto-resolution trigger
CREATE TRIGGER tr_auto_resolve_security_alerts
    AFTER INSERT ON access_logs
    FOR EACH ROW
BEGIN
    -- Auto-resolve expired pass alerts when visitor successfully exits
    IF NEW.action_type = 'exit' AND NEW.verification_status = 'success' THEN
        UPDATE security_alerts 
        SET status = 'resolved', 
            auto_resolved = TRUE,
            resolved_at = NOW(),
            resolution_summary = 'Auto-resolved: Visitor successfully checked out'
        WHERE visitor_id = NEW.visitor_id 
          AND alert_type IN ('expired_pass', 'suspicious_behavior')
          AND status IN ('new', 'acknowledged');
    END IF;
END //

-- Update visitor statistics trigger
CREATE TRIGGER tr_update_visitor_stats
    AFTER UPDATE ON gate_passes
    FOR EACH ROW
BEGIN
    -- Update average visit duration when pass is completed
    IF NEW.status = 'completed' AND OLD.status != 'completed' AND NEW.actual_duration_minutes IS NOT NULL THEN
        UPDATE visitors 
        SET average_visit_duration_minutes = (
            SELECT ROUND(AVG(actual_duration_minutes))
            FROM gate_passes 
            WHERE visitor_id = NEW.visitor_id 
              AND actual_duration_minutes IS NOT NULL 
              AND status = 'completed'
        )
        WHERE visitor_id = NEW.visitor_id;
    END IF;
END //

DELIMITER ;

-- ===============================================
-- INDEXES FOR PERFORMANCE OPTIMIZATION
-- ===============================================

-- Additional performance indexes
CREATE INDEX idx_gate_passes_composite ON gate_passes(status, visit_date, expires_at);
CREATE INDEX idx_access_logs_composite ON access_logs(timestamp, action_type, verification_status);
CREATE INDEX idx_visitor_tracking_composite ON visitor_tracking(is_inside_premises, current_status);
CREATE INDEX idx_security_alerts_composite ON security_alerts(status, severity, created_at);
CREATE INDEX idx_notifications_composite ON notifications(recipient_id, is_read, priority, created_at);

-- Full-text search indexes
ALTER TABLE visitors ADD FULLTEXT(full_name, company, purpose_of_visit);
ALTER TABLE security_alerts ADD FULLTEXT(title, description);
ALTER TABLE gate_passes ADD FULLTEXT(visit_purpose_detailed, special_instructions);

-- ===============================================
-- SAMPLE USAGE QUERIES
-- ===============================================

/*
-- Dashboard queries
SELECT * FROM v_security_dashboard;
SELECT * FROM v_dashboard_active_visitors WHERE is_inside_premises = TRUE;
SELECT * FROM v_host_dashboard WHERE host_id = 1;

-- Check in a visitor
CALL sp_check_in_visitor('GP2025091201', 'Gate A', 2, 'qr_scan', 'SCANNER001', @result, @message, @visitor_name);
SELECT @result as result, @message as message, @visitor_name as visitor;

-- Generate new visitor ID
CALL sp_generate_visitor_id(@new_id);
SELECT @new_id as new_visitor_id;

-- Emergency evacuation
CALL sp_initiate_emergency('fire', 'high', 'Building A', 'Fire detected in server room', 1, @emergency_id, @visitors_count);
SELECT @emergency_id as emergency_id, @visitors_count as visitors_inside;

-- Security analytics
SELECT 
    DATE(timestamp) as date,
    COUNT(*) as total_scans,
    COUNT(CASE WHEN verification_status = 'success' THEN 1 END) as successful,
    COUNT(CASE WHEN verification_status = 'failed' THEN 1 END) as failed,
    ROUND(AVG(processing_time_ms), 2) as avg_processing_time
FROM access_logs 
WHERE timestamp >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY DATE(timestamp)
ORDER BY date DESC;

-- Visitor behavior analysis
SELECT 
    v.visitor_id,
    v.full_name,
    COUNT(gp.pass_id) as total_visits,
    AVG(gp.actual_duration_minutes) as avg_duration,
    MAX(gp.visit_date) as last_visit,
    v.risk_level
FROM visitors v
JOIN gate_passes gp ON v.visitor_id = gp.visitor_id
WHERE gp.status = 'completed'
GROUP BY v.visitor_id, v.full_name, v.risk_level
HAVING total_visits > 1
ORDER BY total_visits DESC, last_visit DESC;
*/

-- ===============================================
-- END OF COMPREHENSIVE DATABASE SCHEMA
-- ===============================================