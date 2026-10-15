const nav = document.querySelector(".nav");
const toggle = document.querySelector(".nav-toggle");
const links = document.querySelector(".nav-links");
const year = document.getElementById("year");
const navAnchors = document.querySelectorAll('.nav-links a[href^="#"]');
const sections = document.querySelectorAll("section[id]");

if (year) year.textContent = String(new Date().getFullYear());

function setMenu(open) {
  links?.classList.toggle("is-open", open);
  toggle?.setAttribute("aria-expanded", open ? "true" : "false");
  toggle?.setAttribute("aria-label", open ? "Close menu" : "Open menu");
  document.body.style.overflow = open ? "hidden" : "";
}

toggle?.addEventListener("click", () => {
  setMenu(toggle.getAttribute("aria-expanded") !== "true");
});

links?.querySelectorAll("a").forEach((a) => {
  a.addEventListener("click", () => setMenu(false));
});

window.addEventListener(
  "scroll",
  () => {
    nav?.classList.toggle("is-solid", window.scrollY > 20);
  },
  { passive: true }
);

const revealIo = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (!entry.isIntersecting) return;
      entry.target.classList.add("in");
      revealIo.unobserve(entry.target);
    });
  },
  { threshold: 0.12, rootMargin: "0px 0px -6% 0px" }
);

document.querySelectorAll(".reveal").forEach((el, i) => {
  el.style.transitionDelay = `${Math.min(i % 5, 4) * 0.06}s`;
  revealIo.observe(el);
});

const sectionIo = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (!entry.isIntersecting) return;
      const id = entry.target.id;
      navAnchors.forEach((link) => {
        link.classList.toggle("is-active", link.getAttribute("href") === `#${id}`);
      });
    });
  },
  { rootMargin: "-40% 0px -50% 0px", threshold: 0 }
);

sections.forEach((s) => sectionIo.observe(s));

/* Nested GitHub link inside LocalPulse featured card */
document.querySelectorAll(".link-inline[data-href]").forEach((el) => {
  el.addEventListener("click", (e) => {
    e.preventDefault();
    e.stopPropagation();
    window.open(el.getAttribute("data-href"), "_blank", "noopener,noreferrer");
  });
});

/* Subtle magnetic primary button */
document.querySelectorAll(".btn-primary").forEach((btn) => {
  btn.addEventListener("pointermove", (e) => {
    const r = btn.getBoundingClientRect();
    const x = e.clientX - r.left - r.width / 2;
    const y = e.clientY - r.top - r.height / 2;
    btn.style.transform = `translate(${x * 0.1}px, ${y * 0.15 - 2}px)`;
  });
  btn.addEventListener("pointerleave", () => {
    btn.style.transform = "";
  });
});
