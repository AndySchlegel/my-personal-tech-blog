// ============================================
// Admin Dashboard Logic
//
// Fetches stats from /api/admin/stats and renders
// the dashboard overview: stat cards, recent posts,
// recent comments. Falls back to demo data if the
// API is unreachable.
// ============================================

(function () {
  "use strict";

  // --- Demo data (used when API is unavailable) ---
  var DEMO_STATS = {
    posts: { total: 12, published: 10, drafts: 2 },
    comments: { total: 8, pending: 3, approved: 4, flagged: 1 },
    views: { total: 1842 },
    recentPosts: [
      {
        title: "From Zero to Cloud Engineer",
        status: "published",
        published_at: "2026-02-15T10:00:00Z",
        created_at: "2026-02-15T10:00:00Z",
      },
      {
        title: "Terraform Modules: Lessons from a Real Project",
        status: "published",
        published_at: "2026-02-14T14:00:00Z",
        created_at: "2026-02-14T14:00:00Z",
      },
      {
        title: "GitHub Actions with OIDC",
        status: "draft",
        published_at: null,
        created_at: "2026-02-13T09:00:00Z",
      },
    ],
    recentComments: [
      {
        author_name: "Max",
        content: "Great article about Terraform!",
        status: "pending",
        created_at: "2026-02-16T12:30:00Z",
        post_title: "Terraform Modules",
      },
      {
        author_name: "Lisa",
        content: "Very helpful, thanks for sharing.",
        status: "approved",
        created_at: "2026-02-15T08:00:00Z",
        post_title: "From Zero to Cloud Engineer",
      },
    ],
  };

  // --- Animated counter (counts from 0 to target) ---
  function animateCounter(element, target) {
    var duration = 800;
    var start = 0;
    var startTime = null;

    function step(timestamp) {
      if (!startTime) startTime = timestamp;
      var progress = Math.min((timestamp - startTime) / duration, 1);
      // Ease out cubic
      var eased = 1 - Math.pow(1 - progress, 3);
      element.textContent = Math.floor(eased * target).toLocaleString();
      if (progress < 1) {
        requestAnimationFrame(step);
      } else {
        element.textContent = target.toLocaleString();
      }
    }

    requestAnimationFrame(step);
  }

  // --- Format date to readable string ---
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

  // --- Status badge HTML ---
  function statusBadge(status) {
    var colors = {
      published:
        "bg-green-500/10 text-green-600 dark:text-green-400 border-green-500/20",
      draft:
        "bg-amber-500/10 text-amber-600 dark:text-amber-400 border-amber-500/20",
      pending: "bg-sky-500/10 text-sky-600 dark:text-sky-400 border-sky-500/20",
      approved:
        "bg-green-500/10 text-green-600 dark:text-green-400 border-green-500/20",
      flagged: "bg-red-500/10 text-red-600 dark:text-red-400 border-red-500/20",
      deleted: "bg-slate-500/10 text-slate-500 border-slate-500/20",
    };
    var cls = colors[status] || colors.draft;
    return (
      '<span class="inline-flex px-2 py-0.5 text-[11px] font-semibold uppercase tracking-wider border rounded-full ' +
      cls +
      '">' +
      status +
      "</span>"
    );
  }

  // --- Render stat cards ---
  function renderStatCards(stats) {
    var cards = [
      {
        label: "Total Posts",
        value: stats.posts.total,
        icon: "ti-article",
        color: "sky",
      },
      {
        label: "Published",
        value: stats.posts.published,
        icon: "ti-check",
        color: "green",
      },
      {
        label: "Pending Comments",
        value: stats.comments.pending,
        icon: "ti-clock",
        color: "amber",
      },
      {
        label: "Total Views",
        value: stats.views.total,
        icon: "ti-eye",
        color: "purple",
      },
    ];

    var colorMap = {
      sky: {
        bg: "bg-sky-500/10",
        text: "text-sky-500",
        border: "border-t-sky-500",
      },
      green: {
        bg: "bg-green-500/10",
        text: "text-green-500",
        border: "border-t-green-500",
      },
      amber: {
        bg: "bg-amber-500/10",
        text: "text-amber-500",
        border: "border-t-amber-500",
      },
      purple: {
        bg: "bg-purple-500/10",
        text: "text-purple-500",
        border: "border-t-purple-500",
      },
    };

    var container = document.getElementById("stat-cards");
    container.innerHTML = cards
      .map(function (card, i) {
        var c = colorMap[card.color];
        return (
          '<div class="admin-stat-card border-t-2 ' +
          c.border +
          ' fade-in" style="animation-delay: ' +
          i * 0.05 +
          's">' +
          '<div class="flex items-center gap-2 mb-3">' +
          '<div class="w-8 h-8 ' +
          c.bg +
          ' rounded-lg flex items-center justify-center">' +
          '<i class="ti ' +
          card.icon +
          " " +
          c.text +
          ' text-base"></i>' +
          "</div>" +
          '<span class="text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">' +
          card.label +
          "</span>" +
          "</div>" +
          '<span class="stat-value text-2xl font-bold text-slate-900 dark:text-white" data-target="' +
          card.value +
          '">0</span>' +
          "</div>"
        );
      })
      .join("");

    // Animate the counters
    var valueElements = container.querySelectorAll(".stat-value");
    valueElements.forEach(function (el) {
      var target = parseInt(el.getAttribute("data-target"), 10);
      animateCounter(el, target);
    });
  }

  // --- Render recent posts ---
  function renderRecentPosts(posts) {
    var container = document.getElementById("recent-posts");

    if (!posts || posts.length === 0) {
      container.innerHTML =
        '<div class="p-6 text-center text-sm text-slate-400 dark:text-slate-500">No posts yet</div>';
      return;
    }

    container.innerHTML = posts
      .map(function (post, i) {
        var date = formatDate(post.published_at || post.created_at);
        return (
          '<div class="admin-list-item flex items-center justify-between gap-4 px-5 py-3.5 ' +
          (i < posts.length - 1
            ? "border-b border-slate-100 dark:border-slate-700/50"
            : "") +
          '">' +
          '<div class="min-w-0 flex-1">' +
          '<p class="text-sm font-medium text-slate-900 dark:text-white truncate">' +
          truncate(post.title, 60) +
          "</p>" +
          '<p class="text-xs text-slate-400 dark:text-slate-500 mt-0.5">' +
          date +
          "</p>" +
          "</div>" +
          '<div class="flex-shrink-0">' +
          statusBadge(post.status) +
          "</div>" +
          "</div>"
        );
      })
      .join("");
  }

  // --- Render recent comments ---
  function renderRecentComments(comments) {
    var container = document.getElementById("recent-comments");

    if (!comments || comments.length === 0) {
      container.innerHTML =
        '<div class="p-6 text-center text-sm text-slate-400 dark:text-slate-500">No comments yet</div>';
      return;
    }

    container.innerHTML = comments
      .map(function (comment, i) {
        return (
          '<div class="admin-list-item px-5 py-3.5 ' +
          (i < comments.length - 1
            ? "border-b border-slate-100 dark:border-slate-700/50"
            : "") +
          '">' +
          '<div class="flex items-start justify-between gap-3">' +
          '<div class="min-w-0 flex-1">' +
          '<div class="flex items-center gap-2 mb-1">' +
          '<span class="text-sm font-medium text-slate-900 dark:text-white">' +
          comment.author_name +
          "</span>" +
          statusBadge(comment.status) +
          "</div>" +
          '<p class="text-xs text-slate-500 dark:text-slate-400 leading-relaxed">' +
          truncate(comment.content, 100) +
          "</p>" +
          '<p class="text-[11px] text-slate-400 dark:text-slate-500 mt-1">' +
          "on " +
          (comment.post_title
            ? truncate(comment.post_title, 40)
            : "Unknown post") +
          " &middot; " +
          formatDate(comment.created_at) +
          "</p>" +
          "</div>" +
          "</div>" +
          "</div>"
        );
      })
      .join("");
  }

  // --- Update theme label in sidebar ---
  function updateThemeLabel() {
    var label = document.getElementById("theme-label");
    if (label) {
      var isDark = document.documentElement.classList.contains("dark");
      label.textContent = isDark ? "Light Mode" : "Dark Mode";
    }
  }

  // --- Main: load dashboard ---
  async function loadDashboard() {
    // Require authentication
    AdminAuth.requireLogin();

    // Show dev mode badge
    if (AdminAuth.isDevMode()) {
      var badge = document.getElementById("sidebar-dev-badge");
      if (badge) badge.classList.remove("hidden");
    }

    // Set welcome message
    var email = AdminAuth.getUserEmail();
    var welcomeMsg = document.getElementById("welcome-msg");
    if (welcomeMsg && email) {
      welcomeMsg.textContent = "Welcome back, " + email.split("@")[0];
    }

    // Set up logout button
    var logoutBtn = document.getElementById("logout-btn");
    if (logoutBtn) {
      logoutBtn.addEventListener("click", function () {
        AdminAuth.logout();
      });
    }

    // Update theme label
    updateThemeLabel();
    // Watch for theme changes
    var observer = new MutationObserver(updateThemeLabel);
    observer.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ["class"],
    });

    // Fetch stats from API
    var stats = null;
    try {
      var response = await AdminAuth.authFetch("/api/admin/stats");
      if (response.ok) {
        stats = await response.json();
      }
    } catch (err) {
      console.warn(
        "Failed to fetch admin stats, using demo data:",
        err.message,
      );
    }

    // Fall back to demo data if API failed
    if (!stats) {
      stats = DEMO_STATS;
    }

    // Render everything
    renderStatCards(stats);
    renderRecentPosts(stats.recentPosts);
    renderRecentComments(stats.recentComments);
  }

  // --- Initialize when DOM is ready ---
  document.addEventListener("DOMContentLoaded", loadDashboard);
})();
