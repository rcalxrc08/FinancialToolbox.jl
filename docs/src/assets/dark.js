// The sites are dark: a reader who has not picked a theme in the settings gets documenter-dark, whatever the OS says.
(function () {
  try {
    if (window.localStorage.getItem("documenter-theme") === null) {
      window.localStorage.setItem("documenter-theme", "documenter-dark");
      set_theme_from_local_storage();
    }
  } catch (e) {}
})();
