(->
  HeaderView = Backbone.View.extend(
    el: "#header"

    events:
      "click .toggle-timezone-select": "toggleTimezoneSelect"
      "click .save-timezone": "saveTimezone"

    toggleTimezoneSelect: (e) ->
      e.preventDefault() if e
      $(".select-timezone").toggleClass("is-visible")

    saveTimezone: (e) ->
      tz = $("#main_timezone").val()

      $.ajax
        url: "api/restaurants/1"
        method: "put"
        id: "1"
        data:
          restaurant:
            timezone: tz
        success: (response) =>
          toastr["success"]("Restaurant name successfully updated", "Success")
          $(".toggle-timezone-select .date").text(response.restaurant.current_date)
          $(".toggle-timezone-select .timezone").text(tz)
          @toggleTimezoneSelect()
        error: ->
          toastr["error"]("Something went wrong.", "Error")
  )

  $(document).ready ->
    Tipcalc.Controllers.headerView = new HeaderView()
)()