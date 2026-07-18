const menuBtn = document.querySelector(".menu-btn");
const drawer = document.querySelector(".drawer");
const year = document.getElementById("year");

if (year) year.textContent = String(new Date().getFullYear());

function setMenu(open) {
  drawer?.classList.toggle("is-open", open);
  menuBtn?.setAttribute("aria-expanded", open ? "true" : "false");
}

menuBtn?.addEventListener("click", () => {
  setMenu(menuBtn.getAttribute("aria-expanded") !== "true");
});

drawer?.querySelectorAll("a").forEach((a) => {
  a.addEventListener("click", () => setMenu(false));
});

document.querySelectorAll(".tile, .job, .paper, .stats > div, .profile-card").forEach((el) => {
  el.classList.add("reveal");
});

const io = new IntersectionObserver(
  (entries) => {
    entries.forEach((e) => {
      if (e.isIntersecting) {
        e.target.classList.add("in");
        io.unobserve(e.target);
      }
    });
  },
  { threshold: 0.1 }
);

document.querySelectorAll(".reveal").forEach((el) => io.observe(el));
