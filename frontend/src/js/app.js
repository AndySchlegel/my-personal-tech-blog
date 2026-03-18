// ============================================
// Main App - Blog Post Loading, Rendering,
// Search & Category Filtering
//
// Fetches blog posts from the backend API and
// renders them as cards on the page.
// Supports search (title/excerpt) and category
// filter via API query parameters.
// If the API is not available (e.g. local dev
// without Docker), demo posts are shown with
// client-side filtering as fallback.
// ============================================

(function () {
  "use strict";

  // --- Configuration ---
  var API_BASE = "/api";

  // --- Filter state ---
  var activeCategory = ""; // category slug, empty = all
  var searchQuery = ""; // current search text
  var allPosts = []; // cached posts for count display
  var totalPostCount = 0; // total posts before filtering
  var isDemo = false; // true when API is not available
  var debounceTimer = null; // for search debounce

  // --- Category color mapping (slug -> color name) ---
  // Used to color the filter buttons with the matching category accent
  var CATEGORY_COLORS = {
    "devops-ci-cd": "sky",
    certifications: "amber",
    "homelab-self-hosting": "green",
    "networking-security": "red",
    "tools-productivity": "purple",
    "aws-cloud": "orange",
    "career-learning": "teal",
  };

  // --- Demo posts shown when the API is not reachable ---
  // These give a preview of how the blog will look.
  // They get replaced by real data once the backend runs.
  var DEMO_POSTS = [
    {
      title: "From Zero to Cloud Engineer in One Year",
      excerpt:
        "My personal journey from career changer to certified AWS Solutions Architect. Four certifications, countless late nights, and the lessons nobody tells you about.",
      category_name: "Career",
      category_slug: "career",
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
      category_slug: "networking-security",
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
      category_slug: "homelab-self-hosting",
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
      category_slug: "devops-ci-cd",
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
      category_slug: "homelab-self-hosting",
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
      category_slug: "devops-ci-cd",
      published_at: "2026-01-15T10:00:00Z",
      reading_time_minutes: 6,
      slug: "github-actions-oidc",
      tags: [{ name: "CI/CD" }, { name: "GitHub Actions" }, { name: "AWS" }],
    },
  ];

  // --- Demo categories for client-side fallback ---
  var DEMO_CATEGORIES = [
    { name: "DevOps & CI/CD", slug: "devops-ci-cd", post_count: 2 },
    {
      name: "Homelab & Self-Hosting",
      slug: "homelab-self-hosting",
      post_count: 2,
    },
    {
      name: "Networking & Security",
      slug: "networking-security",
      post_count: 1,
    },
    { name: "Career", slug: "career", post_count: 1 },
  ];

  // --- Sort order state (chronological = oldest first, default) ---
  var sortNewest = false;

  // --- Format a date string into German readable format ---
  // "2026-02-15T10:00:00Z" -> "15. Feb 2026"
  function formatDate(dateString) {
    var date = new Date(dateString);
    return date.toLocaleDateString("de-DE", {
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
    "Career & Learning": {
      badge: "bg-teal-500/20 text-teal-400",
      border: "border-t-teal-500",
      glow: "glow-teal",
      tag: "text-teal-500/70",
    },
    // Fallback for demo posts and unknown categories
    Career: {
      badge: "bg-teal-500/20 text-teal-400",
      border: "border-t-teal-500",
      glow: "glow-teal",
      tag: "text-teal-500/70",
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

  // --- Category RGB values for card blob visuals ---
  var CATEGORY_RGB = {
    "DevOps & CI/CD": "14, 165, 233",
    Certifications: "245, 158, 11",
    "Homelab & Self-Hosting": "34, 197, 94",
    "Networking & Security": "239, 68, 68",
    "Tools & Productivity": "168, 85, 247",
    "AWS & Cloud": "249, 115, 22",
    "Career & Learning": "20, 184, 166",
    Career: "20, 184, 166",
    Security: "239, 68, 68",
    Homelab: "34, 197, 94",
    DevOps: "14, 165, 233",
    AWS: "249, 115, 22",
  };

  function getCategoryStyle(category) {
    return CATEGORY_STYLES[category] || DEFAULT_STYLE;
  }

  // --- Escape HTML to prevent XSS when inserting API data into innerHTML ---
  // Converts special characters (<, >, ", &) to harmless HTML entities
  // so they render as text instead of being parsed as HTML/JavaScript.
  function escapeHtml(text) {
    var div = document.createElement("div");
    div.appendChild(document.createTextNode(text));
    return div.innerHTML;
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
          '<span class="text-xs ' +
          style.tag +
          '">#' +
          escapeHtml(tag.name) +
          "</span>"
        );
      })
      .join(" ");

    // Featured indicator (star icon for featured posts)
    var featuredHtml = post.featured
      ? '<span class="flex items-center gap-1 text-xs text-amber-400" title="Featured">' +
        '<i class="ti ti-star-filled text-sm"></i></span>'
      : "";

    // Category RGB for the card blob visual
    var rgb = CATEGORY_RGB[post.category_name] || "148, 163, 184";

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
      'cursor-pointer group relative overflow-hidden" style="animation-delay: ' +
      index * 0.1 +
      's" ' +
      "onclick=\"window.location.href='./post.html?slug=" +
      escapeHtml(post.slug) +
      "'\">" +
      // Category blob (subtle floating color accent)
      '<div class="card-blob" style="background:rgba(' +
      rgb +
      ",0.2);animation-delay:" +
      index * 0.3 +
      's;"></div>' +
      // Card body (above blob)
      '<div class="p-6 relative" style="z-index:1;">' +
      // Category + featured star + reading time
      '<div class="flex items-center justify-between mb-3">' +
      '<div class="flex items-center gap-2">' +
      '<span class="badge px-2.5 py-1 rounded-full ' +
      style.badge +
      '">' +
      escapeHtml(post.category_name) +
      "</span>" +
      featuredHtml +
      "</div>" +
      '<div class="flex items-center gap-3">' +
      '<span class="flex items-center gap-1 text-xs text-slate-400 dark:text-slate-500">' +
      '<i class="ti ti-eye text-sm"></i> ' +
      (post.view_count || 0) +
      "</span>" +
      '<span class="flex items-center gap-1 text-xs text-slate-400 dark:text-slate-500">' +
      '<i class="ti ti-clock text-sm"></i>' +
      post.reading_time_minutes +
      " min read" +
      "</span>" +
      "</div>" +
      "</div>" +
      // Title with gradient span
      '<h2 class="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-2">' +
      '<span class="title-text">' +
      escapeHtml(post.title) +
      "</span>" +
      "</h2>" +
      // Excerpt
      '<p class="text-sm text-slate-600 dark:text-slate-400 mb-4 card-excerpt">' +
      escapeHtml(post.excerpt) +
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

  // --- Sort posts by date ---
  function sortPosts(posts) {
    return posts.slice().sort(function (a, b) {
      var da = new Date(a.published_at).getTime();
      var db = new Date(b.published_at).getTime();
      return sortNewest ? db - da : da - db;
    });
  }

  // --- Render all posts into the grid ---
  function renderPosts(posts) {
    var grid = document.getElementById("posts-grid");
    var loading = document.getElementById("posts-loading");
    var count = document.getElementById("post-count");

    // Apply current sort order
    posts = sortPosts(posts);

    if (!grid) return;

    // Hide loading skeleton
    if (loading) loading.classList.add("hidden");

    // Update post count - show "X of Y" when filtered
    if (count) {
      var isFiltered = activeCategory || searchQuery;
      if (isFiltered && totalPostCount > 0) {
        count.textContent = posts.length + " of " + totalPostCount + " posts";
      } else {
        count.textContent = posts.length + " posts";
      }
    }

    // Handle no results
    if (posts.length === 0) {
      grid.innerHTML =
        '<div class="no-results col-span-2 text-center py-12">' +
        '<i class="ti ti-search-off text-4xl text-slate-400 dark:text-slate-600 mb-3 block"></i>' +
        '<p class="text-slate-500 dark:text-slate-400 text-sm">No posts found.</p>' +
        '<p class="text-slate-400 dark:text-slate-500 text-xs mt-1">Try a different search term or category.</p>' +
        "</div>";
      return;
    }

    // Build all cards and insert into grid
    var html = posts
      .map(function (post, i) {
        return createPostCard(post, i);
      })
      .join("");

    grid.innerHTML = html;
  }

  // --- Render category filter buttons ---
  function renderCategoryFilters(categories) {
    var container = document.getElementById("category-filters");
    if (!container) return;

    // Start with the "All" button (already in HTML, but rebuild all for consistency)
    var html =
      '<button class="filter-btn' +
      (activeCategory === "" ? " filter-btn-active" : "") +
      '" data-category="">All</button>';

    categories.forEach(function (cat) {
      var color = CATEGORY_COLORS[cat.slug] || "slate";
      var isActive = activeCategory === cat.slug;
      html +=
        '<button class="filter-btn' +
        (isActive ? " filter-btn-active" : "") +
        '" data-category="' +
        cat.slug +
        '" data-color="' +
        color +
        '">' +
        cat.name +
        " (" +
        cat.post_count +
        ")" +
        "</button>";
    });

    container.innerHTML = html;

    // Attach click handlers to all filter buttons
    var buttons = container.querySelectorAll(".filter-btn");
    buttons.forEach(function (btn) {
      btn.addEventListener("click", function () {
        activeCategory = btn.getAttribute("data-category") || "";
        // Re-render buttons to update active state
        renderCategoryFilters(categories);
        // Re-fetch/filter posts
        fetchFilteredPosts();
      });
    });
  }

  // --- Show a status message (API connected / demo mode) ---
  function showStatus(isDemoMode) {
    var status = document.getElementById("api-status");
    if (!status) return;

    if (isDemoMode) {
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

  // --- Client-side filtering for demo mode ---
  function filterDemoPosts() {
    var filtered = DEMO_POSTS;

    // Filter by category slug
    if (activeCategory) {
      filtered = filtered.filter(function (post) {
        return post.category_slug === activeCategory;
      });
    }

    // Filter by search query (title + excerpt, case-insensitive)
    if (searchQuery) {
      var q = searchQuery.toLowerCase();
      filtered = filtered.filter(function (post) {
        return (
          post.title.toLowerCase().indexOf(q) !== -1 ||
          post.excerpt.toLowerCase().indexOf(q) !== -1
        );
      });
    }

    return filtered;
  }

  // --- Get current language from lang.js ---
  function getCurrentLang() {
    return window.blogLang ? window.blogLang.get() : "de";
  }

  // --- Update static UI text based on current language ---
  // Swaps text for elements with data-de / data-en attributes,
  // and updates placeholders with data-de-placeholder / data-en-placeholder.
  function updateStaticText() {
    var lang = getCurrentLang();

    // Swap innerHTML for elements with data-de/data-en
    var elements = document.querySelectorAll("[data-de][data-en]");
    for (var i = 0; i < elements.length; i++) {
      elements[i].innerHTML = elements[i].getAttribute("data-" + lang) || "";
    }

    // Swap placeholder text
    var inputs = document.querySelectorAll(
      "[data-de-placeholder][data-en-placeholder]",
    );
    for (var j = 0; j < inputs.length; j++) {
      inputs[j].placeholder =
        inputs[j].getAttribute("data-" + lang + "-placeholder") || "";
    }

    // Sort label
    var sortLabel = document.getElementById("sort-label");
    if (sortLabel) {
      if (lang === "en") {
        sortLabel.textContent = sortNewest ? "Newest first" : "Chronological";
      } else {
        sortLabel.textContent = sortNewest ? "Neueste zuerst" : "Chronologisch";
      }
    }

    // Post count suffix
    var countEl = document.getElementById("post-count");
    if (countEl && allPosts.length > 0) {
      var isFiltered = activeCategory || searchQuery;
      if (isFiltered && totalPostCount > 0) {
        countEl.textContent =
          allPosts.length +
          (lang === "en" ? " of " : " von ") +
          totalPostCount +
          " posts";
      } else {
        countEl.textContent = allPosts.length + " posts";
      }
    }
  }

  // --- Fetch posts from the API with current filters ---
  function fetchFilteredPosts() {
    if (isDemo) {
      // Client-side filtering in demo mode
      var filtered = filterDemoPosts();
      renderPosts(filtered);
      return;
    }

    // Build query string from active filters
    var params = [];
    if (searchQuery) params.push("search=" + encodeURIComponent(searchQuery));
    if (activeCategory)
      params.push("category=" + encodeURIComponent(activeCategory));
    // Add language parameter for translation
    var lang = getCurrentLang();
    if (lang === "en") params.push("lang=en");
    var queryString = params.length > 0 ? "?" + params.join("&") : "";

    fetch(API_BASE + "/posts" + queryString)
      .then(function (response) {
        if (!response.ok) throw new Error("API returned " + response.status);
        return response.json();
      })
      .then(function (data) {
        var posts = data.posts || data;
        allPosts = posts;
        renderPosts(posts);
      })
      .catch(function () {
        // If API fails mid-session, fall back to demo
        isDemo = true;
        var filtered = filterDemoPosts();
        renderPosts(filtered);
        showStatus(true);
      });
  }

  // --- Initial load: fetch all posts + categories ---
  // Includes language parameter so posts load in the active language
  // (important when returning from a post page where EN was selected).
  function loadPosts() {
    var lang = getCurrentLang();
    var langParam = lang === "en" ? "?lang=en" : "";
    fetch(API_BASE + "/posts" + langParam)
      .then(function (response) {
        if (!response.ok) throw new Error("API returned " + response.status);
        return response.json();
      })
      .then(function (data) {
        var posts = data.posts || data;
        if (posts.length > 0) {
          isDemo = false;
          allPosts = posts;
          totalPostCount = posts.length;
          renderPosts(posts);
          showStatus(false);
          // Fetch categories for filter buttons
          loadCategories();
        } else {
          // API works but no posts - show demo
          initDemoMode();
        }
      })
      .catch(function () {
        // API not available - show demo posts
        initDemoMode();
      });
  }

  // --- Initialize demo mode with client-side filtering ---
  function initDemoMode() {
    isDemo = true;
    allPosts = DEMO_POSTS;
    totalPostCount = DEMO_POSTS.length;
    renderPosts(DEMO_POSTS);
    showStatus(true);
    renderCategoryFilters(DEMO_CATEGORIES);
  }

  // --- Fetch categories from API for filter buttons ---
  function loadCategories() {
    fetch(API_BASE + "/categories")
      .then(function (response) {
        if (!response.ok) throw new Error("API returned " + response.status);
        return response.json();
      })
      .then(function (categories) {
        // Only show categories that have posts
        var withPosts = categories.filter(function (cat) {
          return parseInt(cat.post_count, 10) > 0;
        });
        renderCategoryFilters(withPosts);
      })
      .catch(function () {
        // If categories fail, use demo categories
        renderCategoryFilters(DEMO_CATEGORIES);
      });
  }

  // --- Set up search input handlers ---
  function setupSearch() {
    var input = document.getElementById("search-input");
    var clearBtn = document.getElementById("search-clear");
    if (!input) return;

    // Debounced search: waits 300ms after user stops typing
    input.addEventListener("input", function () {
      var value = input.value.trim();
      searchQuery = value;

      // Show/hide clear button
      if (clearBtn) {
        clearBtn.classList.toggle("hidden", value.length === 0);
      }

      // Debounce the API call
      if (debounceTimer) clearTimeout(debounceTimer);
      debounceTimer = setTimeout(function () {
        fetchFilteredPosts();
      }, 300);
    });

    // Clear button resets search
    if (clearBtn) {
      clearBtn.addEventListener("click", function () {
        input.value = "";
        searchQuery = "";
        clearBtn.classList.add("hidden");
        fetchFilteredPosts();
        input.focus();
      });
    }

    // Enter key triggers immediate search (no debounce wait)
    input.addEventListener("keydown", function (e) {
      if (e.key === "Enter") {
        if (debounceTimer) clearTimeout(debounceTimer);
        searchQuery = input.value.trim();
        fetchFilteredPosts();
      }
    });
  }

  // --- Set up sort toggle ---
  function setupSortToggle() {
    var btn = document.getElementById("sort-toggle");
    var label = document.getElementById("sort-label");
    if (!btn) return;

    btn.addEventListener("click", function () {
      sortNewest = !sortNewest;
      // Update icon and label
      var icon = btn.querySelector("i");
      if (icon) {
        icon.className = sortNewest
          ? "ti ti-arrow-down text-sm"
          : "ti ti-arrow-up text-sm";
      }
      if (label) {
        var lang = getCurrentLang();
        if (lang === "en") {
          label.textContent = sortNewest ? "Newest first" : "Chronological";
        } else {
          label.textContent = sortNewest ? "Neueste zuerst" : "Chronologisch";
        }
      }
      // Re-render with current data
      if (isDemo) {
        renderPosts(filterDemoPosts());
      } else {
        renderPosts(allPosts);
      }
    });
  }

  // --- Save scroll position before leaving the page ---
  // So when the user clicks "Back to Blog Posts", we can
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

  // --- Save current post list context for prev/next navigation ---
  // When a user clicks a post card, we save the currently visible
  // posts (filtered + sorted) so the post page can show matching
  // prev/next links. This respects category filter, search, and
  // sort order -- the navigation always matches what the user saw.
  function setupPostNavContext() {
    document.addEventListener("click", function (e) {
      var card = e.target.closest(".post-card");
      if (!card) return;

      // Get the currently rendered posts in their displayed order
      var currentPosts = isDemo ? filterDemoPosts() : allPosts;
      var sorted = sortPosts(currentPosts);

      // Save slug + title for each post (minimal data for navigation)
      var navList = sorted.map(function (p) {
        return { slug: p.slug, title: p.title };
      });

      // Store with language key so prev/next titles match active language
      var lang = getCurrentLang ? getCurrentLang() : "de";
      sessionStorage.setItem("postNavContext_" + lang, JSON.stringify(navList));
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
    setupSearch();
    setupSortToggle();
    setupScrollMemory();
    setupPostNavContext();
    restoreScrollPosition();

    // Re-fetch posts and update static text when language is toggled (DE/EN)
    window.addEventListener("languageChanged", function () {
      updateStaticText();
      fetchFilteredPosts();
    });

    // Apply language on initial load (if EN was saved in localStorage)
    updateStaticText();
  });
})();
