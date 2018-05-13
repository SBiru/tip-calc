(->
  TipOutView = Backbone.View.extend(
    el: "#tip-out"
    events:
      "keyup [data-recalculate='true']": -> @scope.updateTotalNumbers()
      "change [data-recalculate='true']": -> @scope.updateTotalNumbers()
      "keyup [data-recalculate-total-numbers='true']": -> @scope.updateTotalNumbers()
      "change [data-recalculate-total-numbers='true']": -> @scope.updateTotalNumbers()
      "change select#area_type_id": "updateAreaSelects"
      "change select#shift_type_id": "updateTipOutShift"
      "click [data-action='add-area']": "addTipout"
      "click [data-action='edit-tip-outs']": "editTipouts"
      "click [data-action='edit-tip-outs-cancel']": "editTipouts"
      "click [data-action='remove-tip-out-distribution']": "removeTipOutDistribution"
      # "click [data-action='save-tip-outs']": "saveTipOuts"

    initialize: (options) ->
      @scope = options.scope
      @updateAreaSelects()

    updateTipOutArea: (e) ->
      _.each $("#given-tipouts-table .tip-out-line #area_type_id"), (select) ->
        val = $(select).val()
        areaName = $(select).closest("tr").find("option[value='#{ val }']").text()
        tr = $(select).closest("tr").attr("data-area-name", areaName)

    updateTipOutShift: (e) ->
      _.each $("#given-tipouts-table .tip-out-line #shift_type_id"), (select) ->
        val = $(select).val()
        shiftName = $(select).closest("tr").find("option[value='#{ val }']").text()
        tr = $(select).closest("tr").attr("data-shift-type-name", shiftName)

    updateAreaSelects: (e) ->
      allValues = gon.areas

      usedValues = _.map $("#given-tipouts-table .tip-out-line #area_type_id"), (e) -> 
        $(e).val()

      freeItems = _.filter gon.areas, (item) ->
        !_.contains(usedValues, item.id)

      optionsHtmlArray = (_.map freeItems, (item) ->
        "<option value='#{ item.id }'>#{ item.name }</option>"
      ).join()

      _.each $("#given-tipouts-table .tip-out-line #area_type_id"), (select) ->
        id = $(select).val()
        name = $(select).find("option[value='#{id}']").text()
        finalHtml = [
          optionsHtmlArray,
          "<option value='#{ id }' selected='selected'>#{ name }</option>"
        ].join()

        $(select).html(finalHtml)

      @updateTipOutArea(e)

    editTipouts: ->
      $(@el).find(".actions").toggleClass("hidden")
      $(@el).find("[data-action='edit-tip-outs-cancel']").toggleClass("hidden")
      $(@el).find("[data-action='edit-tip-outs']").toggleClass("hidden")

    syncTipOutsWithData: (data) ->
      _.each $("#given-tipouts-table .tip-out-line[data-tip-out-status='new']"), (line) =>
        areaId = $(line).find("select#area_type_id").val()
        if gon.restaurant.shifted_tip_outs_enabled
          shiftTypeId = $(line).find("select#shift_type_id").val()
          options = {
            area_type_id: areaId,
            shift_type_id: shiftTypeId
          }
        else
          options = {
            area_type_id: areaId
          }

        tipOutData = _.findWhere(data, options)

        $(line).attr("data-tip-out-status", "persisted")
        $(line).attr("data-tip-out-id", tipOutData.id)

    removeTipOutDistribution: (e) ->
      tr = $(e.currentTarget).closest("tr")
      table = $(e.currentTarget).closest("table")

      if tr.attr("data-tip-out-status") is "new"
        tr.remove()
        @scope.calculate()
        @updateAreaSelects()
      else if tr.attr("data-tip-out-status") is "persisted"
        $.ajax
          url: "/api/tip_outs/" + tr.attr("data-tip-out-id")
          method: "delete"
          data:
            calculation_id: gon.calculation_id
          success: (e) =>
            toastr["success"]("Tip out removed", "Success")
            tr.remove()
            @scope.calculate()
            @updateAreaSelects()
          error: (e) =>
            toastr["error"]("Tip out was not removed", "Error")

    addTipout: (e) ->
      allValues = gon.areas

      usedValues = _.map $("#given-tipouts-table .tip-out-line #area_type_id"), (e) -> 
        $(e).val()

      freeItems = _.filter gon.areas, (item) ->
        !_.contains(usedValues, item.id)

      if freeItems.length is 0
        toastr["error"]("There are no areas for making tip out.", "Error")
      else
        table = $("table#given-tipouts-table")

        areaOptionsHtmlArray = (_.map freeItems, (item) ->
          "<option value='#{ item.id }'>#{ item.name }</option>"
        ).join()

        
        shiftOptionsHtmlArray = (_.map gon.shifts, (item) ->
          if gon.calculation_params.shift_type_id is item.id
            htmline = "<option value='#{ item.id }' selected='selected'>#{ item.name }</option>"
          else
            htmline = "<option value='#{ item.id }'>#{ item.name }</option>"
          htmline
        ).join()

        if gon.restaurant.shifted_tip_outs_enabled
          shifted_tipout_part = "
            <td class='shift-type-select-wrapper'>
              <select id='shift_type_id' class='select-2 shift-type-id' style='width: 100%' >
                  " + shiftOptionsHtmlArray + "
              </select>
            </td>
          "
        else
          shifted_tipout_part = ""

        tr_example = "
          <tr class='tip-out-line' data-area-name='' data-shift-type-name='' data-tip-out-status='new'>
            <td class='area-type-select-wrapper'>
              <select id='area_type_id' class='select-2 area-id' style='width: 100%' >
                  " + areaOptionsHtmlArray + "
              </select>
              <span class='actions hidden'>
                <span class='btn btn-danger btn-sm' type='button' data-action='remove-tip-out-distribution'><i class='fa fa-minus-circle'></i></span>
              </span>
            </td>" + shifted_tipout_part + "
            <td><input class='touch-spin tip-out-percentage' type='text'  name='touch-spin' value='0' data-recalculate='true' data-recalculate-total-numbers='true'></td>
            <td class='active cc_summ'>-
            </td>
            <td class='active cash_summ'>-</td>
          </tr>
        "

        $(table).find("tbody tr.total").before(tr_example)

        window.bindSelect2();
        window.bindPercentSelect();
        @updateAreaSelects(e)
        @updateTipOutShift()

    # saveTipOuts: (e) ->
    #   table = $("#given-tipouts-table")
    #   data = {}
    #   for tr in table.find(".tip-out-line")
    #     data[$(tr).attr("data-area-name")] = {
    #       calculation_id: gon.calculation_id,
    #       area_type_id: $(tr).find(".area-id").val(),
    #       percentage: $(tr).find(".tip-out-percentage").val(),
    #     }

    #   $.ajax
    #     url: "/api/tip_outs/update_tip_outs"
    #     method: "patch"
    #     data:
    #       calculation_id: gon.calculation_id
    #       tip_outs: data
    #     success: () ->
    #       toastr["success"]("Tip outs successfully added", "Success")
    #     error: () ->
    #       toastr["error"]("Tip outs had some errors", "Error")
  )

  Tipcalc.Controllers.TipOutViewPrototype = TipOutView

)()
