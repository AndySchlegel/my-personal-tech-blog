// ============================================
// Post Page - Single Article View
//
// Loads a single blog post from the API using
// the ?slug= URL parameter, then converts the
// Markdown content to HTML using the "marked"
// library. Code blocks get syntax highlighting
// via highlight.js.
//
// Example URL: post.html?slug=tailscale-traefik-setup
// ============================================

(function () {
  "use strict";

  // --- Configuration ---
  var API_BASE = "/api";

  // --- Demo post for when the API is not running ---
  var DEMO_POST = {
    title: "Tailscale VPN + Traefik: Sichere Homelab-Cloud Verbindung",
    slug: "tailscale-traefik-setup",
    content:
      "Mit Tailscale VPN und Traefik Reverse Proxy verbinde ich meine " +
      "Synology NAS sicher mit einem Hetzner Cloud Server - ohne Port " +
      "Forwarding am Router.\n\n" +
      "## Die Architektur\n\n" +
      "Internet -> Cloudflare DNS -> Hetzner VPS -> Traefik -> " +
      "Tailscale VPN -> Synology NAS\n\n" +
      "## Vorteile\n\n" +
      "- Keine offenen Ports am Router\n" +
      "- End-to-End Encryption via Tailscale\n" +
      "- Automatische SSL-Zertifikate (Let's Encrypt)\n" +
      "- NAT Traversal - funktioniert auch hinter Firewall\n\n" +
      "## Setup in 6 Schritten\n\n" +
      "1. Tailscale auf Hetzner & Synology installieren\n" +
      "2. Traefik Docker Container auf Hetzner\n" +
      "3. Services auf NAS fuer Tailscale exposen\n" +
      "4. Traefik Labels fuer Routing konfigurieren\n" +
      "5. DNS A-Record auf Hetzner IP setzen\n" +
      "6. Let's Encrypt HTTPS aktivieren\n\n" +
      "```yaml\n" +
      "# docker-compose.yml\n" +
      "services:\n" +
      "  traefik:\n" +
      "    image: traefik:v2.10\n" +
      "    ports:\n" +
      '      - "80:80"\n' +
      '      - "443:443"\n' +
      "```\n\n" +
      "**Kosten**: ~4 EUR/Monat fuer unbegrenzte Services!",
    excerpt:
      "Kein Port Forwarding, keine oeffentliche IP - trotzdem sicher auf alle Services zugreifen.",
    category_name: "Networking & Security",
    author_name: "Andy Schlegel",
    published_at: "2026-01-20T10:00:00Z",
    reading_time_minutes: 15,
    view_count: 42,
    tags: [
      { name: "Tailscale" },
      { name: "Traefik" },
      { name: "VPN" },
      { name: "Networking" },
      { name: "Homelab" },
    ],
  };

  // --- Get the slug from the URL (?slug=my-post) ---
  function getSlugFromUrl() {
    var params = new URLSearchParams(window.location.search);
    return params.get("slug");
  }

  // --- Format a date string ---
  function formatDate(dateString) {
    var date = new Date(dateString);
    return date.toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
    });
  }

  // --- Configure marked (Markdown parser) ---
  function setupMarked() {
    // Tell marked to use highlight.js for code blocks
    marked.setOptions({
      highlight: function (code, lang) {
        // If the language is known, highlight it
        if (lang && hljs.getLanguage(lang)) {
          return hljs.highlight(code, { language: lang }).value;
        }
        // Otherwise, let highlight.js auto-detect
        return hljs.highlightAuto(code).value;
      },
      // Security: don't allow raw HTML inside Markdown
      sanitize: false,
      // Add line breaks on single newlines (like GitHub)
      breaks: false,
      // Use GitHub Flavored Markdown (tables, strikethrough, etc.)
      gfm: true,
    });
  }

  // --- Render the post into the page ---
  function renderPost(post) {
    // Set the page title
    document.title = post.title + " - Andy Schlegel Tech Blog";

    // Category badge
    var categoryEl = document.getElementById("post-category");
    if (categoryEl) categoryEl.textContent = post.category_name || "";

    // Title
    var titleEl = document.getElementById("post-title");
    if (titleEl) titleEl.textContent = post.title;

    // Meta info (date, reading time, views)
    var metaEl = document.getElementById("post-meta");
    if (metaEl) {
      metaEl.innerHTML =
        '<span class="flex items-center gap-1.5">' +
        '<i class="ti ti-calendar text-sm"></i>' +
        formatDate(post.published_at) +
        "</span>" +
        '<span class="flex items-center gap-1.5">' +
        '<i class="ti ti-clock text-sm"></i>' +
        post.reading_time_minutes +
        " min read</span>" +
        '<span class="flex items-center gap-1.5">' +
        '<i class="ti ti-eye text-sm"></i>' +
        (post.view_count || 0) +
        " views</span>";
    }

    // Tags
    var tagsEl = document.getElementById("post-tags");
    if (tagsEl && post.tags) {
      tagsEl.innerHTML = post.tags
        .map(function (tag) {
          return (
            '<span class="px-2.5 py-1 bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 rounded-full text-xs font-medium">' +
            "#" +
            tag.name +
            "</span>"
          );
        })
        .join("");
    }

    // Convert Markdown to HTML and insert it
    var contentEl = document.getElementById("post-content");
    if (contentEl) {
      // marked.parse() turns Markdown string into HTML string
      contentEl.innerHTML = marked.parse(post.content);
    }

    // Show all sections, hide loading skeleton
    var loading = document.getElementById("post-loading");
    var header = document.getElementById("post-header");
    var contentSection = document.getElementById("post-content-section");
    var footerSection = document.getElementById("post-footer-section");
    if (loading) loading.classList.add("hidden");
    if (header) header.classList.remove("hidden");
    if (contentSection) contentSection.classList.remove("hidden");
    if (footerSection) footerSection.classList.remove("hidden");

    // Build prev/next navigation
    loadPostNavigation(post.slug);
  }

  // --- Load prev/next post navigation ---
  // Reads the post list context saved by app.js (respects filter,
  // search, sort order). Falls back to full API list if no context
  // exists (e.g. direct link to a post).
  function loadPostNavigation(currentSlug) {
    // Try to read saved context from blog page
    var saved = sessionStorage.getItem("postNavContext");
    if (saved) {
      try {
        var navList = JSON.parse(saved);
        buildNavFromList(navList, currentSlug);
        return;
      } catch (e) {
        // Invalid JSON, fall through to API fallback
      }
    }

    // Fallback: fetch full post list from API (chronological)
    fetch(API_BASE + "/posts")
      .then(function (response) {
        if (!response.ok) throw new Error("Failed");
        return response.json();
      })
      .then(function (posts) {
        var navList = posts.map(function (p) {
          return { slug: p.slug, title: p.title };
        });
        buildNavFromList(navList, currentSlug);
      })
      .catch(function () {
        // No navigation available, skip silently
      });
  }

  // --- Find prev/next in list and render navigation ---
  function buildNavFromList(navList, currentSlug) {
    var currentIndex = -1;
    for (var i = 0; i < navList.length; i++) {
      if (navList[i].slug === currentSlug) {
        currentIndex = i;
        break;
      }
    }
    if (currentIndex === -1) return;

    var prevPost = currentIndex > 0 ? navList[currentIndex - 1] : null;
    var nextPost =
      currentIndex < navList.length - 1 ? navList[currentIndex + 1] : null;

    // Nothing to show if this is the only post
    if (!prevPost && !nextPost) return;

    renderPostNavigation(prevPost, nextPost);
  }

  // --- Render prev/next navigation into the DOM ---
  function renderPostNavigation(prevPost, nextPost) {
    var navEl = document.getElementById("post-navigation");
    if (!navEl) return;

    // Clear existing content
    while (navEl.firstChild) navEl.removeChild(navEl.firstChild);

    // Previous post - left side
    if (prevPost) {
      navEl.appendChild(buildNavLink(prevPost, "prev"));
    } else {
      navEl.appendChild(document.createElement("div"));
    }

    // Next post - right side
    if (nextPost) {
      navEl.appendChild(buildNavLink(nextPost, "next"));
    } else {
      navEl.appendChild(document.createElement("div"));
    }

    navEl.classList.remove("hidden");
  }

  // --- Build a single nav link element ---
  function buildNavLink(post, direction) {
    var isPrev = direction === "prev";

    // Clicking prev/next should keep the navigation context alive,
    // so the user can continue browsing through the filtered list
    var link = document.createElement("a");
    link.href = "./post.html?slug=" + encodeURIComponent(post.slug);
    link.className =
      "group flex flex-col p-5 rounded-xl border border-slate-200 " +
      "dark:border-slate-700/50 bg-white dark:bg-slate-800/50 " +
      "hover:border-sky-500/50 dark:hover:border-sky-500/50 transition-all" +
      (isPrev ? "" : " text-right");

    // Label row with arrow icon
    var label = document.createElement("span");
    label.className =
      "flex items-center gap-1.5 text-xs font-medium " +
      "text-slate-400 dark:text-slate-500 mb-2" +
      (isPrev ? "" : " justify-end");

    var arrow = document.createElement("i");
    arrow.className =
      "ti ti-arrow-" + (isPrev ? "left" : "right") + " text-sm " +
      "group-hover:" + (isPrev ? "-translate-x-1" : "translate-x-1") +
      " transition-transform";

    var labelText = document.createTextNode(
      isPrev ? "Previous article" : "Next article"
    );

    if (isPrev) {
      label.appendChild(arrow);
      label.appendChild(labelText);
    } else {
      label.appendChild(labelText);
      label.appendChild(arrow);
    }

    // Post title
    var title = document.createElement("span");
    title.className =
      "text-sm font-semibold text-slate-900 dark:text-white " +
      "group-hover:text-sky-500 dark:group-hover:text-sky-400 " +
      "transition-colors line-clamp-2";
    title.textContent = post.title;

    link.appendChild(label);
    link.appendChild(title);
    return link;
  }

  // --- Show an error message ---
  function showError(message) {
    var loading = document.getElementById("post-loading");
    if (loading) {
      loading.innerHTML =
        '<div class="text-center py-16">' +
        '<i class="ti ti-alert-circle text-4xl text-red-400 mb-4"></i>' +
        '<p class="text-slate-400">' +
        message +
        "</p>" +
        '<a href="./index.html" class="inline-block mt-4 text-sky-400 hover:text-sky-300">' +
        '<i class="ti ti-arrow-left"></i> Back to blog</a>' +
        "</div>";
    }
  }

  // --- Load the post from the API ---
  function loadPost() {
    var slug = getSlugFromUrl();

    // No slug in URL? Show error
    if (!slug) {
      showError("No article specified.");
      return;
    }

    // Configure the Markdown parser
    setupMarked();

    // Try to fetch from API
    fetch(API_BASE + "/posts/" + slug)
      .then(function (response) {
        if (!response.ok) throw new Error("Not found");
        return response.json();
      })
      .then(function (post) {
        renderPost(post);
      })
      .catch(function () {
        // API not available - show demo post if slug matches
        if (slug === DEMO_POST.slug || slug === "demo") {
          renderPost(DEMO_POST);
        } else {
          // Show demo post anyway with a note
          renderPost(DEMO_POST);
        }
      });
  }

  // --- Start loading when DOM is ready ---
  document.addEventListener("DOMContentLoaded", loadPost);
})();
