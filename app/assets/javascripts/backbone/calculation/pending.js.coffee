(->
  CalculationPendingView = Backbone.View.extend(
    el: "body.calculation"
    events:
      "click [data-pending-action]": "pendingAction"

    pendingAction: (e) ->
      e.preventDefault()

      if @isTeamsQuantityUpdateRequired(e)
        tr = $(e.currentTarget).closest("tr")
        team_number = tr.find(".team_number").text()
        Tipcalc.Controllers.calculationFormView.changeTeamQuantityTo({
          teamNumber: team_number
        })
      
      if @isAdditionalSourceUpdateRequired(e)
        tr = $(e.currentTarget).closest("tr")
        position_type_id = tr.attr("data-position-type-id")
        Tipcalc.Controllers.calculationFormView.addSourcePositionById({
          id: position_type_id
        })

      Tipcalc.Controllers.calculationView.distributionsView.addMissingTables()

      params = {
        updateCalculationRequired: true,
        afterUpdateCallback: {
          action: Tipcalc.Controllers.calculationPendingView.pendingActionRequest,
          event: e
        }
      }

      Tipcalc.Controllers.calculationView.checkCalculationExistance(params)

    pendingActionRequest: (e) ->
      tr = $(e.currentTarget).closest("tr")

      approval_action = $(e.currentTarget).attr("data-pending-action")
      id = $(e.currentTarget).attr("data-employee-distribution-id")

      $.ajax
        url: "api/employee_distributions/check_approval_status"
        method: "patch"
        data:
          approval_action: approval_action
          id: id
          calculation_id: gon.calculation_id
        success: (response) =>
          response = response.employee_distribution

          if response.persisted == false
            tr.remove()
            Tipcalc.Controllers.calculationPendingView.checkPendingBlock()
            Tipcalc.Controllers.calculationPendingView.bindActions()
            toastr["success"]("Distribution successfully removed", "Removed")
          else
            table = $("table[data-position-table=\"#{ response.position_type_name }\"][data-team='#{ response.team_number }']")

            existedEmployeeIds = _.map(table.find("select.employee-id"), (e) -> return $(e).val() )
            employeeListForPosition = ""
            for emp in gon.related_employees[response.position_type_name].employees
              unless _.contains(existedEmployeeIds, emp.id)
                employeeListForPosition += "<option value='#{ emp.id }'>#{ emp.name }</option>"

            if $(table).attr("data-position-is-a-source") is "false" || $(table).attr("data-team-count") is "1"
              team_td = ""
            else
              team_td = "<td>" + response.team_number + "</td>"

            moneyInFields = "
              <td class='notactive sales-summ source-only-fields sales-cell'>
                  <div class='input-group m-b'><span class='input-group-addon'>$</span> <input type='text' placeholder='Sales' class='form-control' value='#{ parseFloat(response.sales_summ).toFixed(2) }' data-recalculate='true'></div>
              </td>
              <td class='notactive source-only-fields cc-in'>
                  <div class='input-group m-b'><span class='input-group-addon'>$</span> <input type='text' placeholder='CC tips' class='form-control' value='#{ parseFloat(response.cc_tips).toFixed(2) }' data-recalculate='true'></div>
              </td>
              <td class='notactive source-only-fields cash-in'>
                  <div class='input-group m-b'><span class='input-group-addon'>$</span> <input type='text' placeholder='Cash tips' class='form-control' value='#{ parseFloat(response.cash_tips).toFixed(2) }' data-recalculate='true'></div>
              </td>
            "

            tr_line = "
              <tr class='employee-distribution-line' data-emp-distribution-status='persisted' data-employee-id='#{ response.employee_id }' data-emp-distribution-id='#{ response.id }'>
                <td>
                  <select class='select-2 employee-id' style='width: 100%'>
                      " + employeeListForPosition + "
                  </select>
                </td>" + team_td + "
                <td><input class='number-hrs form-control' type='text'  name='number-hrs' value='#{ parseFloat(response.hours_worked).toFixed(2) }' data-recalculate='true'>
                </td>
                " + moneyInFields + "
                <td class='notactive cc-out'>
                  -
                </td>
                <td class='notactive cash-out'>
                  -
                </td>

                <td class='notactive tip-outs tip-outs-given-cc'>
                  -
                </td>
                <td class='notactive tip-outs tip-outs-given-cash'>
                  -
                </td>

                <td class='notactive tip-outs tip-outs-received-cc'>
                  -
                </td>
                <td class='notactive tip-outs tip-outs-received-cash'>
                  -
                </td>

                <td class='active final-tips-distributed-cc'>
                  -
                </td>
                <td class='active final-tips-distributed-cash'>
                  -
                </td>
                <td class='actions hidden'>
                  <button class='btn btn-danger' type='button' data-action='remove-employee-distribution' data-position=\"#{ response.position_type_name }\" data-team='#{ response.team_number }'><i class='fa fa-minus-circle'></i></button>
                </td>
              </tr>
            "

            $(table).find("tbody tr.info").before(tr_line)
            line = $(table).find("tr.employee-distribution-line[data-employee-id='#{ response.employee_id }']")
            line.find("select.employee-id").first().val(response.employee_id).trigger("change")

            tr.remove()
            Tipcalc.Controllers.calculationPendingView.checkPendingBlock()
            Tipcalc.Controllers.calculationPendingView.bindActions()

            toastr["success"]("Distribution successfully added to the calculation", "Approved")
        error: (response) =>
          toastr["error"](response.responseJSON.errors, "Error")

    isTeamsQuantityUpdateRequired: (e) ->
      tr = $(e.currentTarget).closest("tr")
      team_number = tr.find(".team_number").text()
      parseInt(team_number) > gon.calculation_params.teams_quantity

    isAdditionalSourceUpdateRequired: (e) ->
      tr = $(e.currentTarget).closest("tr")
      position_type = tr.attr("data-position-type-id")
      hasTips = parseInt(tr.find(".cc_tips").text()) > 0 and parseInt(tr.find(".cash_tips").text()) > 0
      hasTips and !_.contains(gon.calculation_params.source_position_ids, position_type)

    checkPendingBlock: ->
      if $("#pending-distributions-view table tbody tr").length == 0
        $("#pending-distributions-view").remove()
      Tipcalc.Controllers.calculationView.calculate()

    bindActions: ->
      window.bindSelect2()
      window.bindPercentSelect();
      # window.bindHrsSelect();
      window.bindCheckboxes();


  )

  $(document).ready ->
    if $("body").hasClass("calculation")
      Tipcalc.Controllers.calculationPendingView = new CalculationPendingView()
)()

