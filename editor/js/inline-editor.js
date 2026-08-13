(function () {
  "use strict";

  var API = "https://api.sethcharleston.com/test1";
  var LOGIN = "https://login.sethcharleston.com/login?response_type=token&client_id=76g2um3ps3ri68ac30agopcmc9&redirect_uri=https://edit.sethcharleston.com";
  var LIVE_SITE = "https://sethcharleston.com";
  var page = location.pathname.split("/").pop() || "index.html";
  var token = readToken();
  var signedIn = false;
  var previewMode = LOGIN === "PREVIEW";
  var toolbar;
  var status;

  function readToken() {
    var hash = new URLSearchParams(location.hash.slice(1));
    var received = hash.get("id_token");
    if (received) {
      sessionStorage.setItem("editor_id_token", received);
      history.replaceState(null, "", location.pathname + location.search);
      var returnPage = sessionStorage.getItem("editor_return_page");
      sessionStorage.removeItem("editor_return_page");
      if (returnPage && !location.pathname.endsWith(returnPage)) location.replace(returnPage);
    }
    return received || sessionStorage.getItem("editor_id_token") || "";
  }

  function setStatus(message, state) {
    status.textContent = message;
    status.dataset.state = state || "";
  }

  function request(path, options) {
    options = options || {};
    options.headers = Object.assign({ "Content-Type": "application/json" }, token ? { Authorization: token } : {}, options.headers || {});
    document.body.classList.add("edit-busy");
    return fetch(API + path, options).then(function (response) {
      if (!response.ok) throw new Error("Request failed (" + response.status + ")");
      return response.text().then(function (text) {
        try { return JSON.parse(text); } catch (_) { return text; }
      });
    }).finally(function () { document.body.classList.remove("edit-busy"); });
  }

  function createToolbar() {
    toolbar = document.createElement("aside");
    toolbar.className = "edit-toolbar";
    toolbar.setAttribute("aria-label", "Page editing controls");
    status = document.createElement("span");
    status.className = "edit-status";
    status.setAttribute("aria-live", "polite");
    toolbar.appendChild(status);
    document.body.appendChild(toolbar);
  }

  function button(label, action, primary) {
    var element = document.createElement("button");
    element.type = "button";
    element.textContent = label;
    if (primary) element.className = "edit-primary";
    element.addEventListener("click", action);
    toolbar.appendChild(element);
    return element;
  }

  function authenticate() {
    if (previewMode) return request("/access").then(function () { return true; });
    if (!token) return Promise.resolve(false);
    return request("/access").then(function () { return true; }).catch(function () {
      sessionStorage.removeItem("editor_id_token");
      token = "";
      return false;
    });
  }

  function hydrateTextPage() {
    if (page !== "index.html" && page !== "about.html") return Promise.resolve();
    return fetch(API + "/text").then(function (response) { return response.json(); }).then(function (items) {
      items.forEach(function (item) {
        var element = document.getElementById(item.location);
        if (element) element.innerHTML = item.text;
      });
    });
  }

  function editableText(config) {
    var dirty = false;
    function markEditable() {
      config.fields.forEach(function (field) {
        var element = document.getElementById(field.id);
        if (!element || element.dataset.inlineEditable === "true") return;
        element.contentEditable = "true";
        element.dataset.inlineEditable = "true";
        element.setAttribute("role", "textbox");
        element.setAttribute("aria-label", field.label);
        element.addEventListener("input", function () {
          dirty = true;
          setStatus("Unsaved changes");
        });
      });
    }
    markEditable();
    document.body.addEventListener("htmx:afterSettle", markEditable);
    button("Save changes", function () {
      var data = config.fields.map(function (field) {
        var element = document.getElementById(field.id);
        return { location: field.location, text: element.innerHTML.trim() };
      });
      setStatus("Saving…");
      request("/text/", { method: "POST", body: JSON.stringify(data) }).then(function () {
        dirty = false;
        setStatus("Saved", "success");
      }).catch(function (error) { setStatus(error.message, "error"); });
    }, true);
    window.addEventListener("beforeunload", function (event) {
      if (dirty) { event.preventDefault(); event.returnValue = ""; }
    });
  }

  function dialog(title, fields, onSave) {
    var modal = document.createElement("dialog");
    modal.className = "edit-dialog";
    var heading = document.createElement("h2");
    heading.textContent = title;
    modal.appendChild(heading);
    fields.forEach(function (field) {
      var label = document.createElement("label");
      label.textContent = field.label;
      label.htmlFor = "edit-" + field.name;
      var input = field.multiline ? document.createElement("textarea") : document.createElement("input");
      input.id = "edit-" + field.name;
      input.name = field.name;
      if (!field.multiline) input.type = field.type || "text";
      input.value = field.value || "";
      input.required = field.required !== false;
      modal.appendChild(label);
      modal.appendChild(input);
    });
    var menu = document.createElement("menu");
    var cancel = document.createElement("button");
    cancel.type = "button";
    cancel.textContent = "Cancel";
    function closeModal() {
      if (typeof modal.close === "function") modal.close();
      else {
        modal.removeAttribute("open");
        modal.dispatchEvent(new Event("close"));
      }
    }
    modal.closeEditor = closeModal;
    cancel.addEventListener("click", closeModal);
    var save = document.createElement("button");
    save.type = "button";
    save.className = "edit-primary";
    save.textContent = "Save";
    save.addEventListener("click", function () {
      var invalid = Array.from(modal.querySelectorAll("input, textarea")).find(function (input) { return !input.checkValidity(); });
      if (invalid) { invalid.reportValidity(); return; }
      var values = {};
      fields.forEach(function (field) { values[field.name] = modal.querySelector('[name="' + field.name + '"]').value; });
      onSave(values, modal);
    });
    menu.append(cancel, save);
    modal.appendChild(menu);
    document.body.appendChild(modal);
    modal.addEventListener("close", function () { modal.remove(); });
    if (typeof modal.showModal === "function") modal.showModal();
    else modal.setAttribute("open", "");
  }

  function controls(item, onEdit, onDelete) {
    item.classList.add("edit-item");
    var wrap = document.createElement("span");
    wrap.className = "edit-item-controls";
    [["Edit", onEdit], ["Delete", onDelete]].forEach(function (entry) {
      var control = document.createElement("button");
      control.type = "button";
      control.className = "edit-control";
      control.textContent = entry[0];
      control.addEventListener("click", entry[1]);
      wrap.appendChild(control);
    });
    item.appendChild(wrap);
  }

  function mediaUpload(slot, label, accept) {
    button(label, function () {
      var input = document.createElement("input");
      input.type = "file";
      input.accept = accept;
      input.addEventListener("change", function () {
        var file = input.files && input.files[0];
        if (!file) return;
        var limit = slot === "home-video" ? 100 * 1024 * 1024 : 15 * 1024 * 1024;
        if (file.size > limit) { setStatus("File is too large", "error"); return; }
        setStatus("Uploading…");
        request("/media/upload", { method: "POST", body: JSON.stringify({ slot: slot, contentType: file.type }) })
          .then(function (upload) {
            return fetch(upload.uploadUrl, { method: "PUT", headers: { "Content-Type": file.type }, body: file })
              .then(function (response) {
                if (!response.ok) throw new Error("Upload failed (" + response.status + ")");
                return request("/media/commit", { method: "POST", body: JSON.stringify({ slot: slot, key: upload.key }) });
              });
          })
          .then(function () {
            var mediaUrl = API + "/media/" + slot + "?v=" + Date.now();
            document.querySelectorAll('[src*="/media/' + slot + '"]').forEach(function (element) {
              element.src = mediaUrl;
              if (element.tagName === "SOURCE") element.parentElement.load();
            });
            document.querySelectorAll('[poster*="/media/' + slot + '"]').forEach(function (element) { element.poster = mediaUrl; });
            setStatus("Media updated", "success");
          })
          .catch(function (error) { setStatus(error.message, "error"); });
      });
      input.click();
    });
  }

  function musicEditor() {
    var root = document.getElementById("info");
    function render() {
      setStatus("Loading…");
      fetch(API + "/songs").then(function (r) { return r.json(); }).then(function (songs) {
        songs.sort(function (a, b) { return new Date(b.release) - new Date(a.release); });
        root.innerHTML = "";
        songs.forEach(function (song) {
          var item = document.createElement("article");
          item.className = "col-span-full mx-auto w-full max-w-4xl overflow-hidden rounded-xl shadow-[0_16px_32px_rgba(0,0,0,0.8)]";
          item.setAttribute("aria-label", song.song);
          item.innerHTML = song.link;
          controls(item, function () { musicDialog(song); }, function () { removeMusic(song); });
          root.appendChild(item);
        });
        setStatus("Ready", "success");
      }).catch(function (error) { setStatus(error.message, "error"); });
    }
    function musicDialog(song) {
      song = song || {};
      dialog(song.song ? "Edit music" : "Add music", [
        { name: "song", label: "Song or album name", value: song.song },
        { name: "link", label: "Spotify embed HTML", value: song.link, multiline: true },
        { name: "release", label: "Release date", type: "date", value: song.release ? new Date(song.release).toISOString().slice(0, 10) : "" }
      ], function (values, modal) {
        var payload = { song: values.song, link: values.link, release: new Date(values.release + "T00:00:00").toString() };
        request("/songs", { method: "POST", body: JSON.stringify(payload) }).then(function () {
          if (song.song && song.song !== values.song) {
            return request("/delete_song", { method: "POST", body: JSON.stringify({ song: song.song }) });
          }
        }).then(function () { modal.closeEditor(); render(); }).catch(function (error) { setStatus(error.message, "error"); });
      });
    }
    function removeMusic(song) {
      if (!confirm("Delete “" + song.song + "”?")) return;
      request("/delete_song", { method: "POST", body: JSON.stringify({ song: song.song }) }).then(render).catch(function (e) { setStatus(e.message, "error"); });
    }
    button("Add music", function () { musicDialog(); }, true);
    render();
  }

  function showsEditor() {
    var root = document.getElementById("info");
    function render() {
      setStatus("Loading…");
      fetch(API + "/").then(function (r) { return r.json(); }).then(function (response) {
        var events = response.Items || response;
        events.sort(function (a, b) { return new Date(a.when) - new Date(b.when); });
        root.innerHTML = "";
        events.forEach(function (event) {
          var when = new Date(event.when);
          var item = document.createElement("article");
          item.className = "col-span-full rounded-xl bg-[#f5f5f5] p-8 text-center shadow-[0_16px_32px_rgba(0,0,0,0.35)]";
          item.innerHTML = "<h2 class=\"font-display text-3xl text-stone-800\"></h2><p class=\"mt-3 text-sm uppercase tracking-[0.18em] text-stone-500\"></p><p class=\"mt-2 text-stone-700\"></p><a class=\"mt-6 inline-block bg-[#6b6b6b] px-6 py-3 text-sm font-bold uppercase tracking-widest text-white shadow-md transition-colors hover:bg-[#4f4f4f]\" target=\"_blank\" rel=\"noopener\">Tickets</a>";
          item.querySelector("h2").textContent = event.name;
          item.querySelectorAll("p")[0].textContent = when.toLocaleDateString("en-US", { weekday: "long", year: "numeric", month: "long", day: "numeric" });
          item.querySelectorAll("p")[1].textContent = event.where;
          item.querySelector("a").href = event.tickets;
          controls(item, function () { showDialog(event); }, function () { removeShow(event); });
          root.appendChild(item);
        });
        setStatus("Ready", "success");
      }).catch(function (error) { setStatus(error.message, "error"); });
    }
    function showDialog(event) {
      event = event || {};
      var when = event.when ? new Date(event.when) : null;
      dialog(event.event ? "Edit show" : "Add show", [
        { name: "name", label: "Event name", value: event.name },
        { name: "date", label: "Date", type: "date", value: when ? when.toISOString().slice(0, 10) : "" },
        { name: "time", label: "Time", type: "time", value: when ? when.toTimeString().slice(0, 5) : "" },
        { name: "where", label: "Venue", value: event.where },
        { name: "tickets", label: "Ticket URL", type: "url", value: event.tickets }
      ], function (values, modal) {
        var payload = { name: values.name, when: new Date(values.date + "T" + values.time).toString(), where: values.where, tickets: values.tickets };
        if (event.event) payload.event = event.event;
        request("", { method: "POST", body: JSON.stringify(payload) }).then(function () { modal.closeEditor(); render(); }).catch(function (error) { setStatus(error.message, "error"); });
      });
    }
    function removeShow(event) {
      if (!confirm("Delete “" + event.name + "”?")) return;
      request("/delete", { method: "POST", body: JSON.stringify({ event: event.event }) }).then(render).catch(function (e) { setStatus(e.message, "error"); });
    }
    button("Add show", function () { showDialog(); }, true);
    render();
  }

  function servicesEditor() {
    var root = document.getElementById("servicesList");
    var services = [];
    function save() {
      setStatus("Saving…");
      return request("/text/", { method: "POST", body: JSON.stringify([{ location: "services", text: JSON.stringify(services) }]) })
        .then(function () { render(); setStatus("Saved", "success"); })
        .catch(function (error) { setStatus(error.message, "error"); });
    }
    function serviceDialog(service, index) {
      service = service || {};
      dialog(index == null ? "Add service" : "Edit service", [
        { name: "title", label: "Service name", value: service.title },
        { name: "description", label: "Description", value: service.description, multiline: true }
      ], function (values, modal) {
        var updated = { title: values.title.trim(), description: values.description.trim() };
        if (index == null) services.push(updated);
        else services[index] = updated;
        modal.closeEditor();
        save();
      });
    }
    function render() {
      root.innerHTML = "";
      var grid = document.createElement("div");
      grid.className = "grid gap-7 md:grid-cols-3";
      services.forEach(function (service, index) {
        var card = document.createElement("article");
        card.className = "edit-item rounded-xl bg-[#f5f5f5] p-8 shadow-[0_16px_32px_rgba(0,0,0,0.35)]";
        var title = document.createElement("h2");
        title.className = "font-display text-4xl text-[#393939]";
        title.textContent = service.title;
        var description = document.createElement("p");
        description.className = "mt-4 leading-7 text-stone-600";
        description.textContent = service.description;
        var actions = document.createElement("span");
        actions.className = "edit-item-controls";
        [
          ["Edit", function () { serviceDialog(service, index); }],
          ["Earlier", function () { if (index > 0) { services.splice(index - 1, 0, services.splice(index, 1)[0]); save(); } }],
          ["Later", function () { if (index < services.length - 1) { services.splice(index + 1, 0, services.splice(index, 1)[0]); save(); } }],
          ["Delete", function () { if (confirm("Delete “" + service.title + "”?")) { services.splice(index, 1); save(); } }]
        ].forEach(function (entry) {
          var action = document.createElement("button");
          action.type = "button";
          action.className = "edit-control";
          action.textContent = entry[0];
          action.addEventListener("click", entry[1]);
          actions.appendChild(action);
        });
        card.append(title, description, actions);
        grid.appendChild(card);
      });
      root.appendChild(grid);
    }
    button("Add service", function () { serviceDialog(); }, true);
    setStatus("Loading…");
    fetch(API + "/text").then(function (response) { return response.json(); }).then(function (items) {
      var stored = items.find(function (item) { return item.location === "services"; });
      services = stored ? JSON.parse(stored.text) : (window.defaultServices || []).slice();
      render();
      setStatus("Ready", "success");
    }).catch(function (error) { setStatus(error.message, "error"); });
  }

  function enableEditor() {
    setStatus("Signed in", "success");
    button("View live site", function () { location.href = LIVE_SITE + "/" + (page === "index.html" ? "" : page); });
    if (page === "index.html") {
      mediaUpload("home-video", "Change header video", "video/mp4,video/webm");
      mediaUpload("home-mobile", "Change mobile header", "image/jpeg,image/png,image/webp,image/gif");
      mediaUpload("home-logo", "Change mobile logo", "image/jpeg,image/png,image/webp,image/gif");
    } else {
      mediaUpload(page.replace(".html", "") + "-header", "Change header photo", "image/jpeg,image/png,image/webp,image/gif");
    }
    mediaUpload("footer-photo", "Change footer photo", "image/jpeg,image/png,image/webp,image/gif");
    if (page === "index.html") {
      editableText({ fields: [
      { id: "frontPageHeader", location: "frontPageHeader", label: "Home page heading" },
      { id: "frontPageText", location: "frontPageText", label: "Home page text" }
      ] });
      button("Edit newest video", function () {
        var video = document.getElementById("frontPageVideo");
        var clone = video.cloneNode(true);
        var heading = clone.querySelector("h1");
        if (heading) heading.remove();
        dialog("Edit newest video", [{ name: "video", label: "YouTube embed HTML", value: clone.innerHTML.trim(), multiline: true }], function (values, modal) {
          request("/text/", { method: "POST", body: JSON.stringify([{ location: "frontPageVideo", text: values.video }]) }).then(function () {
            video.innerHTML = "<h1>Newest Video</h1>" + values.video;
            modal.closeEditor();
            setStatus("Saved", "success");
          }).catch(function (error) { setStatus(error.message, "error"); });
        });
      });
    }
    else if (page === "about.html") editableText({ fields: [{ id: "bio", location: "bio", label: "Biography" }] });
    else if (page === "music.html") musicEditor();
    else if (page === "shows.html") showsEditor();
    else if (page === "services.html") servicesEditor();
  }

  createToolbar();
  authenticate().then(function (valid) {
    signedIn = valid;
    if (signedIn) return hydrateTextPage().then(enableEditor);
    else {
      setStatus("Sign in to edit");
      button("Sign in", function () {
        sessionStorage.setItem("editor_return_page", page);
        location.href = LOGIN;
      }, true);
      button("View live site", function () { location.href = LIVE_SITE + "/" + (page === "index.html" ? "" : page); });
    }
  });
}());
