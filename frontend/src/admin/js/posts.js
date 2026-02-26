// ============================================
// Post Management Logic
//
// Handles the admin post list and editor:
//   - loadPostList() fetches all posts from /api/admin/posts
//   - showEditor(id?) opens the editor for new or existing post
//   - hideEditor() returns to the list view
//   - setupPreview() enables live Markdown preview
//   - savePost() creates or updates a post via API
//   - deletePost(id) deletes a post after confirmation
// ============================================

(function () {
  "use strict";

  // --- State ---
  var editingPostId = null; // null = new post, number = editing existing
  var categories = [];
  var previewTimer = null;

  // --- DOM references (cached on DOMContentLoaded) ---
  var listView, editorView;
  var postListEl, newPostBtn;
  var editorTitle,
    editorSubtitle,
    editorBackBtn,
    editorSaveBtn,
    editorCancelBtn;
  var fieldTitle,
    fieldCategory,
    fieldStatus,
    fieldFeatured,
    fieldExcerpt,
    fieldTags,
    fieldContent;
  var previewEl;

  // --- Status badge HTML (matches admin.js pattern) ---
  function statusBadge(status) {
    var colors = {
      published:
        "bg-green-500/10 text-green-600 dark:text-green-400 border-green-500/20",
      draft:
        "bg-amber-500/10 text-amber-600 dark:text-amber-400 border-amber-500/20",
      archived: "bg-slate-500/10 text-slate-500 border-slate-500/20",
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

  // --- Load categories for the dropdown ---
  async function loadCategories() {
    try {
      var response = await fetch("/api/categories");
      if (response.ok) {
        categories = await response.json();
      }
    } catch (err) {
      console.warn("Failed to load categories:", err.message);
    }

    // Populate dropdown
    fieldCategory.innerHTML = '<option value="">Select category...</option>';
    categories.forEach(function (cat) {
      var option = document.createElement("option");
      option.value = cat.id;
      option.textContent = cat.name;
      fieldCategory.appendChild(option);
    });
  }

  // --- Load and render post list ---
  async function loadPostList() {
    postListEl.innerHTML =
      '<div class="p-6 text-center text-sm text-slate-400 dark:text-slate-500">Loading...</div>';

    var posts = [];
    try {
      var response = await AdminAuth.authFetch("/api/admin/posts");
      if (response.ok) {
        posts = await response.json();
      }
    } catch (err) {
      console.warn("Failed to load posts:", err.message);
    }

    if (posts.length === 0) {
      postListEl.innerHTML =
        '<div class="p-8 text-center">' +
        '<i class="ti ti-article text-4xl text-slate-300 dark:text-slate-600 mb-3 block"></i>' +
        '<p class="text-sm text-slate-400 dark:text-slate-500">No posts yet. Create your first post!</p>' +
        "</div>";
      return;
    }

    // Render table header + rows
    var html =
      '<div class="overflow-x-auto">' +
      '<table class="w-full">' +
      "<thead>" +
      '<tr class="border-b border-slate-200 dark:border-slate-700/50">' +
      '<th class="text-left px-5 py-3 text-[11px] font-semibold uppercase tracking-wider text-slate-400 dark:text-slate-500">Title</th>' +
      '<th class="text-left px-5 py-3 text-[11px] font-semibold uppercase tracking-wider text-slate-400 dark:text-slate-500">Status</th>' +
      '<th class="text-left px-5 py-3 text-[11px] font-semibold uppercase tracking-wider text-slate-400 dark:text-slate-500 hidden md:table-cell">Category</th>' +
      '<th class="text-left px-5 py-3 text-[11px] font-semibold uppercase tracking-wider text-slate-400 dark:text-slate-500 hidden lg:table-cell">Date</th>' +
      '<th class="text-left px-5 py-3 text-[11px] font-semibold uppercase tracking-wider text-slate-400 dark:text-slate-500 hidden lg:table-cell">Views</th>' +
      '<th class="text-right px-5 py-3 text-[11px] font-semibold uppercase tracking-wider text-slate-400 dark:text-slate-500">Actions</th>' +
      "</tr>" +
      "</thead>" +
      "<tbody>";

    posts.forEach(function (post) {
      var date = formatDate(post.published_at || post.created_at);
      var featuredIcon = post.featured
        ? ' <i class="ti ti-star-filled text-amber-400 text-xs" title="Featured"></i>'
        : "";

      html +=
        '<tr class="admin-table-row border-b border-slate-100 dark:border-slate-700/30 last:border-0">' +
        '<td class="px-5 py-3">' +
        '<div class="flex items-center gap-1.5">' +
        '<span class="text-sm font-medium text-slate-900 dark:text-white">' +
        truncate(post.title, 50) +
        "</span>" +
        featuredIcon +
        "</div>" +
        "</td>" +
        '<td class="px-5 py-3">' +
        statusBadge(post.status) +
        "</td>" +
        '<td class="px-5 py-3 hidden md:table-cell">' +
        '<span class="text-xs text-slate-500 dark:text-slate-400">' +
        (post.category_name || "--") +
        "</span>" +
        "</td>" +
        '<td class="px-5 py-3 hidden lg:table-cell">' +
        '<span class="text-xs text-slate-500 dark:text-slate-400">' +
        date +
        "</span>" +
        "</td>" +
        '<td class="px-5 py-3 hidden lg:table-cell">' +
        '<span class="text-xs text-slate-500 dark:text-slate-400">' +
        (post.view_count || 0) +
        "</span>" +
        "</td>" +
        '<td class="px-5 py-3 text-right">' +
        '<div class="flex items-center justify-end gap-1">' +
        '<button class="admin-action-btn admin-action-edit" data-id="' +
        post.id +
        '" title="Edit">' +
        '<i class="ti ti-edit"></i>' +
        "</button>" +
        '<button class="admin-action-btn admin-action-delete" data-id="' +
        post.id +
        '" data-title="' +
        post.title.replace(/"/g, "&quot;") +
        '" title="Delete">' +
        '<i class="ti ti-trash"></i>' +
        "</button>" +
        "</div>" +
        "</td>" +
        "</tr>";
    });

    html += "</tbody></table></div>";
    postListEl.innerHTML = html;

    // Attach event listeners to action buttons
    postListEl.querySelectorAll(".admin-action-edit").forEach(function (btn) {
      btn.addEventListener("click", function () {
        showEditor(parseInt(btn.getAttribute("data-id"), 10));
      });
    });

    postListEl.querySelectorAll(".admin-action-delete").forEach(function (btn) {
      btn.addEventListener("click", function () {
        var id = parseInt(btn.getAttribute("data-id"), 10);
        var title = btn.getAttribute("data-title");
        deletePost(id, title);
      });
    });
  }

  // --- Show editor view (new or edit mode) ---
  async function showEditor(postId) {
    editingPostId = postId || null;

    // Reset form
    fieldTitle.value = "";
    fieldCategory.value = "";
    fieldStatus.value = "draft";
    fieldFeatured.checked = false;
    fieldExcerpt.value = "";
    fieldTags.value = "";
    fieldContent.value = "";
    previewEl.innerHTML =
      '<p class="text-slate-400 dark:text-slate-500 text-sm italic">Preview will appear here...</p>';

    if (editingPostId) {
      // Load existing post data
      editorTitle.textContent = "Edit Post";
      editorSubtitle.textContent = "Modify and save your changes";

      try {
        var response = await AdminAuth.authFetch(
          "/api/admin/posts/" + editingPostId,
        );
        if (response.ok) {
          var post = await response.json();
          fieldTitle.value = post.title || "";
          fieldCategory.value = post.category_id || "";
          fieldStatus.value = post.status || "draft";
          fieldFeatured.checked = post.featured || false;
          fieldExcerpt.value = post.excerpt || "";
          fieldContent.value = post.content || "";

          // Set tags
          if (post.tags && post.tags.length > 0) {
            fieldTags.value = post.tags
              .map(function (t) {
                return t.name;
              })
              .join(", ");
          }

          // Trigger preview update
          updatePreview();
        }
      } catch (err) {
        console.warn("Failed to load post for editing:", err.message);
      }
    } else {
      editorTitle.textContent = "New Post";
      editorSubtitle.textContent = "Create a new blog post";
    }

    // Update URL params
    var url = new URL(window.location);
    if (editingPostId) {
      url.searchParams.set("edit", editingPostId);
      url.searchParams.delete("action");
    } else {
      url.searchParams.set("action", "new");
      url.searchParams.delete("edit");
    }
    window.history.pushState({}, "", url);

    // Toggle views
    listView.classList.add("hidden");
    editorView.classList.remove("hidden");
  }

  // --- Hide editor, return to list ---
  function hideEditor() {
    editingPostId = null;

    // Clean URL params
    var url = new URL(window.location);
    url.searchParams.delete("action");
    url.searchParams.delete("edit");
    window.history.pushState({}, "", url);

    editorView.classList.add("hidden");
    listView.classList.remove("hidden");
  }

  // --- Live Markdown preview ---
  function updatePreview() {
    var markdown = fieldContent.value;
    if (!markdown.trim()) {
      previewEl.innerHTML =
        '<p class="text-slate-400 dark:text-slate-500 text-sm italic">Preview will appear here...</p>';
      return;
    }

    // Configure marked with highlight.js for code blocks
    marked.setOptions({
      highlight: function (code, lang) {
        if (lang && hljs.getLanguage(lang)) {
          return hljs.highlight(code, { language: lang }).value;
        }
        return hljs.highlightAuto(code).value;
      },
      breaks: true,
    });

    previewEl.innerHTML = marked.parse(markdown);
  }

  function setupPreview() {
    fieldContent.addEventListener("input", function () {
      // Debounce: wait 300ms after last keystroke
      clearTimeout(previewTimer);
      previewTimer = setTimeout(updatePreview, 300);
    });
  }

  // --- Save post (create or update) ---
  async function savePost() {
    var title = fieldTitle.value.trim();
    var content = fieldContent.value.trim();
    var categoryId = fieldCategory.value;

    // Basic validation
    if (!title) {
      alert("Please enter a post title.");
      fieldTitle.focus();
      return;
    }
    if (!content) {
      alert("Please enter some content.");
      fieldContent.focus();
      return;
    }
    if (!categoryId) {
      alert("Please select a category.");
      fieldCategory.focus();
      return;
    }

    // Build request body
    var body = {
      title: title,
      content: content,
      category_id: parseInt(categoryId, 10),
      status: fieldStatus.value,
      featured: fieldFeatured.checked,
      excerpt: fieldExcerpt.value.trim() || null,
    };

    // Parse tags
    var tagsValue = fieldTags.value.trim();
    if (tagsValue) {
      body.tags = tagsValue
        .split(",")
        .map(function (t) {
          return t.trim();
        })
        .filter(function (t) {
          return t.length > 0;
        });
    }

    // Determine method and URL
    var method = editingPostId ? "PUT" : "POST";
    var url = editingPostId ? "/api/posts/" + editingPostId : "/api/posts";

    try {
      editorSaveBtn.disabled = true;
      editorSaveBtn.innerHTML =
        '<i class="ti ti-loader-2 animate-spin text-base"></i> Saving...';

      var response = await AdminAuth.authFetch(url, {
        method: method,
        body: JSON.stringify(body),
      });

      if (response.ok) {
        // Reload list and go back
        hideEditor();
        await loadPostList();
      } else {
        var err = await response.json();
        alert("Failed to save: " + (err.error || response.statusText));
      }
    } catch (err) {
      alert("Network error: " + err.message);
    } finally {
      editorSaveBtn.disabled = false;
      editorSaveBtn.innerHTML =
        '<i class="ti ti-device-floppy text-base"></i> Save Post';
    }
  }

  // --- Delete a post ---
  async function deletePost(id, title) {
    var confirmed = confirm(
      'Delete "' +
        title +
        '"?\n\nThis will permanently remove the post and all its comments.',
    );
    if (!confirmed) return;

    try {
      var response = await AdminAuth.authFetch("/api/posts/" + id, {
        method: "DELETE",
      });

      if (response.ok) {
        await loadPostList();
      } else {
        var err = await response.json();
        alert("Failed to delete: " + (err.error || response.statusText));
      }
    } catch (err) {
      alert("Network error: " + err.message);
    }
  }

  // --- Theme label update (same as admin.js) ---
  function updateThemeLabel() {
    var label = document.getElementById("theme-label");
    if (label) {
      var isDark = document.documentElement.classList.contains("dark");
      label.textContent = isDark ? "Light Mode" : "Dark Mode";
    }
  }

  // --- Handle URL params on page load ---
  function handleUrlParams() {
    var params = new URLSearchParams(window.location.search);
    if (params.get("action") === "new") {
      showEditor(null);
    } else if (params.get("edit")) {
      showEditor(parseInt(params.get("edit"), 10));
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
    listView = document.getElementById("post-list-view");
    editorView = document.getElementById("post-editor-view");
    postListEl = document.getElementById("post-list");
    newPostBtn = document.getElementById("new-post-btn");
    editorTitle = document.getElementById("editor-title");
    editorSubtitle = document.getElementById("editor-subtitle");
    editorBackBtn = document.getElementById("editor-back-btn");
    editorSaveBtn = document.getElementById("editor-save-btn");
    editorCancelBtn = document.getElementById("editor-cancel-btn");
    fieldTitle = document.getElementById("editor-field-title");
    fieldCategory = document.getElementById("editor-field-category");
    fieldStatus = document.getElementById("editor-field-status");
    fieldFeatured = document.getElementById("editor-field-featured");
    fieldExcerpt = document.getElementById("editor-field-excerpt");
    fieldTags = document.getElementById("editor-field-tags");
    fieldContent = document.getElementById("editor-field-content");
    previewEl = document.getElementById("editor-preview");

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

    // Button handlers
    newPostBtn.addEventListener("click", function () {
      showEditor(null);
    });
    editorBackBtn.addEventListener("click", hideEditor);
    editorCancelBtn.addEventListener("click", hideEditor);
    editorSaveBtn.addEventListener("click", savePost);

    // Set up live preview
    setupPreview();

    // Load data
    await loadCategories();
    await loadPostList();

    // Check URL params (e.g. ?action=new or ?edit=5)
    handleUrlParams();
  }

  document.addEventListener("DOMContentLoaded", init);
})();
