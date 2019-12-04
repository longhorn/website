const burger = $('.navbar-burger'),
  navbarMenu = $('.navbar-menu'),
  dropdownTrigger = $('#dropdown-trigger'),
  dropdown = $('#dropdown');

const navbarBurgerExpand = () => {
  burger.click((e) => {
    [burger, navbarMenu].forEach((el) => {
      el.toggleClass('is-active')
    });
  });
}

const dropdownMenuExpand = () => {
  dropdownTrigger.click(() => {
    dropdown.toggleClass('is-active');
  });
}

$(() => {
  navbarBurgerExpand();
  dropdownMenuExpand();
});
