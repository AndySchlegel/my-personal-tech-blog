// ============================================
// Main App - Blog Post Loading & Rendering
//
// Fetches blog posts from the backend API and
// renders them as cards on the page.
// If the API is not available (e.g. local dev
// without Docker), demo posts are shown instead.
// ============================================

(function () {
  "use strict";

  // --- Configuration ---
  var API_BASE = "/api";

  // --- Demo posts shown when the API is not reachable ---
  // These give a preview of how the blog will look.
  // They get replaced by real data once the backend runs.
  var DEMO_POSTS = [
    {
      title: "From Zero to Cloud Engineer in One Year",
      excerpt:
        "My personal journey from career changer to certified AWS Solutions Architect. Four certifications, countless late nights, and the lessons nobody tells you about.",
      category_name: "Career",
      published_at: "2026-02-15T10:00:00Z",
      reading_time_minutes: 8,
      slug: "zero-to-cloud-engineer",
      tags: [{ name: "AWS" }, { name: "Career" }, { name: "Certification" }],
    },
    {
      title: "How I Detected a Crypto Miner on My NAS",
      excerpt:
        "A Synology NAS, suspicious CPU spikes, and a deep dive into container forensics. Here is how I found and removed a crypto mining container that should not have been there.",
      category_name: "Security",
      published_at: "2026-02-10T10:00:00Z",
      reading_time_minutes: 12,
      slug: "crypto-miner-nas",
      tags: [{ name: "Security" }, { name: "Docker" }, { name: "Homelab" }],
    },
    {
      title: "Building a Media Stack with Plex and the *arr Suite",
      excerpt:
        "Setting up a self-hosted media server with Plex, Sonarr, Radarr, and Prowlarr on a Synology NAS. Docker Compose, reverse proxy, and automation.",
      category_name: "Homelab",
      published_at: "2026-02-05T10:00:00Z",
      reading_time_minutes: 10,
      slug: "media-stack-plex-arr",
      tags: [{ name: "Docker" }, { name: "Plex" }, { name: "Self-Hosted" }],
    },
    {
      title: "Terraform Modules: Lessons from a Real Project",
      excerpt:
        "What I learned building 15 Terraform modules for a production e-commerce platform. Module structure, state management, and the mistakes I made along the way.",
      category_name: "DevOps",
      published_at: "2026-01-28T10:00:00Z",
      reading_time_minutes: 9,
      slug: "terraform-modules-lessons",
      tags: [{ name: "Terraform" }, { name: "AWS" }, { name: "IaC" }],
    },
    {
      title: "Monitoring with Prometheus and Grafana",
      excerpt:
        "Setting up infrastructure monitoring for a homelab. Prometheus for metrics collection, Grafana for dashboards, and alerting that actually works.",
      category_name: "Homelab",
      published_at: "2026-01-20T10:00:00Z",
      reading_time_minutes: 7,
      slug: "monitoring-prometheus-grafana",
      tags: [{ name: "Monitoring" }, { name: "Grafana" }, { name: "Homelab" }],
    },
    {
      title: "GitHub Actions with OIDC: No More AWS Keys",
      excerpt:
        "How to set up CI/CD pipelines that authenticate with AWS using OIDC federation instead of long-lived access keys. Safer, simpler, and the way it should be done.",
      category_name: "DevOps",
      published_at: "2026-01-15T10:00:00Z",
      reading_time_minutes: 6,
      slug: "github-actions-oidc",
      tags: [{ name: "CI/CD" }, { name: "GitHub Actions" }, { name: "AWS" }],
    },
  ];

  // --- Format a date string into a readable format ---
  // "2026-02-15T10:00:00Z" -> "Feb 15, 2026"
  function formatDate(dateString) {
    var date = new Date(dateString);
    return date.toLocaleDateString("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric",
    });
  }

  // --- Category color system ---
  // Each category gets a badge color AND a card accent color (top border)
  var CATEGORY_STYLES = {
    "DevOps & CI/CD": {
      badge: "bg-sky-500/20 text-sky-400",
      border: "border-t-sky-500",
      glow: "glow-sky",
      tag: "text-sky-500/70",
    },
    Certifications: {
      badge: "bg-amber-500/20 text-amber-400",
      border: "border-t-amber-500",
      glow: "glow-amber",
      tag: "text-amber-500/70",
    },
    "Homelab & Self-Hosting": {
      badge: "bg-green-500/20 text-green-400",
      border: "border-t-green-500",
      glow: "glow-green",
      tag: "text-green-500/70",
    },
    "Networking & Security": {
      badge: "bg-red-500/20 text-red-400",
      border: "border-t-red-500",
      glow: "glow-red",
      tag: "text-red-500/70",
    },
    "Tools & Productivity": {
      badge: "bg-purple-500/20 text-purple-400",
      border: "border-t-purple-500",
      glow: "glow-purple",
      tag: "text-purple-500/70",
    },
    "AWS & Cloud": {
      badge: "bg-orange-500/20 text-orange-400",
      border: "border-t-orange-500",
      glow: "glow-orange",
      tag: "text-orange-500/70",
    },
    // Fallback for demo posts and unknown categories
    Career: {
      badge: "bg-purple-500/20 text-purple-400",
      border: "border-t-purple-500",
      glow: "glow-purple",
      tag: "text-purple-500/70",
    },
    Security: {
      badge: "bg-red-500/20 text-red-400",
      border: "border-t-red-500",
      glow: "glow-red",
      tag: "text-red-500/70",
    },
    Homelab: {
      badge: "bg-green-500/20 text-green-400",
      border: "border-t-green-500",
      glow: "glow-green",
      tag: "text-green-500/70",
    },
    DevOps: {
      badge: "bg-sky-500/20 text-sky-400",
      border: "border-t-sky-500",
      glow: "glow-sky",
      tag: "text-sky-500/70",
    },
    AWS: {
      badge: "bg-orange-500/20 text-orange-400",
      border: "border-t-orange-500",
      glow: "glow-orange",
      tag: "text-orange-500/70",
    },
  };

  var DEFAULT_STYLE = {
    badge: "bg-slate-500/20 text-slate-400",
    border: "border-t-slate-500",
    glow: "glow-sky",
    tag: "text-slate-500/70",
  };

  function getCategoryStyle(category) {
    return CATEGORY_STYLES[category] || DEFAULT_STYLE;
  }

  // --- Create HTML for a single post card ---
  function createPostCard(post, index) {
    var style = getCategoryStyle(post.category_name);

    // Build tags HTML (only show first 3 tags) with category color
    var tagsArray = post.tags || [];
    var tagsHtml = tagsArray
      .slice(0, 3)
      .map(function (tag) {
        return (
          '<span class="text-xs ' + style.tag + '">#' + tag.name + "</span>"
        );
      })
      .join(" ");

    // Featured indicator (star icon for featured posts)
    var featuredHtml = post.featured
      ? '<span class="flex items-center gap-1 text-xs text-amber-400" title="Featured">' +
        '<i class="ti ti-star-filled text-sm"></i></span>'
      : "";

    // Build the card HTML with colored top border + glow class for gradient title
    return (
      '<article class="post-card fade-in ' +
      style.glow +
      " bg-white dark:bg-slate-800/50 rounded-xl " +
      "border border-slate-200 dark:border-slate-700/50 " +
      "border-t-2 " +
      style.border +
      " " +
      "hover:border-slate-300 dark:hover:border-slate-600 " +
      'cursor-pointer group" style="animation-delay: ' +
      index * 0.1 +
      's" ' +
      "onclick=\"window.location.href='./post.html?slug=" +
      post.slug +
      "'\">" +
      // Card body
      '<div class="p-6">' +
      // Category + featured star + reading time
      '<div class="flex items-center justify-between mb-3">' +
      '<div class="flex items-center gap-2">' +
      '<span class="badge px-2.5 py-1 rounded-full ' +
      style.badge +
      '">' +
      post.category_name +
      "</span>" +
      featuredHtml +
      "</div>" +
      '<span class="flex items-center gap-1 text-xs text-slate-400 dark:text-slate-500">' +
      '<i class="ti ti-clock text-sm"></i>' +
      post.reading_time_minutes +
      " min read" +
      "</span>" +
      "</div>" +
      // Title with gradient span
      '<h2 class="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-2">' +
      '<span class="title-text">' +
      post.title +
      "</span>" +
      "</h2>" +
      // Excerpt
      '<p class="text-sm text-slate-600 dark:text-slate-400 mb-4 line-clamp-2">' +
      post.excerpt +
      "</p>" +
      // Footer: date + tags
      '<div class="flex items-center justify-between pt-3 border-t border-slate-100 dark:border-slate-700/50">' +
      '<span class="flex items-center gap-1.5 text-xs text-slate-400 dark:text-slate-500">' +
      '<i class="ti ti-calendar text-sm"></i>' +
      formatDate(post.published_at) +
      "</span>" +
      '<div class="flex gap-2 card-tags">' +
      tagsHtml +
      "</div>" +
      "</div>" +
      "</div>" +
      "</article>"
    );
  }

  // --- Render all posts into the grid ---
  function renderPosts(posts) {
    var grid = document.getElementById("posts-grid");
    var loading = document.getElementById("posts-loading");
    var count = document.getElementById("post-count");

    if (!grid) return;

    // Hide loading skeleton
    if (loading) loading.classList.add("hidden");

    // Update post count
    if (count) count.textContent = posts.length + " articles";

    // Build all cards and insert into grid
    var html = posts
      .map(function (post, i) {
        return createPostCard(post, i);
      })
      .join("");

    grid.innerHTML = html;
  }

  // --- Show a status message (API connected / demo mode) ---
  function showStatus(isDemo) {
    var status = document.getElementById("api-status");
    if (!status) return;

    if (isDemo) {
      status.innerHTML =
        '<div class="flex items-center gap-2 text-xs text-amber-500 dark:text-amber-400">' +
        '<i class="ti ti-info-circle"></i>' +
        "<span>Demo mode - showing sample posts. Start the backend to load real data.</span>" +
        "</div>";
    } else {
      status.innerHTML =
        '<div class="flex items-center gap-2 text-xs text-green-500 dark:text-green-400">' +
        '<i class="ti ti-circle-check"></i>' +
        "<span>Connected to API</span>" +
        "</div>";
      // Auto-hide the success message after 3 seconds
      setTimeout(function () {
        status.innerHTML = "";
      }, 3000);
    }
  }

  // --- Fetch posts from the API ---
  function loadPosts() {
    fetch(API_BASE + "/posts")
      .then(function (response) {
        if (!response.ok) throw new Error("API returned " + response.status);
        return response.json();
      })
      .then(function (data) {
        // API returned real posts
        var posts = data.posts || data;
        if (posts.length > 0) {
          renderPosts(posts);
          showStatus(false);
        } else {
          // API works but no posts yet - show demo
          renderPosts(DEMO_POSTS);
          showStatus(true);
        }
      })
      .catch(function () {
        // API not available - show demo posts
        renderPosts(DEMO_POSTS);
        showStatus(true);
      });
  }

  // --- Save scroll position before leaving the page ---
  // So when the user clicks "Back to all articles", we can
  // scroll them back to where they were in the post list.
  function setupScrollMemory() {
    // Save scroll position whenever user is about to leave
    window.addEventListener("beforeunload", function () {
      sessionStorage.setItem("scrollPos", window.scrollY.toString());
    });

    // Also save when clicking a post card (beforeunload doesn't always fire on SPA-like nav)
    document.addEventListener("click", function (e) {
      var card = e.target.closest(".post-card");
      if (card) {
        sessionStorage.setItem("scrollPos", window.scrollY.toString());
      }
    });
  }

  // --- Restore scroll position if coming back from a post ---
  function restoreScrollPosition() {
    var saved = sessionStorage.getItem("scrollPos");
    if (saved) {
      // Small delay so the DOM has rendered the posts first
      setTimeout(function () {
        window.scrollTo(0, parseInt(saved, 10));
      }, 100);
      sessionStorage.removeItem("scrollPos");
    }
  }

  // --- Start loading when DOM is ready ---
  document.addEventListener("DOMContentLoaded", function () {
    loadPosts();
    setupScrollMemory();
    restoreScrollPosition();
  });
})();
