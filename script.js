const year = document.getElementById("year");
const backBtn = document.getElementById("back-to-top");
const sidebarLinks = document.querySelectorAll(".sidebar a[href^='#']");
const sections = [...sidebarLinks]
  .map((a) => document.querySelector(a.getAttribute("href")))
  .filter(Boolean);

if (year) year.textContent = String(new Date().getFullYear());

backBtn?.addEventListener("click", () => {
  window.scrollTo({ top: 0, behavior: "smooth" });
});

window.addEventListener(
  "scroll",
  () => {
    backBtn?.classList.toggle("show", window.scrollY > 400);

    let current = sections[0];
    for (const section of sections) {
      if (section.getBoundingClientRect().top <= 120) current = section;
    }
    sidebarLinks.forEach((link) => {
      const active = link.getAttribute("href") === `#${current.id}`;
      link.classList.toggle("active", active);
    });
  },
  { passive: true }
);

sidebarLinks.forEach((link) => {
  link.addEventListener("click", () => {
    sidebarLinks.forEach((l) => l.classList.remove("active"));
    link.classList.add("active");
  });
});
