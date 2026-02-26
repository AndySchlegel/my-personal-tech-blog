// ============================================
// Comment Moderation Logic
//
// Handles the admin comment moderation page:
//   - loadComments(status?) fetches all comments from /api/admin/comments
//   - renderComments(comments) renders the list with action buttons
//   - updateStatus(id, status) changes a comment's status via API
//   - Filter buttons switch between all/pending/approved/flagged
// ============================================

(function () {
  "use strict";

  // --- State ---
  var currentFilter = "all";

  // --- DOM references ---
  var commentListEl, filtersEl;

  // --- Status badge HTML ---
  function statusBadge(status) {
    var colors = {
      pending: "bg-sky-500/10 text-sky-600 dark:text-sky-400 border-sky-500/20",
      approved:
        "bg-green-500/10 text-green-600 dark:text-green-400 border-green-500/20",
      flagged: "bg-red-500/10 text-red-600 dark:text-red-400 border-red-500/20",
      deleted: "bg-slate-500/10 text-slate-500 border-slate-500/20",
    };
    var cls = colors[status] || colors.pending;
    return (
      '<span class="inline-flex px-2 py-0.5 text-[11px] font-semibold uppercase tracking-wider border rounded-full ' +
      cls +
      '">' +
      status +
      "</span>"
    );
  }

  // --- Format date ---
  function formatDate(dateString) {
    if (!dateString) return "--";
    var d = new Date(dateString);
    return d.toLocaleDateString("en-US", {
      month: "short",
      day: "numeric",
      year: "numeric",
    });
  }

  // --- Truncate text ---
  function truncate(text, maxLen) {
    if (!text) return "";
    return text.length > maxLen ? text.substring(0, maxLen) + "..." : text;
  }

  // --- Load comments from API ---
  async function loadComments(status) {
    commentListEl.innerHTML =
      '<div class="p-6 text-center text-sm text-slate-400 dark:text-slate-500 bg-white dark:bg-slate-800/50 rounded-xl border border-slate-200 dark:border-slate-700/50">Loading...</div>';

    var url = "/api/admin/comments";
    if (status && status !== "all") {
      url += "?status=" + encodeURIComponent(status);
    }

    var comments = [];
    try {
      var response = await AdminAuth.authFetch(url);
      if (response.ok) {
        comments = await response.json();
      }
    } catch (err) {
      console.warn("Failed to load comments:", err.message);
    }

    renderComments(comments);
  }

  // --- Render comment list ---
  function renderComments(comments) {
    if (comments.length === 0) {
      var filterLabel =
        currentFilter === "all" ? "" : ' with status "' + currentFilter + '"';
      commentListEl.innerHTML =
        '<div class="p-8 text-center bg-white dark:bg-slate-800/50 rounded-xl border border-slate-200 dark:border-slate-700/50">' +
        '<i class="ti ti-message-off text-4xl text-slate-300 dark:text-slate-600 mb-3 block"></i>' +
        '<p class="text-sm text-slate-400 dark:text-slate-500">No comments' +
        filterLabel +
        "</p>" +
        "</div>";
      return;
    }

    var html = "";
    comments.forEach(function (comment) {
      // Determine which action buttons to show based on current status
      var actions = "";

      if (comment.status !== "approved") {
        actions +=
          '<button class="admin-action-btn admin-action-approve" data-id="' +
          comment.id +
          '" title="Approve">' +
          '<i class="ti ti-check"></i>' +
          "</button>";
      }

      if (comment.status !== "flagged") {
        actions +=
          '<button class="admin-action-btn admin-action-flag" data-id="' +
          comment.id +
          '" title="Flag">' +
          '<i class="ti ti-flag"></i>' +
          "</button>";
      }

      actions +=
        '<button class="admin-action-btn admin-action-delete" data-id="' +
        comment.id +
        '" title="Delete">' +
        '<i class="ti ti-trash"></i>' +
        "</button>";

      html +=
        '<div class="bg-white dark:bg-slate-800/50 rounded-xl border border-slate-200 dark:border-slate-700/50 p-4 admin-comment-card">' +
        '<div class="flex items-start justify-between gap-3">' +
        '<div class="min-w-0 flex-1">' +
        // Author + status badge
        '<div class="flex items-center gap-2 mb-2">' +
        '<span class="text-sm font-semibold text-slate-900 dark:text-white">' +
        comment.author_name +
        "</span>" +
        statusBadge(comment.status) +
        "</div>" +
        // Content
        '<p class="text-sm text-slate-600 dark:text-slate-300 leading-relaxed mb-2">' +
        truncate(comment.content, 200) +
        "</p>" +
        // Post link + date
        '<p class="text-xs text-slate-400 dark:text-slate-500">' +
        "on " +
        '<span class="text-slate-500 dark:text-slate-400 font-medium">' +
        (comment.post_title
          ? truncate(comment.post_title, 50)
          : "Unknown post") +
        "</span>" +
        " &middot; " +
        formatDate(comment.created_at) +
        "</p>" +
        "</div>" +
        // Actions
        '<div class="flex items-center gap-1 flex-shrink-0">' +
        actions +
        "</div>" +
        "</div>" +
        "</div>";
    });

    commentListEl.innerHTML = html;

    // Attach event listeners
    commentListEl
      .querySelectorAll(".admin-action-approve")
      .forEach(function (btn) {
        btn.addEventListener("click", function () {
          updateStatus(parseInt(btn.getAttribute("data-id"), 10), "approved");
        });
      });

    commentListEl
      .querySelectorAll(".admin-action-flag")
      .forEach(function (btn) {
        btn.addEventListener("click", function () {
          updateStatus(parseInt(btn.getAttribute("data-id"), 10), "flagged");
        });
      });

    commentListEl
      .querySelectorAll(".admin-action-delete")
      .forEach(function (btn) {
        btn.addEventListener("click", function () {
          var id = parseInt(btn.getAttribute("data-id"), 10);
          if (confirm("Delete this comment permanently?")) {
            updateStatus(id, "deleted");
          }
        });
      });
  }

  // --- Update comment status ---
  async function updateStatus(id, status) {
    try {
      var response = await AdminAuth.authFetch(
        "/api/comments/" + id + "/status",
        {
          method: "PUT",
          body: JSON.stringify({ status: status }),
        },
      );

      if (response.ok) {
        // Reload current filter view
        await loadComments(currentFilter);
      } else {
        var err = await response.json();
        alert("Failed to update: " + (err.error || response.statusText));
      }
    } catch (err) {
      alert("Network error: " + err.message);
    }
  }

  // --- Set up filter buttons ---
  function setupFilters() {
    var buttons = filtersEl.querySelectorAll(".filter-btn");

    buttons.forEach(function (btn) {
      btn.addEventListener("click", function () {
        // Update active state
        buttons.forEach(function (b) {
          b.classList.remove("filter-btn-active");
        });
        btn.classList.add("filter-btn-active");

        // Load filtered comments
        currentFilter = btn.getAttribute("data-status");
        loadComments(currentFilter);
      });
    });
  }

  // --- Theme label update ---
  function updateThemeLabel() {
    var label = document.getElementById("theme-label");
    if (label) {
      var isDark = document.documentElement.classList.contains("dark");
      label.textContent = isDark ? "Light Mode" : "Dark Mode";
    }
  }

  // --- Initialize ---
  async function init() {
    // Require authentication
    AdminAuth.requireLogin();

    // Show dev mode badge
    if (AdminAuth.isDevMode()) {
      var badge = document.getElementById("sidebar-dev-badge");
      if (badge) badge.classList.remove("hidden");
    }

    // Cache DOM references
    commentListEl = document.getElementById("comment-list");
    filtersEl = document.getElementById("comment-filters");

    // Set up logout button
    var logoutBtn = document.getElementById("logout-btn");
    if (logoutBtn) {
      logoutBtn.addEventListener("click", function () {
        AdminAuth.logout();
      });
    }

    // Theme label
    updateThemeLabel();
    var observer = new MutationObserver(updateThemeLabel);
    observer.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ["class"],
    });

    // Set up filter buttons
    setupFilters();

    // Load all comments
    await loadComments("all");
  }

  document.addEventListener("DOMContentLoaded", init);
})();
