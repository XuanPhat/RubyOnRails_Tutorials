function Product(options) {
  var module = this;
  var defaults = {
    template: {
      product: $("#list-product-template"),
      search: $("#list-search-template"),
    },
    api: {
      product: "/api/v1/product",
      search: "/api/v1/search",
      delete_order: "/api/v1/delete_order",
      api_token: Cookies.get("api_token"),
    },
    data: {},
  };
  module.settings = $.extend({}, defaults, options);
  module.searchProduct = function () {
    $(".in-search").keypress(function (e) {
      if (event.keyCode == 13) {
        search = $(this).val();
        $.ajax({
          url: module.settings.api.search,
          headers: {
            Authorization: "Bearer " + module.settings.api.api_token, //z9SNcLnCMHJUXdtzU0VBeQ
          },
          type: "POST",
          data: { token: module.settings.api.api_token, search },
          dataType: "json",
          success: function (data) {
            if (data.code == 200) {
              $(".padding-right").html("");
              $("#cart_items").html("");
              $("#do_action").html("");
              var template_search = Handlebars.compile(
                module.settings.template.search.html()
              );
              $(".padding-right").append(
                template_search({
                  products: data.data.products,
                })
              );
              $("#cart_items").append(
                template_search({
                  products: data.data.products,
                })
              );
            } else {
              console.log("error");
            }
          },
          error: function () {},
        });
      }
    });
  };

  module.Productofmonth = function () {
    $("#submit").on("click", function () {
      var date = new Date($("#start").val());
      var month = date.getMonth() + 1;
      var year = date.getFullYear();
      $.ajax({
        url: module.settings.api.product,
        headers: {
          Authorization: "Bearer " + module.settings.api.api_token, //z9SNcLnCMHJUXdtzU0VBeQ
        },
        type: "POST",
        data: { token: module.settings.api.api_token, month, year },
        dataType: "json",
        success: function (data) {
          if (data.code == 200) {
            $(".tbody").html("");
            var template_product = Handlebars.compile(
              module.settings.template.product.html()
            );
            $(".tbody").append(
              template_product({
                product_of_month: data.data.product_of_month,
                carts_order: data.data.carts_order,
              })
            );
          } else {
            console.log("error");
          }
        },
        error: function () {},
      });
    });
  };

  module.CancelOrder = function () {
    $(".submit_delete")
      .off()
      .on("click", function () {
        product_id = $(this).attr("product_id");
        order_id = $(this).attr("order_id");
        $.ajax({
          url: module.settings.api.delete_order,
          headers: {
            Authorization: "Bearer " + module.settings.api.api_token, //z9SNcLnCMHJUXdtzU0VBeQ
          },
          type: "POST",
          data: { token: module.settings.api.api_token, product_id, order_id },
          dataType: "json",
          success: function (data) {
            if (data.code == 200) {
              window.location = "/users/orders";
            } else {
              console.log("error");
            }
          },
          error: function () {},
        });
      });
  };

  module.init = function () {
    module.searchProduct();
    module.Productofmonth();
    module.CancelOrder();
  };
}

$(document).ready(function () {
  product = new Product();
  product.init();
});
