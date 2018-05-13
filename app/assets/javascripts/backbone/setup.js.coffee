(->
  SetupView = Backbone.View.extend(
    el: "#setup-view"
    events:
      "click #change-restaurant-name": "changeRestaurantName"
      "click #save-restaurant-name": "saveRestaurantName"
      "click #cancel-restaurant-name": "cancelRestaurantName"

      # asp - Area Shift Position
      # the logic used there is identical
      "click [data-asp-action='asp-add']": "aspAdd"
      "click [data-asp-action='asp-create']": "aspCreate"
      "click [data-asp-action='asp-cancel-creation']": "aspCancelCreation"
      "click [data-asp-action='asp-cancel']": "aspCancel"
      "click [data-asp-action='asp-update']": "aspUpdate"
      "click [data-asp-action='asp-edit']": "aspEdit"
      "click [data-asp-action='asp-remove']": "aspRemove"
      "click [data-asp-action='asp-reactivate']": "aspReactivate"

      # Position/Shift relations
      "ifChanged [data-action-type='ps-action']": "psToggle"
      "ifChanged [data-action-type='as-action']": "asToggle"
      # "ifChecked .icheckbox_square-green": "psToggle"

    # NAME

    saveRestaurantName: ->

      restaurantName = $("#restaurant-name").val()

      if restaurantName.length <= 0
        toastr["info"]("Please fill in the restaurant name.", "Can not be blank")
      else
        $.ajax
          url: "api/restaurants/1" #TODO
          method: "put"
          id: "1"
          data:
            restaurant:
              name: restaurantName
          success: =>
            toastr["success"]("Restaurant name successfully updated", "Success")
          error: (response) =>
            $("#restaurant-name").restoreData()
            toastr["error"](response.responseText, "Error")


        $("#restaurant-name").editAndFocus(false)
        $("#save-restaurant-name, #change-restaurant-name, #cancel-restaurant-name").toggleClass("hidden")

    changeRestaurantName: ->
      $("#restaurant-name").saveData()
      $("#restaurant-name").editAndFocus(true)
      $("#save-restaurant-name, #change-restaurant-name, #cancel-restaurant-name").toggleClass("hidden")

    cancelRestaurantName: ->
      $("#restaurant-name").restoreData()
      $("#restaurant-name").editAndFocus(false)
      $("#save-restaurant-name, #change-restaurant-name, #cancel-restaurant-name").toggleClass("hidden")

    # AREA TYPES

    aspAdd: (e) ->
      @type = $(e.currentTarget).attr("data-asp-type")
      tr = $(e.currentTarget).closest("tr")

      if @type is "area-type"
        bookmark = "<i class='fa fa-bookmark' style='color: #f3f3f3;'></i>"
      else
        bookmark = ""

      areaTypesTable = $("##{ @type }s-table")
      totalAreaTypeCount = areaTypesTable.find("tr").length
      areaTypesTable.find("tbody").append(
        "
        <tr class='new-asp'>
          <td class='#{ @type }-sequence sequence'>
            " + bookmark + "
            #{ totalAreaTypeCount + 1 })
          </td>
          <td class='name-td'>
              <input class='#{ @type }-name form-control' disabled='true' placeholder='#{ @type.replace('-type', '') } name'>
          </td>
          <td class='actions'>
            <span id='#{ @type }-update' data-asp-action='asp-update' data-asp-type='#{ @type }' class='save hidden btn btn-success btn' data-#{ @type }-id=''><i class='fa fa-floppy-o'></i></span>
            <span id='#{ @type }-cancel' data-asp-action='asp-cancel' data-asp-type='#{ @type }' class='save hidden btn btn-default btn' data-#{ @type }-id=''><i class='fa fa-ban'></i></span>

            <button class='btn btn-info btn-xs' type='button' id='#{ @type }-edit' data-asp-action='asp-edit' data-asp-type='#{ @type }' class='edit' data-#{ @type }-id=''><i class='fa fa-edit'></i></button>
            <button class='btn btn-danger btn-xs' type='button' id='#{ @type }-remove' data-asp-action='asp-remove' data-asp-type='#{ @type }' class='remove' data-#{ @type }-id='' class='btn btn-danger btn'><i class='fa fa-remove'></i></button>

            <button id='#{ @type }-create' data-asp-action='asp-create' data-asp-type='#{ @type }' class='btn btn-success' type='button'><i class='fa fa-floppy-o'></i></button>
            <button id='#{ @type }-cancel-creation' data-asp-action='asp-cancel-creation' data-asp-type='#{ @type }' class='btn btn-default' type='button'><i class='fa fa-ban'></i></button>
          </td>
        </tr>
        "
      )

      areaTypesTable.find(".new-asp .#{ @type }-name").editAndFocus(true)
      $("##{ @type }-add").toggleClass("hidden")
      tr.find("##{ @type }-create, ##{ @type }-cancel-creation").toggleClass("hidden")

    aspCancelCreation: (e)->
      @type = $(e.currentTarget).attr("data-asp-type")
      areaTypesTable = $("##{ @type }s-table")
      areaTypesTable.find(".new-asp").remove()
      $("##{ @type }-add").toggleClass("hidden")
      tr = $(e.currentTarget).closest("tr")
      tr.find("##{ @type }-add, ##{ @type }-create, ##{ @type }-cancel-creation").toggleClass("hidden")

    aspCancel: (e)->
      @type = $(e.currentTarget).attr("data-asp-type")
      tr = $(e.currentTarget).closest("tr")
      tr.find("##{ @type }-edit, ##{ @type }-update, ##{ @type }-remove, ##{ @type }-cancel").toggleClass("hidden")
      tr.find(".#{ @type }-name").restoreData().editAndFocus(false)

    aspCreate: (e)->
      @type = $(e.currentTarget).attr("data-asp-type")
      tr = $(e.currentTarget).closest("tr")

      areaTypesTable = $("##{ @type }s-table")
      areaTypesTable.find(".new-asp")

      $.ajax
        url: "api/#{ @urlByType(@type) }s"
        method: "post"
        data:
          "#{ @urlByType(@type) }":
            name: areaTypesTable.find(".new-asp .#{ @type }-name").val().toLowerCase()
        success: (e) =>
          id = e[@urlByType(@type)]["id"]
          color = e[@urlByType(@type)]["chart_color"]
          tr.find(".sequence i").css({color: color})
          tr.removeClass("new-asp").attr("data-#{ @type }-id", id)
          tr.find("[data-#{ @type }-id]").attr("data-#{ @type }-id", id)
          tr.find(".#{ @type }-name").editAndFocus(false)
          tr.find("##{ @type }-create, ##{ @type }-cancel-creation").toggleClass("hidden")
          tr.attr("data-asp-status", "active")

          $("##{ @type }-add").toggleClass("hidden")

          # TODO update schedule table
          @updateScheduleHtml()
          @updateWorkloadHtml()

          toastr["success"]("#{ @modelNameByType(@type) } successfully added", "Success")
        error: (response) ->
          toastr["error"](response.responseText, "Error")

    aspRemove: (e) ->
      @type = $(e.currentTarget).attr("data-asp-type")

      id = $(e.currentTarget).attr("data-#{ @type }-id")
      Tipcalc.Controllers.spinner.show()
      $.ajax
        url: "api/#{ @urlByType(@type) }s/#{ id }"
        method: "delete"
        success: (response) =>
          if response.persisted is true
            toastr["success"]("#{ @modelNameByType(@type) } is successfully deactivated", "Success")
            $("tr[data-#{ @type }-id=#{ id }]").attr("data-asp-status", "deactivated")
          else
            toastr["success"]("#{ @modelNameByType(@type) } is successfully removed", "Success")
            $("tr[data-#{ @type }-id=#{ id }]").remove()

          @updateScheduleHtml()
          @updateWorkloadHtml()
          Tipcalc.Controllers.spinner.hide()
        error: (response) ->
          toastr["error"](response.responseText, "Error")
          Tipcalc.Controllers.spinner.hide()

    aspReactivate: (e) ->
      @type = $(e.currentTarget).attr("data-asp-type")

      id = $(e.currentTarget).attr("data-#{ @type }-id")
      $.ajax
        url: "api/#{ @urlByType(@type) }s/#{ id }/reactivate"
        method: "patch"
        success: =>
          toastr["success"]("#{ @modelNameByType(@type) } is successfully activated", "Success")
          $("tr[data-#{ @type }-id=#{ id }]").attr("data-asp-status", "active")
          @updateScheduleHtml()
          @updateWorkloadHtml()
        error: (response) ->
          toastr["error"](response.responseText, "Error")

    aspEdit: (e) ->
      @type = $(e.currentTarget).attr("data-asp-type")
      id = $(e.currentTarget).attr("data-#{ @type }-id")

      $("tr[data-#{ @type }-id=#{ id }]").find("##{ @type }-edit, ##{ @type }-update, ##{ @type }-remove, ##{ @type }-cancel").toggleClass("hidden")
      $("tr[data-#{ @type }-id=#{ id }]").find(".#{ @type }-name").saveData().editAndFocus(true)

    aspUpdate: (e) ->
      @type = $(e.currentTarget).attr("data-asp-type")
      id = $(e.currentTarget).attr("data-#{ @type }-id")

      $.ajax
        url: "api/#{ @urlByType(@type) }s/#{ id }"
        method: "patch"
        data:
          "#{ @urlByType(@type) }":
            name: $("tr[data-#{ @type }-id=#{ id }]").find(".#{ @type }-name").val()
        success: =>
          toastr["success"]("#{ @modelNameByType(@type) } successfully updated", "Success")
          $("tr[data-#{ @type }-id=#{ id }]").find("##{ @type }-edit, ##{ @type }-update, ##{ @type }-remove, ##{ @type }-cancel").toggleClass("hidden")
          $("tr[data-#{ @type }-id=#{ id }]").find(".#{ @type }-name").clearCashedData().editAndFocus(false)

          # TODO update schedulse table
          @updateScheduleHtml()
          @updateWorkloadHtml()
        error: (response) ->
          toastr["error"](response.responseText, "Error")

      # $("tr[data-area-type-id=#{ id }]").find(".area-type-name").editAndFocus(true)

    urlByType: (type) ->
      return type.replace(/-/g, "_")

    modelNameByType: (type) ->
      name = type.replace(/-type/, "")
      nameCapitilized = name.replace(/\b\w/g, (l) => l.toUpperCase())
      return nameCapitilized

    # SCHEDULE

    updateScheduleHtml: ->
      $.ajax
        url: "/api/setup/schedule_html"
        method: "get"
        success: (e) ->
          $("#schedule-wrapper").html(e)
          window.bindCheckboxes()
        error: (response) ->
          toastr["error"](response.responseText, "Error")

    psToggle: (e) ->
      $.ajax
        url: "/api/setup/update_ps_relation"
        method: "patch"
        data:
          checked: e.currentTarget.checked
          shift_type_id: $(e.currentTarget).attr("data-shift-type")
          position_type_id: $(e.currentTarget).attr("data-position-type")
          area_type_id: $(e.currentTarget).attr("data-area-type")
        success: ->
        error: (response) ->
          toastr["error"](response.responseText, "Error")

    # WORKLOAD

    updateWorkloadHtml: ->
      $.ajax
        url: "/api/setup/workload_html"
        method: "get"
        success: (e) ->
          $("#workload-wrapper").html(e)
          window.bindCheckboxes()
        error: (response) ->
          toastr["error"](response.responseText, "Error")

    asToggle: (e) ->
      $.ajax
        url: "/api/setup/update_as_relation"
        method: "patch"
        data:
          checked: e.currentTarget.checked
          day: $(e.currentTarget).attr("data-as-day")
          shift_type_id: $(e.currentTarget).attr("data-as-shift-type-id")
          area_type_id: $(e.currentTarget).attr("data-as-area-type-id")
        success: ->
        error: (response) ->
          toastr["error"](response.responseText, "Error")

  )

  $(document).ready ->
    if $("body").hasClass("setup")
      Tipcalc.Controllers.setupView = new SetupView()
)()
