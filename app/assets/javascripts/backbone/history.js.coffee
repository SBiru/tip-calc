(->
  HistoryView = Backbone.View.extend(
    el: "body.history"
    events:
      "click .duplicate-start": "duplicateStart"
      "click .duplicate-init": "duplicateInit"
      "click .destroy-calculation": "destroyCalculation"
      "click .show-calculation": -> Tipcalc.Controllers.spinner.show()
      "click [data-day-calculation-locked] .lock-icon": "toggleLock"

    toggleLock: (e) ->
      dayBlock = $(e.currentTarget).closest("[data-day-calculation-locked]")

      toggleRequest = =>
        $.ajax
          url: "/api/day_calculations/#{ dayBlock.attr('data-day-calculation-id') }"
          method: "patch"
          data:
            day_calculation:
              locked: dayBlock.attr("data-day-calculation-locked") is "true"
          success: (response) ->
            dayBlock.attr("data-day-calculation-locked", response.day_calculation_locked)
            if response.day_calculation_locked
              status = 'locked'
            else
              status = 'unlocked'
            toastr["success"]("Day successfully #{ status }", "Success")
          error: (response) ->
            toastr["error"]("Day is not locked", "Error")

      if dayBlock.attr('data-day-calculation-locked') is 'true'
        swal(
          title: "",
          text: "Are you sure you want to unlock this day?",
          type: "info",
          confirmButtonColor: "#28C256",
          confirmButtonText: "Unlock",
          showCancelButton: true,
          cancelButtonText: "Cancel"

        , (isToggleLock) =>
          if isToggleLock
            toggleRequest()
        )
      else
        toggleRequest()

    duplicateInit: (e) ->
      e.preventDefault()
      $(".duplicate-start").attr("data-calculation-id", $(e.currentTarget).attr("data-calculation-id") )

    duplicateStart: (e) ->
      originalId = $(e.currentTarget).attr("data-calculation-id")
      positionTypeIds = $("#source_positions").val()

      $.ajax
        url: "api/calculations/duplicate"
        method: "get"
        data:
          originalId: originalId
          positionTypeIds: positionTypeIds
        success: (e) ->
          console.log e.duplicated_calculation_id
          toastr["success"]("Calculation successfully duplicated. Redirecting...", "Success")

          window.location.href = "/show_calculation_get?calculation_id=#{ e.duplicated_calculation_id }"
        error: (e) ->
          toastr["error"]("Calculation is not duplicated.", "Error")

    destroyCalculation: (e) ->
      e.preventDefault()
      calculationId = $(e.currentTarget).attr("data-calculation-id")
      tr = $(e.currentTarget).closest("tr")

      swal(
        title: "",
        text: "Are you sure you want to destroy the calculation?",
        type: "warning",
        confirmButtonColor: "#DD6B55",
        confirmButtonText: "Delete",
        showCancelButton: true,
        cancelButtonText: "Cancel"
      , (isDelete) =>
        if isDelete
          $.ajax
            url: "/api/calculations/#{ calculationId }"
            method: "delete"
            success: (e) ->
              toastr["success"]("Calculation successfully removed.", "Success")
              tr.remove()
            error: (e) ->
              toastr["error"]("Calculation is not removed.", "Error")
      )
  )

  $(document).ready ->
    if $("body").hasClass("history")
      Tipcalc.Controllers.historyView = new HistoryView()
)()