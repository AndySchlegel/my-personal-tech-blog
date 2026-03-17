// ============================================
// Post Page - Single Article View
//
// Loads a single blog post from the API using
// the ?slug= URL parameter, then converts the
// Markdown content to HTML using the "marked"
// library. Code blocks get syntax highlighting
// via highlight.js.
//
// Features:
//   - Markdown rendering with syntax highlighting
//   - Like button (localStorage prevents duplicates)
//   - Comment section (load approved + submit new)
//   - Category visual (animated floating blobs)
//   - Prev/Next post navigation
//
// Example URL: post.html?slug=tailscale-traefik-setup
// ============================================

(function () {
  "use strict";

  // --- Configuration ---
  var API_BASE = "/api";

  // --- Get current language from lang.js ---
  function getCurrentLang() {
    return window.blogLang ? window.blogLang.get() : "de";
  }

  // --- Category color + icon mapping ---
  // Matches the colors used in app.js and styles.css
  // Category slugs must match the DB exactly (see categories table)
  var CATEGORY_CONFIG = {
    "devops-ci-cd": {
      color: "14, 165, 233",
      icon: "ti ti-rocket",
      bgClass: "bg-sky-500/10",
      textClass: "text-sky-500",
    },
    "aws-cloud": {
      color: "249, 115, 22",
      icon: "ti ti-cloud",
      bgClass: "bg-orange-500/10",
      textClass: "text-orange-500",
    },
    "homelab-self-hosting": {
      color: "34, 197, 94",
      icon: "ti ti-server",
      bgClass: "bg-green-500/10",
      textClass: "text-green-500",
    },
    "networking-security": {
      color: "239, 68, 68",
      icon: "ti ti-shield-lock",
      bgClass: "bg-red-500/10",
      textClass: "text-red-500",
    },
    certifications: {
      color: "245, 158, 11",
      icon: "ti ti-certificate",
      bgClass: "bg-amber-500/10",
      textClass: "text-amber-500",
    },
    "tools-productivity": {
      color: "168, 85, 247",
      icon: "ti ti-tool",
      bgClass: "bg-purple-500/10",
      textClass: "text-purple-500",
    },
    "career-learning": {
      color: "20, 184, 166",
      icon: "ti ti-school",
      bgClass: "bg-teal-500/10",
      textClass: "text-teal-500",
    },
  };

  // --- Demo post for when the API is not running ---
  var DEMO_POST = {
    id: 1,
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
    category_slug: "networking-and-security",
    author_name: "Andy Schlegel",
    published_at: "2026-01-20T10:00:00Z",
    reading_time_minutes: 15,
    view_count: 42,
    like_count: 7,
    comment_count: 0,
    tags: [
      { name: "Tailscale" },
      { name: "Traefik" },
      { name: "VPN" },
      { name: "Networking" },
      { name: "Homelab" },
    ],
  };

  // --- Store current post data for comments/likes ---
  var currentPost = null;

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

  // --- Format relative time for comments (DE/EN) ---
  function formatRelativeTime(dateString) {
    var date = new Date(dateString);
    var now = new Date();
    var diff = Math.floor((now - date) / 1000);
    var lang = getCurrentLang();

    if (lang === "en") {
      if (diff < 60) return "just now";
      if (diff < 3600) return Math.floor(diff / 60) + " min ago";
      if (diff < 86400) return Math.floor(diff / 3600) + " hrs ago";
      if (diff < 604800) return Math.floor(diff / 86400) + " days ago";
    } else {
      if (diff < 60) return "gerade eben";
      if (diff < 3600) return "vor " + Math.floor(diff / 60) + " Min.";
      if (diff < 86400) return "vor " + Math.floor(diff / 3600) + " Std.";
      if (diff < 604800) return "vor " + Math.floor(diff / 86400) + " Tagen";
    }
    return formatDate(dateString);
  }

  // --- Validate commenter name (block troll/anonymous names) ---
  var BLOCKED_NAMES = [
    "anonymous",
    "anonym",
    "anon",
    "test",
    "tester",
    "admin",
    "administrator",
    "user",
    "nobody",
    "noname",
    "no name",
    "mr. x",
    "mr x",
    "mrs x",
    "john doe",
    "jane doe",
    "max mustermann",
    "hans wurst",
    "foo",
    "bar",
    "asdf",
    "qwerty",
    "xyz",
    "abc",
    "name",
    "dein name",
    "your name",
    "unknown",
    "unbekannt",
    "gast",
    "guest",
    "bot",
    "spam",
    "fake",
  ];

  // --- Basic profanity blocklist (German + English common insults) ---
  // Not exhaustive -- Comprehend sentiment analysis handles the rest on EKS
  var PROFANITY_LIST = [
    "spast",
    "spasti",
    "hurensohn",
    "wichser",
    "arschloch",
    "idiot",
    "depp",
    "vollidiot",
    "missgeburt",
    "bastard",
    "schlampe",
    "fotze",
    "hure",
    "schwuchtel",
    "behindert",
    "retard",
    "fuck",
    "shit",
    "asshole",
    "bitch",
    "dick",
    "pussy",
    "cunt",
    "nigger",
    "nazi",
  ];

  function isValidName(name) {
    if (!name || name.length < 3) return false;

    var lower = name.toLowerCase().trim();

    // Must contain at least 2 letter characters
    var letterCount = (lower.match(/[a-zA-ZäöüÄÖÜß]/g) || []).length;
    if (letterCount < 2) return false;

    // Block known troll names
    for (var i = 0; i < BLOCKED_NAMES.length; i++) {
      if (lower === BLOCKED_NAMES[i]) return false;
    }

    // Block profanity in name (check if any blocked word is contained)
    for (var j = 0; j < PROFANITY_LIST.length; j++) {
      if (lower.indexOf(PROFANITY_LIST[j]) !== -1) return false;
    }

    // Block repeated single character ("aaa", "xxx", "mmm")
    if (/^(.)\1+$/.test(lower.replace(/\s/g, ""))) return false;

    // Block all-number names
    if (/^\d+$/.test(lower.replace(/\s/g, ""))) return false;

    return true;
  }

  // --- Setup live name validation on input ---
  function setupLiveNameValidation() {
    var nameInput = document.querySelector(
      '#comment-form [name="author_name"]',
    );
    var nameError = document.getElementById("name-error");
    if (!nameInput || !nameError) return;

    nameInput.addEventListener("input", function () {
      var value = nameInput.value.trim();
      // Only validate when user has typed at least 2 chars (don't nag too early)
      if (value.length < 2) {
        nameError.classList.add("hidden");
        nameInput.classList.remove("border-red-500", "dark:border-red-500");
        return;
      }
      if (!isValidName(value)) {
        nameError.classList.remove("hidden");
        nameInput.classList.add("border-red-500", "dark:border-red-500");
      } else {
        nameError.classList.add("hidden");
        nameInput.classList.remove("border-red-500", "dark:border-red-500");
      }
    });
  }

  // --- Configure marked (Markdown parser) ---
  function setupMarked() {
    // Tell marked to use highlight.js for code blocks
    marked.setOptions({
      highlight: function (code, lang) {
        if (lang && hljs.getLanguage(lang)) {
          return hljs.highlight(code, { language: lang }).value;
        }
        return hljs.highlightAuto(code).value;
      },
      sanitize: false,
      breaks: false,
      gfm: true,
    });
  }

  // ============================================
  // CATEGORY VISUAL - Animated floating blobs
  // ============================================

  // --- Render animated category visual in post header ---
  function renderCategoryVisual(categorySlug) {
    var config = CATEGORY_CONFIG[categorySlug];
    if (!config) return;

    var container = document.getElementById("category-visual");
    if (!container) return;

    // Create 3 floating blobs with the category color (large, visible)
    var rgb = config.color;
    var blobConfigs = [
      { size: 120, top: 0, right: 20, opacity: 0.5, delay: 0 },
      { size: 90, top: 50, right: 80, opacity: 0.4, delay: 0.6 },
      { size: 100, top: -10, right: 100, opacity: 0.35, delay: 1.2 },
    ];
    for (var i = 0; i < blobConfigs.length; i++) {
      var bc = blobConfigs[i];
      var blob = document.createElement("div");
      blob.className = "category-blob";
      blob.style.cssText =
        "width:" +
        bc.size +
        "px;height:" +
        bc.size +
        "px;" +
        "top:" +
        bc.top +
        "px;right:" +
        bc.right +
        "px;" +
        "background:rgba(" +
        rgb +
        "," +
        bc.opacity +
        ");" +
        "animation-delay:" +
        bc.delay +
        "s;";
      container.appendChild(blob);
    }

    // Fade in the visual after a short delay (entrance animation)
    setTimeout(function () {
      container.style.opacity = "1";
    }, 200);

    // Style the category icon box
    var iconBox = document.getElementById("post-category-icon");
    if (iconBox) {
      iconBox.className =
        "w-7 h-7 rounded-lg flex items-center justify-center " + config.bgClass;
      iconBox.innerHTML =
        '<i class="' + config.icon + " text-sm " + config.textClass + '"></i>';
    }

    // Update category badge color
    var badge = document.getElementById("post-category");
    if (badge) {
      badge.className =
        "inline-block px-3 py-1 rounded-full text-xs font-semibold uppercase tracking-wide " +
        config.bgClass +
        " " +
        config.textClass;
    }
  }

  // ============================================
  // LIKE BUTTON
  // ============================================

  // --- Check if this post was already liked ---
  function isPostLiked(postId) {
    try {
      var liked = JSON.parse(localStorage.getItem("likedPosts") || "[]");
      return liked.indexOf(postId) !== -1;
    } catch (e) {
      return false;
    }
  }

  // --- Mark post as liked in localStorage ---
  function markPostLiked(postId) {
    try {
      var liked = JSON.parse(localStorage.getItem("likedPosts") || "[]");
      if (liked.indexOf(postId) === -1) {
        liked.push(postId);
        localStorage.setItem("likedPosts", JSON.stringify(liked));
      }
    } catch (e) {
      // localStorage not available, ignore
    }
  }

  // --- Show filled heart via CSS class (color + glow) ---
  function showFilledHeart() {
    var heart = document.querySelector("#like-btn .like-heart");
    if (heart) heart.classList.add("liked-heart");
  }

  // --- Setup the like button ---
  function setupLikeButton(post) {
    var btn = document.getElementById("like-btn");
    var countEl = document.getElementById("like-count");
    if (!btn || !countEl) return;

    // Set initial count
    countEl.textContent = post.like_count || 0;

    // If already liked, show filled heart permanently
    if (isPostLiked(post.id)) {
      btn.classList.add("liked");
      showFilledHeart();
    }

    // Click handler
    btn.addEventListener("click", function () {
      if (isPostLiked(post.id)) return; // Already liked

      // Optimistic UI update
      var currentCount = parseInt(countEl.textContent) || 0;
      countEl.textContent = currentCount + 1;
      btn.classList.add("liked", "like-pop");
      showFilledHeart();
      markPostLiked(post.id);

      // Remove pop animation after it plays
      setTimeout(function () {
        btn.classList.remove("like-pop");
      }, 500);

      // Send to API
      fetch(API_BASE + "/posts/" + post.id + "/like", { method: "POST" })
        .then(function (response) {
          if (!response.ok) throw new Error("Failed");
          return response.json();
        })
        .then(function (data) {
          // Sync with server count
          countEl.textContent = data.like_count;
        })
        .catch(function () {
          // API failed, keep optimistic count (it's fine for a like)
        });
    });
  }

  // ============================================
  // AUDIO PLAYER (Amazon Polly text-to-speech)
  // ============================================

  var audioState = { loading: false, playing: false };

  // --- Setup the audio (listen) button + speed controls + sticky bar ---
  function setupAudioButton(post) {
    var btn = document.getElementById("audio-btn");
    var player = document.getElementById("audio-player");
    var icon = document.getElementById("audio-icon");
    var label = document.getElementById("audio-label");
    var speedControl = document.getElementById("audio-speed-control");

    // Sticky bar elements (mirrors main controls)
    var stickyBar = document.getElementById("sticky-audio-bar");
    var stickyTitle = document.getElementById("sticky-title");
    var stickyBtn = document.getElementById("sticky-audio-btn");
    var stickyIcon = document.getElementById("sticky-audio-icon");
    var stickyLabel = document.getElementById("sticky-audio-label");
    var stickySpeedControl = document.getElementById("sticky-speed-control");

    if (!btn || !player) return;

    // Set sticky bar title
    if (stickyTitle) stickyTitle.textContent = post.title;

    // --- Sync both buttons (main + sticky) to reflect current audio state ---
    function syncUI(state) {
      var lang = getCurrentLang();
      var mainIconClass, stickyIconClass, text;

      if (state === "loading") {
        mainIconClass = "ti ti-loader text-lg animate-spin";
        stickyIconClass = "ti ti-loader text-sm animate-spin";
        text = lang === "en" ? "Loading..." : "Laden...";
      } else if (state === "playing") {
        mainIconClass = "ti ti-player-pause text-lg";
        stickyIconClass = "ti ti-player-pause text-sm";
        text = "Pause";
      } else {
        mainIconClass = "ti ti-headphones text-lg";
        stickyIconClass = "ti ti-headphones text-sm";
        text = lang === "en" ? "Listen" : "Vorlesen";
      }

      if (icon) icon.className = mainIconClass;
      if (label) label.textContent = text;
      if (stickyIcon) stickyIcon.className = stickyIconClass;
      if (stickyLabel) stickyLabel.textContent = text;
    }

    // --- Speed button setup (works for both main and sticky controls) ---
    function setupSpeedButtons(container, cssActive, cssInactive) {
      if (!container) return;
      var speedBtns = container.querySelectorAll(
        ".audio-speed-btn, .sticky-speed-btn",
      );
      speedBtns.forEach(function (speedBtn) {
        speedBtn.addEventListener("click", function () {
          var speed = parseFloat(speedBtn.getAttribute("data-speed"));
          player.playbackRate = speed;
          // Sync active state across ALL speed buttons (main + sticky)
          syncSpeedUI(speed);
        });
      });
    }

    // Highlight the active speed across both control bars
    function syncSpeedUI(speed) {
      [speedControl, stickySpeedControl].forEach(function (ctrl) {
        if (!ctrl) return;
        ctrl.querySelectorAll("[data-speed]").forEach(function (b) {
          var isActive = parseFloat(b.getAttribute("data-speed")) === speed;
          var isSticky = b.classList.contains("sticky-speed-btn");
          if (isSticky) {
            b.className = isActive
              ? "sticky-speed-btn active px-1.5 py-0.5 rounded text-[10px] font-semibold border border-purple-400 dark:border-purple-500 text-purple-500 dark:text-purple-400 transition-all"
              : "sticky-speed-btn px-1.5 py-0.5 rounded text-[10px] font-semibold border border-slate-200 dark:border-slate-700/50 text-slate-400 dark:text-slate-500 hover:text-purple-500 hover:border-purple-400 transition-all";
          } else {
            b.className = isActive
              ? "audio-speed-btn active px-2 py-1 rounded-md text-xs font-semibold border border-purple-400 dark:border-purple-500 text-purple-500 dark:text-purple-400 transition-all"
              : "audio-speed-btn px-2 py-1 rounded-md text-xs font-semibold border border-slate-200 dark:border-slate-700/50 text-slate-400 dark:text-slate-500 hover:text-purple-500 dark:hover:text-purple-400 hover:border-purple-300 dark:hover:border-purple-500/50 transition-all";
          }
        });
      });
    }

    setupSpeedButtons(speedControl);
    setupSpeedButtons(stickySpeedControl);

    // Show/hide speed controls on both bars
    function showSpeedControls() {
      if (speedControl) speedControl.classList.remove("hidden");
      if (stickySpeedControl) stickySpeedControl.classList.remove("hidden");
    }

    // --- Audio play/pause handler (shared by both buttons) ---
    function handleAudioClick() {
      // If already playing, pause
      if (audioState.playing) {
        player.pause();
        audioState.playing = false;
        syncUI("idle");
        return;
      }

      // If audio is loaded (paused), resume
      if (player.src && !audioState.loading) {
        player.play();
        audioState.playing = true;
        syncUI("playing");
        return;
      }

      // First click: fetch audio URL from API
      if (audioState.loading) return;
      audioState.loading = true;
      syncUI("loading");

      var lang = getCurrentLang();
      var langParam = lang === "en" ? "?lang=en" : "";

      fetch(API_BASE + "/posts/" + post.id + "/audio" + langParam)
        .then(function (response) {
          if (!response.ok) throw new Error("Audio not available");
          return response.json();
        })
        .then(function (data) {
          player.src = data.audio_url;
          player.play();
          audioState.loading = false;
          audioState.playing = true;
          syncUI("playing");
          showSpeedControls();
        })
        .catch(function () {
          audioState.loading = false;
          syncUI("idle");
        });
    }

    // Attach click handler to both buttons
    btn.addEventListener("click", handleAudioClick);
    if (stickyBtn) stickyBtn.addEventListener("click", handleAudioClick);

    // When audio ends, reset both buttons (keep speed controls visible)
    player.addEventListener("ended", function () {
      audioState.playing = false;
      syncUI("idle");
    });

    // --- Sticky bar visibility (IntersectionObserver) ---
    // Show sticky bar when the original post-header scrolls out of view
    var postHeader = document.getElementById("post-header");
    if (postHeader && stickyBar) {
      var observer = new IntersectionObserver(
        function (entries) {
          entries.forEach(function (entry) {
            if (entry.isIntersecting) {
              // Header visible -> hide sticky bar
              stickyBar.classList.add(
                "translate-y-[-100%]",
                "opacity-0",
                "pointer-events-none",
              );
              stickyBar.classList.remove(
                "translate-y-0",
                "opacity-100",
                "pointer-events-auto",
              );
            } else {
              // Header scrolled away -> show sticky bar
              stickyBar.classList.remove(
                "translate-y-[-100%]",
                "opacity-0",
                "pointer-events-none",
              );
              stickyBar.classList.add(
                "translate-y-0",
                "opacity-100",
                "pointer-events-auto",
              );
            }
          });
        },
        { threshold: 0, rootMargin: "-64px 0px 0px 0px" },
      );
      observer.observe(postHeader);
    }
  }

  // ============================================
  // COMMENTS
  // ============================================

  // --- Load approved comments for this post ---
  function loadComments(postId) {
    fetch(API_BASE + "/posts/" + postId + "/comments")
      .then(function (response) {
        if (!response.ok) throw new Error("Failed");
        return response.json();
      })
      .then(function (comments) {
        renderComments(comments);
      })
      .catch(function () {
        // API not available, show empty state
        renderComments([]);
      });
  }

  // --- Render comments into the DOM ---
  function renderComments(comments) {
    var listEl = document.getElementById("comments-list");
    var emptyEl = document.getElementById("comments-empty");
    var countBadge = document.getElementById("comment-count-badge");
    var engagementCount = document.getElementById("engagement-comment-count");

    if (!listEl) return;

    // Update counts
    var count = comments.length;
    if (countBadge) countBadge.textContent = count;
    if (engagementCount) engagementCount.textContent = count;

    // Empty state
    if (count === 0) {
      listEl.innerHTML = "";
      if (emptyEl) emptyEl.classList.remove("hidden");
      return;
    }

    if (emptyEl) emptyEl.classList.add("hidden");

    // Render each comment
    listEl.innerHTML = comments
      .map(function (comment, index) {
        // Generate initials for avatar
        var initials = comment.author_name
          .split(" ")
          .map(function (w) {
            return w.charAt(0).toUpperCase();
          })
          .join("")
          .substring(0, 2);

        return (
          '<div class="comment-item flex gap-4 p-4 rounded-xl border border-slate-100 dark:border-slate-700/30 bg-white dark:bg-slate-800/30" ' +
          'style="animation: fadeIn 0.4s ease ' +
          index * 0.1 +
          's forwards; opacity: 0;">' +
          // Avatar
          '<div class="flex-shrink-0 w-10 h-10 rounded-full bg-sky-500/10 flex items-center justify-center">' +
          '<span class="text-xs font-bold text-sky-500">' +
          initials +
          "</span>" +
          "</div>" +
          // Content
          '<div class="flex-1 min-w-0">' +
          '<div class="flex items-center gap-2 mb-1">' +
          '<span class="text-sm font-semibold text-slate-900 dark:text-white">' +
          escapeHtml(comment.author_name) +
          "</span>" +
          '<span class="text-xs text-slate-400 dark:text-slate-500">' +
          formatRelativeTime(comment.created_at) +
          "</span>" +
          "</div>" +
          '<p class="text-sm text-slate-600 dark:text-slate-300 leading-relaxed">' +
          escapeHtml(comment.content) +
          "</p>" +
          "</div>" +
          "</div>"
        );
      })
      .join("");
  }

  // --- Escape HTML to prevent XSS in comment content ---
  function escapeHtml(text) {
    var div = document.createElement("div");
    div.appendChild(document.createTextNode(text));
    return div.innerHTML;
  }

  // --- Setup comment form submission ---
  function setupCommentForm(postId) {
    var form = document.getElementById("comment-form");
    if (!form) return;

    // Prevent duplicate listeners when loadPost() is called again (e.g. language switch)
    if (form.dataset.listenerAttached) return;
    form.dataset.listenerAttached = "true";

    form.addEventListener("submit", function (e) {
      e.preventDefault();

      var submitBtn = document.getElementById("comment-submit-btn");
      var nameInput = form.querySelector('[name="author_name"]');
      var contentInput = form.querySelector('[name="content"]');
      var nameError = document.getElementById("name-error");

      if (!nameInput.value.trim() || !contentInput.value.trim()) return;

      // Validate name against blocklist
      if (!isValidName(nameInput.value.trim())) {
        if (nameError) nameError.classList.remove("hidden");
        nameInput.focus();
        return;
      }
      if (nameError) nameError.classList.add("hidden");

      // Disable button during submit
      submitBtn.disabled = true;
      submitBtn.textContent =
        getCurrentLang() === "en" ? "Sending..." : "Wird gesendet...";

      var data = {
        author_name: nameInput.value.trim(),
        content: contentInput.value.trim(),
      };

      fetch(API_BASE + "/posts/" + postId + "/comments", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      })
        .then(function (response) {
          if (!response.ok) throw new Error("Failed");
          return response.json();
        })
        .then(function () {
          // Show success message prominently
          var success = document.getElementById("comment-success");
          if (success) success.classList.remove("hidden");

          // Reset form but keep visible (user can submit another)
          form.reset();
          submitBtn.disabled = false;
          submitBtn.textContent =
            getCurrentLang() === "en" ? "Send comment" : "Kommentar senden";

          // Scroll success message into view
          if (success) {
            success.scrollIntoView({ behavior: "smooth", block: "center" });
          }

          // Fade out success after 30 seconds
          setTimeout(function () {
            if (success) success.classList.add("hidden");
          }, 30000);
        })
        .catch(function () {
          // Re-enable on error
          submitBtn.disabled = false;
          submitBtn.textContent =
            getCurrentLang() === "en" ? "Send comment" : "Kommentar senden";
          alert(
            getCurrentLang() === "en"
              ? "Comment could not be sent. Please try again."
              : "Kommentar konnte nicht gesendet werden. Bitte versuche es erneut.",
          );
        });
    });
  }

  // ============================================
  // CONTENT ANIMATIONS - Subtle scroll reveals
  // ============================================

  // --- Add scroll-reveal animations to post content elements ---
  // Headings slide in from left, code blocks and blockquotes fade in.
  function setupContentAnimations() {
    var contentEl = document.getElementById("post-content");
    if (!contentEl) return;

    // Select elements to animate: headings, paragraphs, code blocks, blockquotes, hr, lists
    var targets = contentEl.querySelectorAll(
      "h2, h3, p, pre, blockquote, hr, ul, ol",
    );
    if (targets.length === 0) return;

    // Apply initial hidden state with staggered delays for paragraphs
    var pIndex = 0;
    for (var i = 0; i < targets.length; i++) {
      var el = targets[i];
      var tagName = el.tagName.toLowerCase();

      // Headings slide in from left (noticeable offset + slow transition)
      if (tagName === "h2" || tagName === "h3") {
        el.style.cssText =
          "opacity:0;transform:translateX(-30px);transition:opacity 0.9s ease-out,transform 0.9s ease-out;";
        pIndex = 0; // Reset paragraph counter after each heading
      }
      // Paragraphs fade in and rise (subtle, quick)
      else if (tagName === "p") {
        var delay = pIndex * 0.05; // Slight stagger between consecutive paragraphs
        el.style.cssText =
          "opacity:0;transform:translateY(16px);transition:opacity 0.6s ease-out " +
          delay +
          "s,transform 0.6s ease-out " +
          delay +
          "s;";
        pIndex++;
      }
      // Lists fade in and rise (like paragraphs)
      else if (tagName === "ul" || tagName === "ol") {
        el.style.cssText =
          "opacity:0;transform:translateY(16px);transition:opacity 0.6s ease-out,transform 0.6s ease-out;";
      }
      // Code blocks slide up and fade in
      else if (tagName === "pre") {
        el.style.cssText =
          "opacity:0;transform:translateY(20px) scale(0.97);transition:opacity 0.8s ease-out,transform 0.8s ease-out;";
      }
      // Blockquotes slide in from left
      else if (tagName === "blockquote") {
        el.style.cssText =
          "opacity:0;transform:translateX(-24px);transition:opacity 0.8s ease-out,transform 0.8s ease-out;";
      }
      // Horizontal rules grow from center
      else if (tagName === "hr") {
        el.style.cssText =
          "opacity:0;transform:scaleX(0.2);transition:opacity 1s ease-out,transform 1s ease-out;transform-origin:center;";
      }
    }

    // Use IntersectionObserver to reveal when scrolled into view
    var observer = new IntersectionObserver(
      function (entries) {
        for (var j = 0; j < entries.length; j++) {
          if (entries[j].isIntersecting) {
            var target = entries[j].target;
            target.style.opacity = "1";
            target.style.transform = "none";
            observer.unobserve(target);
          }
        }
      },
      { threshold: 0.1, rootMargin: "0px 0px -60px 0px" },
    );

    for (var k = 0; k < targets.length; k++) {
      observer.observe(targets[k]);
    }
  }

  // ============================================
  // POST RENDERING
  // ============================================

  // --- Render the post into the page ---
  function renderPost(post) {
    currentPost = post;

    // Set the page title
    document.title = post.title + " - Andy Schlegel Tech Blog";

    // Category badge text
    var categoryEl = document.getElementById("post-category");
    if (categoryEl) categoryEl.textContent = post.category_name || "";

    // Category visual (animated blobs + icon)
    renderCategoryVisual(post.category_slug);

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

    // Tags (colored, with staggered fade-in)
    var TAG_COLORS = [
      {
        bg: "bg-sky-500/10",
        text: "text-sky-500 dark:text-sky-400",
        border: "border-sky-500/20",
      },
      {
        bg: "bg-amber-500/10",
        text: "text-amber-500 dark:text-amber-400",
        border: "border-amber-500/20",
      },
      {
        bg: "bg-green-500/10",
        text: "text-green-500 dark:text-green-400",
        border: "border-green-500/20",
      },
      {
        bg: "bg-purple-500/10",
        text: "text-purple-500 dark:text-purple-400",
        border: "border-purple-500/20",
      },
      {
        bg: "bg-red-500/10",
        text: "text-red-500 dark:text-red-400",
        border: "border-red-500/20",
      },
      {
        bg: "bg-orange-500/10",
        text: "text-orange-500 dark:text-orange-400",
        border: "border-orange-500/20",
      },
      {
        bg: "bg-teal-500/10",
        text: "text-teal-500 dark:text-teal-400",
        border: "border-teal-500/20",
      },
    ];
    var tagsEl = document.getElementById("post-tags");
    if (tagsEl && post.tags) {
      tagsEl.innerHTML = post.tags
        .map(function (tag, i) {
          var c = TAG_COLORS[i % TAG_COLORS.length];
          return (
            '<span class="post-tag px-2.5 py-1 border ' +
            c.border +
            " " +
            c.bg +
            " " +
            c.text +
            ' rounded-full text-xs font-medium" style="opacity:0;animation:fadeIn 0.4s ease ' +
            i * 0.08 +
            's forwards;">' +
            "#" +
            escapeHtml(tag.name) +
            "</span>"
          );
        })
        .join("");
    }

    // Convert Markdown to HTML and insert it
    var contentEl = document.getElementById("post-content");
    if (contentEl) {
      // Sanitize Markdown HTML output to prevent stored XSS attacks.
      // DOMPurify strips dangerous elements (script, onerror, etc.)
      // while keeping safe formatting (h1, p, code, etc.).
      contentEl.innerHTML =
        typeof DOMPurify !== "undefined"
          ? DOMPurify.sanitize(marked.parse(post.content))
          : marked.parse(post.content);
    }

    // Show all sections, hide loading skeleton
    var loading = document.getElementById("post-loading");
    var header = document.getElementById("post-header");
    var contentSection = document.getElementById("post-content-section");
    var engagementSection = document.getElementById("post-engagement-section");
    var footerSection = document.getElementById("post-footer-section");
    var commentsSection = document.getElementById("post-comments-section");

    if (loading) loading.classList.add("hidden");
    if (header) header.classList.remove("hidden");
    if (contentSection) contentSection.classList.remove("hidden");
    if (engagementSection) engagementSection.classList.remove("hidden");
    if (footerSection) footerSection.classList.remove("hidden");
    if (commentsSection) commentsSection.classList.remove("hidden");

    // Setup content scroll-reveal animations
    setupContentAnimations();

    // Setup reading progress bar (tracks scroll through article)
    setupReadingProgress();

    // Setup like button + audio player
    setupLikeButton(post);
    setupAudioButton(post);

    // Load and display comments
    if (post.id) {
      loadComments(post.id);
      setupCommentForm(post.id);
      setupLiveNameValidation();
    }

    // Build prev/next navigation
    loadPostNavigation(post.slug);
  }

  // ============================================
  // POST NAVIGATION (prev/next)
  // ============================================

  // --- Load prev/next post navigation ---
  // Reads the post list context saved by app.js (respects filter,
  // search, sort order). Falls back to full API list if no context
  // exists (e.g. direct link to a post).
  function loadPostNavigation(currentSlug) {
    // Use language-specific cache key so prev/next titles match the active language
    var lang = getCurrentLang();
    var saved = sessionStorage.getItem("postNavContext_" + lang);
    if (saved) {
      try {
        var navList = JSON.parse(saved);
        buildNavFromList(navList, currentSlug);
        return;
      } catch (e) {
        // Invalid JSON, fall through to API fallback
      }
    }

    // Fetch posts with current language for correct translated titles
    var langParam = lang === "en" ? "?lang=en" : "";

    fetch(API_BASE + "/posts" + langParam)
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
        // No navigation available
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

    if (!prevPost && !nextPost) return;
    renderPostNavigation(prevPost, nextPost);
  }

  // --- Render prev/next navigation into the DOM ---
  function renderPostNavigation(prevPost, nextPost) {
    var navEl = document.getElementById("post-navigation");
    if (!navEl) return;

    while (navEl.firstChild) navEl.removeChild(navEl.firstChild);

    if (prevPost) {
      navEl.appendChild(buildNavLink(prevPost, "prev"));
    } else {
      navEl.appendChild(document.createElement("div"));
    }

    if (nextPost) {
      navEl.appendChild(buildNavLink(nextPost, "next"));
    } else {
      navEl.appendChild(document.createElement("div"));
    }

    navEl.classList.remove("hidden");
  }

  // --- Update prev/next titles + labels after language switch ---
  // Keeps navigation structure intact (same prev/next posts), only updates
  // visible text: post titles (from API) and direction labels (DE/EN).
  // This avoids the position-swap bug that happened when rebuilding from
  // the full API list (different order than the blog.html filtered list).
  function refreshNavLanguage(lang) {
    var navEl = document.getElementById("post-navigation");
    if (!navEl) return;
    var links = navEl.querySelectorAll("a");
    if (!links.length) return;

    var langParam = lang === "en" ? "?lang=en" : "";

    // Step 1: Update direction labels immediately (no API needed)
    for (var i = 0; i < links.length; i++) {
      var labelSpan = links[i].querySelector(".text-xs");
      if (!labelSpan) continue;
      var arrow = labelSpan.querySelector("i");
      var isPrev = arrow && arrow.className.indexOf("arrow-left") !== -1;
      // Replace the text node content
      var nodes = labelSpan.childNodes;
      for (var k = 0; k < nodes.length; k++) {
        if (nodes[k].nodeType === 3 && nodes[k].textContent.trim()) {
          nodes[k].textContent = isPrev
            ? lang === "en"
              ? "Previous Post "
              : "Vorheriger Post "
            : lang === "en"
              ? "Next Post "
              : "Nächster Post ";
          break;
        }
      }
    }

    // Step 2: Fetch translated titles from API
    // Collect slugs from existing nav link hrefs
    var slugs = [];
    var linkBySlug = {};
    for (var j = 0; j < links.length; j++) {
      var href = links[j].getAttribute("href") || "";
      var match = href.match(/slug=([^&]+)/);
      if (match) {
        var slug = decodeURIComponent(match[1]);
        slugs.push(slug);
        linkBySlug[slug] = links[j];
      }
    }
    if (!slugs.length) return;

    // Fetch each post individually to get its translated title
    slugs.forEach(function (slug) {
      fetch(API_BASE + "/posts/" + slug + langParam)
        .then(function (r) {
          return r.ok ? r.json() : Promise.reject();
        })
        .then(function (post) {
          var link = linkBySlug[slug];
          if (!link) return;
          var titleSpan = link.querySelector(".line-clamp-2");
          if (titleSpan) titleSpan.textContent = post.title;
        })
        .catch(function () {
          /* keep current title */
        });
    });
  }

  // --- Build a single nav link element ---
  function buildNavLink(post, direction) {
    var isPrev = direction === "prev";

    var link = document.createElement("a");
    link.href = "./post.html?slug=" + encodeURIComponent(post.slug);
    link.className =
      "group flex flex-col p-5 rounded-xl border border-slate-200 " +
      "dark:border-slate-700/50 bg-white dark:bg-slate-800/50 " +
      "hover:border-sky-500/50 dark:hover:border-sky-500/50 transition-all" +
      (isPrev ? "" : " text-right");

    var label = document.createElement("span");
    label.className =
      "flex items-center gap-1.5 text-xs font-medium " +
      "text-slate-400 dark:text-slate-500 mb-2" +
      (isPrev ? "" : " justify-end");

    var arrow = document.createElement("i");
    arrow.className =
      "ti ti-arrow-" +
      (isPrev ? "left" : "right") +
      " text-sm " +
      "group-hover:" +
      (isPrev ? "-translate-x-1" : "translate-x-1") +
      " transition-transform";

    var lang = getCurrentLang();
    var labelText = document.createTextNode(
      isPrev
        ? lang === "en"
          ? "Previous Post"
          : "Vorheriger Post"
        : lang === "en"
          ? "Next Post"
          : "Nächster Post",
    );

    if (isPrev) {
      label.appendChild(arrow);
      label.appendChild(labelText);
    } else {
      label.appendChild(labelText);
      label.appendChild(arrow);
    }

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

  // ============================================
  // READING PROGRESS BAR
  // ============================================

  // --- Update the reading progress bar width based on scroll position ---
  // Calculates how far through the article content the user has scrolled.
  // Uses requestAnimationFrame to avoid layout thrashing on scroll.
  function setupReadingProgress() {
    var progressBar = document.getElementById("reading-progress");
    var articleEl = document.getElementById("post-content-section");
    if (!progressBar || !articleEl) return;

    var ticking = false;

    function updateProgress() {
      var articleTop = articleEl.offsetTop;
      var articleHeight = articleEl.offsetHeight;
      var scrollTop = window.scrollY || document.documentElement.scrollTop;
      var viewportHeight = window.innerHeight;

      // Calculate progress: 0% at article start, 100% at article end
      var articleEnd = articleTop + articleHeight - viewportHeight;
      var progress = 0;

      if (scrollTop >= articleTop) {
        progress = (scrollTop - articleTop) / (articleEnd - articleTop);
      }

      // Clamp between 0 and 1
      progress = Math.min(Math.max(progress, 0), 1);
      progressBar.style.width = progress * 100 + "%";
      ticking = false;
    }

    window.addEventListener("scroll", function () {
      if (!ticking) {
        requestAnimationFrame(updateProgress);
        ticking = true;
      }
    });

    // Run once on setup in case the page is already scrolled
    updateProgress();
  }

  // ============================================
  // ERROR STATE
  // ============================================

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

  // ============================================
  // MAIN - Load post from API
  // ============================================

  function loadPost() {
    var slug = getSlugFromUrl();

    if (!slug) {
      showError("Kein Post angegeben.");
      return;
    }

    // Validate slug format to prevent path traversal in API calls.
    // Slugs must only contain lowercase letters, numbers, and hyphens.
    if (!/^[a-z0-9-]+$/.test(slug)) {
      showError("Invalid post slug.");
      return;
    }

    setupMarked();

    // Build URL with language parameter
    var lang = getCurrentLang();
    var langParam = lang === "en" ? "?lang=en" : "";

    fetch(API_BASE + "/posts/" + slug + langParam)
      .then(function (response) {
        if (!response.ok) throw new Error("Not found");
        return response.json();
      })
      .then(function (post) {
        renderPost(post);
      })
      .catch(function () {
        // API not available - show demo post
        if (slug === DEMO_POST.slug || slug === "demo") {
          renderPost(DEMO_POST);
        } else {
          renderPost(DEMO_POST);
        }
      });
  }

  // --- Update static UI text based on current language ---
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
  }

  document.addEventListener("DOMContentLoaded", function () {
    loadPost();
    updateStaticText();

    // Re-load post content when language is toggled (DE/EN)
    // Navigation is preserved -- only post body + labels update
    window.addEventListener("languageChanged", function () {
      updateStaticText();

      // Re-fetch post content in new language (translated body from API)
      var slug = getSlugFromUrl();
      if (!slug) return;
      var lang = getCurrentLang();
      var langParam = lang === "en" ? "?lang=en" : "";

      fetch(API_BASE + "/posts/" + slug + langParam)
        .then(function (response) {
          if (!response.ok) throw new Error("Not found");
          return response.json();
        })
        .then(function (post) {
          // Update content areas
          var titleEl = document.getElementById("post-title");
          var contentEl = document.getElementById("post-content");
          if (titleEl) titleEl.textContent = post.title;
          if (contentEl && post.content) {
            // Sanitize translated Markdown to prevent XSS
            var parsedHtml =
              typeof marked !== "undefined"
                ? marked.parse(post.content)
                : post.content;
            contentEl.innerHTML =
              typeof DOMPurify !== "undefined"
                ? DOMPurify.sanitize(parsedHtml)
                : parsedHtml;
          }
          // Update nav titles + labels in-place (keeps prev/next positions stable)
          refreshNavLanguage(lang);
        })
        .catch(function () {
          // Silently fail -- keep current content
        });
    });
  });
})();
