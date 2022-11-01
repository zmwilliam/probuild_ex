// tailwind ui mobile nav
const $toggleMenu = document.getElementById("toggle-menu")
const $burger = document.getElementById("burger")
const $xMark = document.getElementById("x-mark")
const $mobileMenu = document.getElementById("mobile-menu")

$toggleMenu.addEventListener("click", event => {
  event.preventDefault();
  ["hidden", "block"].forEach(className => {
    $burger.classList.toggle(className)
    $xMark.classList.toggle(className)
  })
  $mobileMenu.classList.toggle("hidden")
})

