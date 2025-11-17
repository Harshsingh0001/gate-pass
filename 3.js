var dashboard = null;

function VisitorDashboard() {
  this.currentUser = null;
  this.qrCode = null;
  this.refreshInterval = null;

  // -------- INIT --------
  this.init = function () {
    this.checkSession();
    this.updateUserInfo();
    this.generateQR();
    this.setupAutoRefresh();
    this.updateDateTime();
  };

  // -------- SESSION CHECK --------
  this.checkSession = function () {
    var session = sessionStorage.getItem('gatePassSession');
    if (!session) {
      this.redirectToLogin();
      return;
    }

    var sessionData = JSON.parse(session);

    if (sessionData.role !== 'visitor') {
      this.showNotification('Access denied. Visitor account required.', 'error');
      this.redirectToLogin();
      return;
    }

    var loginTime = new Date(sessionData.loginTime);
    var now = new Date();
    var hoursDiff = (now - loginTime) / (1000 * 60 * 60);

    if (hoursDiff > 8) {
      this.showNotification('Session expired. Please login again.', 'error');
      sessionStorage.removeItem('gatePassSession');
      this.redirectToLogin();
      return;
    }

    this.currentUser = sessionData;
  };

  // -------- UPDATE USER INFO --------
  this.updateUserInfo = function () {
    if (this.currentUser) {
      document.getElementById('userName').textContent = this.currentUser.name;
      document.getElementById('welcomeName').textContent = this.currentUser.name;
      document.getElementById('passId').textContent = this.currentUser.id;

      var initials = this.currentUser.name.trim().split(' ').filter(Boolean).map(n => n[0]).join('');
      document.getElementById('userAvatar').textContent = initials;

      var hostName = 'Sarah Wilson';
      var hostInitials = hostName.split(' ').map(function (n) { return n[0]; }).join('');
      document.getElementById('hostAvatar').textContent = hostInitials;
      document.getElementById('hostName').textContent = hostName;

      var purposes = {
        'V001': 'Business Meeting',
        'V002': 'Interview',
        'V003': 'Delivery'
      };
      document.getElementById('visitPurpose').textContent =
        purposes[this.currentUser.id] || 'General Visit';
    }
  };

  // -------- GENERATE QR --------
  this.generateQR = function () {
    var self = this;
    var qrData = {
      id: this.currentUser.id,
      name: this.currentUser.name,
      timestamp: new Date().toISOString(),
      type: 'gate_pass',
      purpose: document.getElementById('visitPurpose').textContent,
      host: document.getElementById('hostName').textContent,
      location: 'Building A, Floor 3',
      validUntil: new Date(Date.now() + 8 * 60 * 60 * 1000).toISOString()
    };

    var qrContainer = document.getElementById('qrcode');
    qrContainer.innerHTML = ""; // clear old QR

    var canvas = document.createElement("canvas");
    qrContainer.appendChild(canvas);

    QRCode.toCanvas(
      canvas,
      JSON.stringify(qrData),
      {
        width: 256,
        height: 256,
        colorDark: '#059669',
        colorLight: '#ffffff',
        margin: 2
      },
      function (error) {
        if (error) {
          self.showNotification('Failed to generate QR code', 'error');
        } else {
          self.updateGeneratedTime();
          self.showNotification('QR code generated successfully!', 'success');
        }
      }
    );
  };

  this.updateGeneratedTime = function () {
    var now = new Date();
    document.getElementById('generatedTime').textContent = now.toLocaleTimeString();
  };

  this.updateDateTime = function () {
    var now = new Date();
    var dateTimeStr = now.toLocaleDateString() + ', ' + now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    document.getElementById('visitDateTime').textContent = dateTimeStr;
  };

  this.setupAutoRefresh = function () {
    var self = this;
    this.refreshInterval = setInterval(function () {
      self.generateQR();
    }, 5 * 60 * 1000);
  };

  // -------- DOWNLOAD --------
  this.downloadQR = function () {
    var canvas = document.querySelector('#qrcode canvas');
    if (canvas) {
      var link = document.createElement('a');
      link.download = 'gate-pass-' + this.currentUser.id + '-' + Date.now() + '.png';
      link.href = canvas.toDataURL('image/png', 1.0);
      link.click();
      this.showNotification('QR code downloaded successfully!', 'success');
    } else {
      this.showNotification('No QR code to download', 'error');
    }
  };

  // -------- LOGOUT --------
  this.logout = function () {
    sessionStorage.removeItem('gatePassSession');
    this.showNotification('You have been logged out.', 'info');
    this.redirectToLogin();
  };

  // -------- PRINT --------
  this.printQR = function () {
    var canvas = document.querySelector('#qrcode canvas');
    if (canvas) {
      var dataUrl = canvas.toDataURL('image/png');
      var printWindow = window.open('', '', 'width=400,height=400');
      printWindow.document.write('<img src="' + dataUrl + '">');
      printWindow.document.close();
      printWindow.print();
    } else {
      this.showNotification('No QR code to print', 'error');
    }
  };

  // -------- REFRESH --------
  this.refreshQR = function () {
    this.showNotification('Refreshing QR code...', 'info');
    this.generateQR();
  };

  // -------- SHARE --------
  this.sharePass = function () {
    this.showNotification('Sharing pass is not fully supported in all browsers.', 'info');
  };

  // -------- EXTEND VISIT --------
  this.extendVisit = function () {
    this.showNotification('Request to extend visit sent.', 'success');
  };

  // -------- REPORT ISSUE --------
  this.reportIssue = function () {
    this.showNotification('Issue reported. Admin notified.', 'info');
  };

  // -------- FIND LOCATION --------
  this.findLocation = function () {
    this.showNotification('Opening building map...', 'info');
  };

  // -------- CHECK OUT --------
  this.checkOut = function () {
    this.showNotification('You have checked out. Thank you!', 'success');
    sessionStorage.removeItem('gatePassSession');
    this.redirectToLogin();
  };

  // -------- CALL / EMAIL HOST --------
  this.callHost = function () {
    window.location.href = 'tel:+911234567890'; // replace with real host number
  };

  this.emailHost = function () {
    window.location.href = 'mailto:host@example.com'; // replace with real host email
  };

  // -------- EMERGENCY --------
  this.triggerEmergency = function () {
    this.showNotification('Emergency alert sent to security!', 'error');
  };

  // -------- HELPERS --------
  this.redirectToLogin = function () {
    try {
      window.location.href = 'login.html';
    } catch (error) {
      window.location.replace('login.html');
    }
  };

  this.showNotification = function (message, type) {
    try {
      var existingNotifications = document.querySelectorAll('.notification');
      for (var i = 0; i < existingNotifications.length; i++) {
        existingNotifications[i].remove();
      }

      var notification = document.createElement('div');
      notification.className = 'notification ' + (type || 'info');

      var iconClass = 'fas fa-info-circle';
      if (type === 'success') iconClass = 'fas fa-check-circle';
      if (type === 'error') iconClass = 'fas fa-exclamation-circle';

      notification.innerHTML =
        '<div style="display: flex; align-items: center; gap: 0.5rem;">' +
        '<i class="' + iconClass + '"></i>' +
        '<span>' + message + '</span>' +
        '</div>';

      document.body.appendChild(notification);

      setTimeout(function () {
        if (notification && notification.parentNode) {
          notification.style.animation = 'slideOut 0.3s ease';
          setTimeout(function () {
            if (notification && notification.parentNode) {
              notification.parentNode.removeChild(notification);
            }
          }, 300);
        }
      }, 4000);
    } catch (error) {
      console.log(type + ': ' + message);
    }
  };
}

// -------- GLOBAL WRAPPERS (for HTML onclick) --------
function logoutUser() { if (dashboard) dashboard.logout(); }
function downloadQRCode() { if (dashboard) dashboard.downloadQR(); }
function printQRCode() { if (dashboard) dashboard.printQR(); }
function refreshQRCode() { if (dashboard) dashboard.refreshQR(); }
function shareQRPass() { if (dashboard) dashboard.sharePass(); }
function extendVisit() { if (dashboard) dashboard.extendVisit(); }
function reportIssue() { if (dashboard) dashboard.reportIssue(); }
function findLocation() { if (dashboard) dashboard.findLocation(); }
function checkOutVisitor() { if (dashboard) dashboard.checkOut(); }
function callHost() { if (dashboard) dashboard.callHost(); }
function emailHost() { if (dashboard) dashboard.emailHost(); }
function triggerEmergency() { if (dashboard) dashboard.triggerEmergency(); }

// -------- INITIALIZE --------
document.addEventListener('DOMContentLoaded', function () {
  dashboard = new VisitorDashboard();
  dashboard.init();
});
