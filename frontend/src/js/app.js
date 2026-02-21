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

  // --- Pick a color for a category badge ---
  // Each category gets a consistent color from this list
  var CATEGORY_COLORS = {
    Career:
      "bg-purple-500/20 text-purple-400 dark:bg-purple-500/20 dark:text-purple-400",
    Security: "bg-red-500/20 text-red-400 dark:bg-red-500/20 dark:text-red-400",
    Homelab:
      "bg-green-500/20 text-green-400 dark:bg-green-500/20 dark:text-green-400",
    DevOps: "bg-sky-500/20 text-sky-400 dark:bg-sky-500/20 dark:text-sky-400",
    AWS: "bg-amber-500/20 text-amber-400 dark:bg-amber-500/20 dark:text-amber-400",
    default:
      "bg-slate-500/20 text-slate-400 dark:bg-slate-500/20 dark:text-slate-400",
  };

  function getCategoryColor(category) {
    return CATEGORY_COLORS[category] || CATEGORY_COLORS.default;
  }

  // --- Create HTML for a single post card ---
  function createPostCard(post, index) {
    // Build tags HTML (only show first 3 tags)
    var tagsArray = post.tags || [];
    var tagsHtml = tagsArray
      .slice(0, 3)
      .map(function (tag) {
        return (
          '<span class="text-xs text-slate-500 dark:text-slate-500">#' +
          tag.name +
          "</span>"
        );
      })
      .join(" ");

    // Category badge with color
    var categoryColor = getCategoryColor(post.category_name);

    // Build the card HTML
    return (
      '<article class="post-card fade-in bg-white dark:bg-slate-800/50 rounded-xl ' +
      "border border-slate-200 dark:border-slate-700/50 overflow-hidden " +
      "hover:border-slate-300 dark:hover:border-slate-600 hover:shadow-lg dark:hover:shadow-slate-900/50 " +
      'cursor-pointer group" style="animation-delay: ' +
      index * 0.1 +
      's" ' +
      "onclick=\"window.location.href='./post.html?slug=" +
      post.slug +
      "'\">" +
      // Card body
      '<div class="p-6">' +
      // Category + reading time
      '<div class="flex items-center justify-between mb-3">' +
      '<span class="badge px-2.5 py-1 rounded-full ' +
      categoryColor +
      '">' +
      post.category_name +
      "</span>" +
      '<span class="flex items-center gap-1 text-xs text-slate-400 dark:text-slate-500">' +
      '<i class="ti ti-clock text-sm"></i>' +
      post.reading_time_minutes +
      " min read" +
      "</span>" +
      "</div>" +
      // Title
      '<h2 class="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-2 ' +
      'group-hover:text-sky-600 dark:group-hover:text-sky-400 transition-colors">' +
      post.title +
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
      '<div class="flex gap-2">' +
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

  // --- Start loading when DOM is ready ---
  document.addEventListener("DOMContentLoaded", loadPosts);
})();
