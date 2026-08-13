(function () {
  "use strict";

  var LOGIN = "https://login.sethcharleston.com/login?response_type=token&client_id=76g2um3ps3ri68ac30agopcmc9&redirect_uri=https://edit.sethcharleston.com";
  var previewMode = LOGIN === "PREVIEW";
  var hash = new URLSearchParams(location.hash.slice(1));
  var received = hash.get("id_token");

  if (received) {
    sessionStorage.setItem("editor_id_token", received);
    history.replaceState(null, "", location.pathname + location.search);
  }

  var token = received || sessionStorage.getItem("editor_id_token") || "";
  var shell = document.getElementById("editorShell");

  document.body.addEventListener("htmx:configRequest", function (event) {
    if (token) event.detail.headers.Authorization = token;
  });

  document.body.addEventListener("htmx:afterRequest", function (event) {
    if (event.detail.successful && event.detail.elt.matches("[data-editor-form]")) {
      htmx.trigger("#editorPanel", "load");
    }
  });

  if (previewMode || token) shell.hidden = false;
  else location.href = LOGIN;
})();
