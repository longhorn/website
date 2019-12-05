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

const drawerToggle = () => {
  const toggle = $('#drawer-toggle'),
    drawer = $('#drawer'),
    canvas = $('#canvas'),
    close = $('#drawer-close');

  toggle.click(() => {
    canvas.addClass('is-dark');
    drawer.toggleClass('is-visible');

    close.click(() => {
      drawer.removeClass('is-visible');
      canvas.removeClass('is-dark');
    });
  });
}

$(() => {
  navbarBurgerExpand();
  dropdownMenuExpand();
  drawerToggle();
});
