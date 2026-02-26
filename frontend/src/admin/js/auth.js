// ============================================
// Admin Auth Module - Cognito OAuth Flow
//
// Handles login/logout with AWS Cognito Hosted UI.
// In dev mode (no Cognito config), bypasses auth
// so the dashboard works without AWS credentials.
// ============================================

(function () {
  "use strict";

  // --- Cognito configuration ---
  // In production these come from the deployed environment.
  // In dev mode (docker compose), these are empty and auth is bypassed.
  var AUTH_CONFIG = {
    userPoolId: "",
    clientId: "",
    region: "eu-central-1",
    domain: "",
    redirectUri: window.location.origin + "/admin/callback.html",
    logoutUri: window.location.origin + "/admin/login.html",
  };

  // Check if we're in dev mode (no Cognito configured)
  function isDevMode() {
    return (
      !AUTH_CONFIG.userPoolId || !AUTH_CONFIG.clientId || !AUTH_CONFIG.domain
    );
  }

  // --- Token storage (sessionStorage = cleared when tab closes) ---

  function getAccessToken() {
    return sessionStorage.getItem("admin_access_token");
  }

  function getIdToken() {
    return sessionStorage.getItem("admin_id_token");
  }

  function storeTokens(accessToken, idToken) {
    sessionStorage.setItem("admin_access_token", accessToken);
    if (idToken) {
      sessionStorage.setItem("admin_id_token", idToken);
    }
  }

  function clearTokens() {
    sessionStorage.removeItem("admin_access_token");
    sessionStorage.removeItem("admin_id_token");
  }

  // --- JWT decoding (no verification -- server does that) ---

  function decodeJwtPayload(token) {
    try {
      var base64 = token.split(".")[1];
      var json = atob(base64.replace(/-/g, "+").replace(/_/g, "/"));
      return JSON.parse(json);
    } catch (e) {
      return null;
    }
  }

  // --- Auth state ---

  function isAuthenticated() {
    if (isDevMode()) {
      return true;
    }

    var token = getAccessToken();
    if (!token) {
      return false;
    }

    // Check if token is expired
    var payload = decodeJwtPayload(token);
    if (!payload || !payload.exp) {
      return false;
    }

    // exp is in seconds, Date.now() is in milliseconds
    return payload.exp * 1000 > Date.now();
  }

  // Get the current user's email from the ID token
  function getUserEmail() {
    if (isDevMode()) {
      return "admin@localhost";
    }
    var token = getIdToken();
    if (!token) return null;
    var payload = decodeJwtPayload(token);
    return payload ? payload.email : null;
  }

  // --- Login flow ---

  function login() {
    if (isDevMode()) {
      // In dev mode, go straight to dashboard
      window.location.href = "/admin/index.html";
      return;
    }

    // Build Cognito Hosted UI URL
    var params = new URLSearchParams({
      client_id: AUTH_CONFIG.clientId,
      response_type: "code",
      scope: "openid email profile",
      redirect_uri: AUTH_CONFIG.redirectUri,
    });

    var url = "https://" + AUTH_CONFIG.domain + "/login?" + params.toString();
    window.location.href = url;
  }

  // --- Callback handler (exchanges auth code for tokens) ---

  async function handleCallback() {
    if (isDevMode()) {
      window.location.href = "/admin/index.html";
      return;
    }

    var urlParams = new URLSearchParams(window.location.search);
    var code = urlParams.get("code");
    var error = urlParams.get("error");

    if (error) {
      throw new Error(
        "Auth error: " + (urlParams.get("error_description") || error),
      );
    }

    if (!code) {
      throw new Error("No authorization code in callback URL");
    }

    // Exchange the code for tokens via Cognito token endpoint
    var tokenUrl = "https://" + AUTH_CONFIG.domain + "/oauth2/token";
    var body = new URLSearchParams({
      grant_type: "authorization_code",
      client_id: AUTH_CONFIG.clientId,
      code: code,
      redirect_uri: AUTH_CONFIG.redirectUri,
    });

    var response = await fetch(tokenUrl, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: body.toString(),
    });

    if (!response.ok) {
      throw new Error("Token exchange failed: " + response.status);
    }

    var data = await response.json();
    storeTokens(data.access_token, data.id_token);

    // Redirect to dashboard
    window.location.href = "/admin/index.html";
  }

  // --- Logout ---

  function logout() {
    clearTokens();

    if (isDevMode()) {
      window.location.href = "/admin/login.html";
      return;
    }

    // Redirect to Cognito logout endpoint
    var params = new URLSearchParams({
      client_id: AUTH_CONFIG.clientId,
      logout_uri: AUTH_CONFIG.logoutUri,
    });

    var url = "https://" + AUTH_CONFIG.domain + "/logout?" + params.toString();
    window.location.href = url;
  }

  // --- Auth-aware fetch wrapper ---

  async function authFetch(url, options) {
    options = options || {};
    options.headers = options.headers || {};

    // Add Authorization header if we have a token
    var token = getAccessToken();
    if (token) {
      options.headers["Authorization"] = "Bearer " + token;
    }

    // Set Content-Type for JSON bodies
    if (options.body && typeof options.body === "string") {
      options.headers["Content-Type"] =
        options.headers["Content-Type"] || "application/json";
    }

    return fetch(url, options);
  }

  // --- Page guard (redirect to login if not authenticated) ---

  function requireLogin() {
    if (!isAuthenticated()) {
      window.location.href = "/admin/login.html";
    }
  }

  // --- Expose public API ---
  window.AdminAuth = {
    isDevMode: isDevMode,
    isAuthenticated: isAuthenticated,
    getUserEmail: getUserEmail,
    login: login,
    handleCallback: handleCallback,
    logout: logout,
    authFetch: authFetch,
    requireLogin: requireLogin,
  };
})();
