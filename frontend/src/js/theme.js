// ============================================
// Theme Toggle - Dark/Light Mode
//
// Handles switching between dark and light mode.
// Dark mode is the default. User preference is
// saved in localStorage so it persists across visits.
// ============================================

(function () {
  "use strict";

  // --- Read saved preference or default to dark ---
  function getTheme() {
    // Check if user has a saved preference
    var saved = localStorage.getItem("theme");
    if (saved === "light" || saved === "dark") {
      return saved;
    }
    // Default: dark mode
    return "dark";
  }

  // --- Apply theme to the page ---
  function applyTheme(theme) {
    // Tailwind uses the "dark" class on <html> to activate dark: styles
    if (theme === "dark") {
      document.documentElement.classList.add("dark");
    } else {
      document.documentElement.classList.remove("dark");
    }

    // Update the toggle button icons
    var sunIcon = document.getElementById("theme-icon-sun");
    var moonIcon = document.getElementById("theme-icon-moon");
    if (sunIcon && moonIcon) {
      // In dark mode: show sun icon (click to go light)
      // In light mode: show moon icon (click to go dark)
      sunIcon.classList.toggle("hidden", theme !== "dark");
      moonIcon.classList.toggle("hidden", theme !== "light");
    }
  }

  // --- Toggle between dark and light ---
  function toggleTheme() {
    var current = getTheme();
    var next = current === "dark" ? "light" : "dark";
    localStorage.setItem("theme", next);
    applyTheme(next);
  }

  // --- Initialize on page load ---
  // Apply theme immediately (before page renders) to avoid flash
  applyTheme(getTheme());

  // Set up the toggle button once the DOM is ready
  document.addEventListener("DOMContentLoaded", function () {
    var toggleBtn = document.getElementById("theme-toggle");
    if (toggleBtn) {
      toggleBtn.addEventListener("click", toggleTheme);
    }
    // Re-apply to make sure icons are correct
    applyTheme(getTheme());
  });
})();
