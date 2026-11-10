const year = document.getElementById("year");
const backBtn = document.getElementById("back-to-top");
const sidebar = document.getElementById("sidebar");
const menuToggle = document.getElementById("menu-toggle");
const backdrop = document.getElementById("backdrop");
const sidebarLinks = document.querySelectorAll(".sidebar a");
const hashLinks = [...sidebarLinks].filter((a) =>
  (a.getAttribute("href") || "").startsWith("#")
);
const sections = hashLinks
  .map((a) => document.querySelector(a.getAttribute("href")))
  .filter(Boolean);

if (year) year.textContent = String(new Date().getFullYear());

/** Apply live thesis tunnel URL from thesis-url.json (single source of truth). */
async function applyThesisLiveUrl() {
  const links = document.querySelectorAll("[data-thesis-live]");
  if (!links.length) return;
  try {
    const res = await fetch(`thesis-url.json?v=${Date.now()}`, { cache: "no-store" });
    if (!res.ok) return;
    const data = await res.json();
    const ui = (data.ui || "").trim().replace(/\/$/, "");
    if (!ui) return;
    links.forEach((a) => {
      a.setAttribute("href", ui);
      a.title = data.updated ? `Live thesis UI · updated ${data.updated}` : "Live thesis UI";
    });
  } catch {
    /* keep href fallback baked into HTML */
  }
}
applyThesisLiveUrl();

function setMenuOpen(open) {
  sidebar?.classList.toggle("open", open);
  backdrop?.classList.toggle("show", open);
  if (backdrop) backdrop.hidden = !open;
  if (menuToggle) {
    menuToggle.setAttribute("aria-expanded", open ? "true" : "false");
    menuToggle.setAttribute("aria-label", open ? "Close navigation" : "Open navigation");
    const icon = menuToggle.querySelector("i");
    if (icon) icon.className = open ? "fas fa-times" : "fas fa-bars";
  }
  document.body.style.overflow = open ? "hidden" : "";
}

menuToggle?.addEventListener("click", () => {
  setMenuOpen(!sidebar?.classList.contains("open"));
});

backdrop?.addEventListener("click", () => setMenuOpen(false));

sidebarLinks.forEach((link) => {
  link.addEventListener("click", () => {
    if (window.matchMedia("(max-width: 820px)").matches) setMenuOpen(false);
  });
});

backBtn?.addEventListener("click", () => {
  window.scrollTo({ top: 0, behavior: "smooth" });
});

window.addEventListener(
  "scroll",
  () => {
    backBtn?.classList.toggle("show", window.scrollY > 400);

    if (!sections.length) return;
    let current = sections[0];
    for (const section of sections) {
      if (section.getBoundingClientRect().top <= 120) current = section;
    }
    hashLinks.forEach((link) => {
      const active = link.getAttribute("href") === `#${current.id}`;
      link.classList.toggle("active", active);
    });
  },
  { passive: true }
);

hashLinks.forEach((link) => {
  link.addEventListener("click", () => {
    hashLinks.forEach((l) => l.classList.remove("active"));
    link.classList.add("active");
  });
});

const revealEls = document.querySelectorAll(".reveal");
if ("IntersectionObserver" in window) {
  const io = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add("in");
          io.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.12, rootMargin: "0px 0px -8% 0px" }
  );
  revealEls.forEach((el) => io.observe(el));
} else {
  revealEls.forEach((el) => el.classList.add("in"));
}

window.addEventListener("keydown", (e) => {
  if (e.key === "Escape") setMenuOpen(false);
});
