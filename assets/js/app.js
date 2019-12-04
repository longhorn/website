const burger = $('.navbar-burger'),
  navbarMenu = $('.navbar-menu');

const navbarBurgerExpand = () => {
  burger.click((e) => {
    [burger, navbarMenu].forEach((el) => {
      el.toggleClass('is-active')
    });
  });
}

$(() => {
  navbarBurgerExpand();
});
