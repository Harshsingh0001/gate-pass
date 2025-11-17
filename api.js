// API Configuration
const API_BASE_URL = 'http://localhost:5000/api';

// API Service for making HTTP requests
class GatePassAPI {
  constructor() {
    this.token = sessionStorage.getItem('gatePassToken');
    // If we have a token but no session, try to decode token payload and set a minimal session
    try {
      const sess = sessionStorage.getItem('gatePassSession');
      if (!sess && this.token) {
        const parts = this.token.split('.');
        if (parts.length === 3) {
          // Decode base64url payload (works in browser)
          const b64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
          try {
            const json = decodeURIComponent(Array.prototype.map.call(atob(b64), function(c) {
              return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
            }).join(''));
            const payload = JSON.parse(json);
          const minimal = {
            id: payload.id || payload.sub || null,
            email: payload.email || null,
            role: payload.role || null,
            name: payload.name || null,
            loginTime: new Date().toISOString()
          };
            sessionStorage.setItem('gatePassSession', JSON.stringify(minimal));
          } catch (e) {
            // invalid token payload, ignore
          }
        }
      }
    } catch (e) {
      // ignore any decode errors
    }
  }

  // Set token after login
  setToken(token) {
    this.token = token;
    sessionStorage.setItem('gatePassToken', token);
  }

  // Get auth headers
  getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${this.token}`
    };
  }

  // Login
  async login(username, password) {
    try {
      const response = await fetch(`${API_BASE_URL}/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password })
      });

      const data = await response.json();
      
      if (data.success) {
        this.setToken(data.token);
        sessionStorage.setItem('gatePassSession', JSON.stringify(data.user));
      }
      
      return data;
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  // Register Visitor
  async registerVisitor(fullName, email, contact, purpose, host) {
    try {
      const response = await fetch(`${API_BASE_URL}/register-visitor`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ fullName, email, contact, purpose, host })
      });

      const data = await response.json();
      
      if (data.success) {
        this.setToken(data.token);
        sessionStorage.setItem('gatePassSession', JSON.stringify(data.visitor));
      }
      
      return data;
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  // Register Admin
  async registerAdmin(adminName, email, contact, department, employeeId, password) {
    try {
      const response = await fetch(`${API_BASE_URL}/register-admin`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ adminName, email, contact, department, employeeId, password })
      });

      const data = await response.json();
      
      if (data.success) {
        this.setToken(data.token);
        sessionStorage.setItem('gatePassSession', JSON.stringify(data.admin));
      }
      
      return data;
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  // Get visitor details
  async getVisitor(visitorId) {
    try {
      const response = await fetch(`${API_BASE_URL}/visitors/${visitorId}`, {
        method: 'GET',
        headers: this.getHeaders()
      });

      const data = await response.json();
      return data;
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  // Get all visitors
  async getAllVisitors() {
    try {
      const response = await fetch(`${API_BASE_URL}/visitors`, {
        method: 'GET',
        headers: this.getHeaders()
      });

      const data = await response.json();
      return data;
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  // Generate QR Code
  async generateQR(visitorId, purpose, host, location) {
    try {
      const response = await fetch(`${API_BASE_URL}/generate-qr`, {
        method: 'POST',
        headers: this.getHeaders(),
        body: JSON.stringify({ visitorId, purpose, host, location })
      });

      const data = await response.json();
      return data;
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  // Verify QR Code
  async verifyQR(qrData) {
    try {
      const response = await fetch(`${API_BASE_URL}/verify-qr`, {
        method: 'POST',
        headers: this.getHeaders(),
        body: JSON.stringify({ qrData })
      });

      const data = await response.json();
      return data;
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  // Check in/out
  async checkInOut(visitorId, action, gate) {
    try {
      const response = await fetch(`${API_BASE_URL}/checkin-checkout`, {
        method: 'POST',
        headers: this.getHeaders(),
        body: JSON.stringify({ visitorId, action, gate })
      });

      const data = await response.json();
      return data;
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  // Get admin stats
  async getAdminStats() {
    try {
      const response = await fetch(`${API_BASE_URL}/admin/stats`, {
        method: 'GET',
        headers: this.getHeaders()
      });

      const data = await response.json();
      return data;
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  // Get admin activity
  async getAdminActivity() {
    try {
      const response = await fetch(`${API_BASE_URL}/admin/activity`, {
        method: 'GET',
        headers: this.getHeaders()
      });

      const data = await response.json();
      return data;
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  // Revoke (delete) a visitor (admin only)
  async revokeVisitor(visitorId) {
    try {
      const response = await fetch(`${API_BASE_URL}/visitors/${visitorId}`, {
        method: 'DELETE',
        headers: this.getHeaders()
      });

      const data = await response.json();
      return data;
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  // Health check
  async healthCheck() {
    try {
      const response = await fetch(`${API_BASE_URL}/health`);
      const data = await response.json();
      return data;
    } catch (error) {
      return { success: false, error: error.message };
    }
  }
}

// Create global API instance
const gatePassAPI = new GatePassAPI();
