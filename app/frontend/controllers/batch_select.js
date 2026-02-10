(function () {
  function init() {
    const selectAll = document.querySelector("[data-batch-select-all]");
    const bar = document.querySelector("[data-batch-bar]");
    const countLabel = document.querySelector("[data-batch-count]");
    const deselectBtn = document.querySelector("[data-batch-deselect]");

    if (!bar) return;

    function getCheckboxes() {
      return document.querySelectorAll("[data-batch-select-item]");
    }

    function updateBar() {
      const checkboxes = getCheckboxes();
      const checked = Array.from(checkboxes).filter((cb) => cb.checked);
      const count = checked.length;

      if (count > 0) {
        bar.style.display = "block";
        countLabel.textContent =
          count + (count === 1 ? " file selected" : " files selected");
      } else {
        bar.style.display = "none";
      }

      // Sync "select all" checkbox
      if (selectAll) {
        selectAll.checked =
          checkboxes.length > 0 && checked.length === checkboxes.length;
        selectAll.indeterminate =
          checked.length > 0 && checked.length < checkboxes.length;
      }
    }

    // Listen for individual checkbox changes
    document.addEventListener("change", (e) => {
      if (e.target.matches("[data-batch-select-item]")) {
        updateBar();
      }
    });

    // Select all / deselect all toggle
    if (selectAll) {
      selectAll.addEventListener("change", () => {
        const checkboxes = getCheckboxes();
        checkboxes.forEach((cb) => {
          cb.checked = selectAll.checked;
        });
        updateBar();
      });
    }

    // Deselect all button in the bar
    if (deselectBtn) {
      deselectBtn.addEventListener("click", () => {
        const checkboxes = getCheckboxes();
        checkboxes.forEach((cb) => {
          cb.checked = false;
        });
        if (selectAll) selectAll.checked = false;
        updateBar();
      });
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }

  document.addEventListener("turbo:load", init);
})();
