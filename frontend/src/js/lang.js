// ============================================
// Language Toggle - DE/EN switch for blog posts
//
// Persists language choice in localStorage.
// Pages that support translation (blog.html, post.html)
// read this value and pass ?lang=en to the API.
//
// The toggle button (id="lang-toggle") must be present
// in the page header. Label (id="lang-label") shows
// current language: "DE" or "EN".
//
// Other pages (about, skills, impressum, etc.) show the
// toggle but don't reload content -- they are static German.
// ============================================

(function () {
  "use strict";

  var STORAGE_KEY = "blogLanguage";

  // --- Get the current language from localStorage ---
  function getLanguage() {
    try {
      return localStorage.getItem(STORAGE_KEY) || "de";
    } catch (e) {
      return "de";
    }
  }

  // --- Save language to localStorage ---
  function setLanguage(lang) {
    try {
      localStorage.setItem(STORAGE_KEY, lang);
    } catch (e) {
      // localStorage not available, ignore
    }
  }

  // --- Update the toggle button label ---
  function updateLabel(lang) {
    var label = document.getElementById("lang-label");
    if (label) {
      label.textContent = lang.toUpperCase();
    }

    // Visual feedback: highlight button when EN is active
    var btn = document.getElementById("lang-toggle");
    if (btn) {
      if (lang === "en") {
        btn.classList.add("text-sky-500", "dark:text-sky-400");
        btn.classList.remove("text-slate-500", "dark:text-slate-400");
      } else {
        btn.classList.remove("text-sky-500", "dark:text-sky-400");
        btn.classList.add("text-slate-500", "dark:text-slate-400");
      }
    }
  }

  // --- Initialize toggle on DOM ready ---
  function init() {
    var lang = getLanguage();
    updateLabel(lang);

    var btn = document.getElementById("lang-toggle");
    if (!btn) return;

    btn.addEventListener("click", function () {
      var current = getLanguage();
      var next = current === "de" ? "en" : "de";
      setLanguage(next);
      updateLabel(next);

      // Dispatch custom event so page scripts can react
      window.dispatchEvent(
        new CustomEvent("languageChanged", { detail: { language: next } }),
      );
    });
  }

  // Export for use by other scripts
  window.blogLang = {
    get: getLanguage,
    set: setLanguage,
  };

  document.addEventListener("DOMContentLoaded", init);
})();
