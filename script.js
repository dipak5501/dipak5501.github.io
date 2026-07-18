const nav = document.querySelector(".nav");
const toggle = document.querySelector(".nav-toggle");
const panel = document.querySelector(".nav-links");
const year = document.getElementById("year");
const links = document.querySelectorAll('.nav-links a[href^="#"]');
const sections = document.querySelectorAll("section[id]");

if (year) year.textContent = String(new Date().getFullYear());

function setMenu(open) {
  panel?.classList.toggle("is-open", open);
  toggle?.setAttribute("aria-expanded", open ? "true" : "false");
  toggle?.setAttribute("aria-label", open ? "Close menu" : "Open menu");
  document.body.style.overflow = open ? "hidden" : "";
}

toggle?.addEventListener("click", () => {
  setMenu(toggle.getAttribute("aria-expanded") !== "true");
});

panel?.querySelectorAll("a").forEach((a) => {
  a.addEventListener("click", () => setMenu(false));
});

window.addEventListener(
  "scroll",
  () => {
    nav?.classList.toggle("is-solid", window.scrollY > 48);
  },
  { passive: true }
);

const revealIo = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (!entry.isIntersecting) return;
      entry.target.classList.add("is-in");
      revealIo.unobserve(entry.target);
    });
  },
  { threshold: 0.12, rootMargin: "0px 0px -8% 0px" }
);

document.querySelectorAll(".reveal").forEach((el, i) => {
  el.style.transitionDelay = `${Math.min(i % 4, 3) * 0.08}s`;
  revealIo.observe(el);
});

const sectionIo = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (!entry.isIntersecting) return;
      const id = entry.target.id;
      links.forEach((link) => {
        link.classList.toggle("is-active", link.getAttribute("href") === `#${id}`);
      });
    });
  },
  { rootMargin: "-40% 0px -50% 0px", threshold: 0 }
);

sections.forEach((s) => sectionIo.observe(s));

/* Smooth magnetic feel on primary button */
document.querySelectorAll(".btn-primary").forEach((btn) => {
  btn.addEventListener("pointermove", (e) => {
    const r = btn.getBoundingClientRect();
    const x = e.clientX - r.left - r.width / 2;
    const y = e.clientY - r.top - r.height / 2;
    btn.style.transform = `translate(${x * 0.12}px, ${y * 0.18 - 2}px)`;
  });
  btn.addEventListener("pointerleave", () => {
    btn.style.transform = "";
  });
});
