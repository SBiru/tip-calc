(->
  DistributionsView = Backbone.View.extend(
    el: "#distributions-list-wrapper"
    events:
      #Adding fields to tables
      "click [data-action='add-employee']": "addEmployee"
      "click [data-action='edit-employee'], [data-action='edit-employee-cancel']": "editEmployee"
      "click [data-action='remove-employee-distribution']": "removeEmployee"
      "ifChanged .toggle-tip-outs": "toggleTipOuts"
      "ifChanged .toggle-sales": "toggleSales"

    initialize: (options) ->
      @scope = options.scope

    addMissingTables: (source_positions, teams_quantity) ->
      data = Tipcalc.Controllers.calculationFormView.getNewPositionsAndTeams()

      _.each data.positions, (position) =>
        positionBlock = $("[data-position-block-name=\"#{ position.position_type_name }\"]")

        _.each (_.range(1,data.team_count + 1)) , (teamNumber) =>
          string = position.position_type_name + " " + teamNumber

          positionTable = positionBlock.find("[data-position-table=\"#{ position.position_type_name }\"][data-team='#{ teamNumber }']")

          if positionTable.length is 0
            console.log "#{ string } missing"
            html = @generateHtmlForTeam({
              position_type_name: position.position_type_name,
              position_type_id: position.position_type_id,
              position_type_is_a_source: true,
              team_no: teamNumber,
              team_count: data.team_count,
            })

            positionBlock.append(html)

          else
            $(positionTable).attr("data-position-is-a-source", true)
            teamTableBlock = $(positionTable).closest(".team-table-block")
            teamTableHeader = teamTableBlock.find(".team-table-name").text(
              position.position_type_name.toUpperCase() + " (Team ##{  teamNumber})"
            )

    removeDestroyedTeamsAndPositions: ->
      data = Tipcalc.Controllers.calculationFormView.getNewPositionsAndTeams()

      # Remove depricated teams from page
      teamsArray = _.range(1, data.team_count + 1)

      _.each $(".team-table"), (teamTable) ->
        teamNumber = parseInt($(teamTable).attr("data-team"))
        unless _.contains teamsArray, teamNumber
          $(".team-table[data-team='#{ teamNumber }']").closest(".team-table-block").remove()

      # Remove depricated source positions (including all employee distributions) from page
      new_source_position_ids = _.map(data.positions, (e) -> e.position_type_id)
      oldSourcePositionIds = gon.calculation_params.source_position_ids
      removedSourcePositionIds = _.difference(oldSourcePositionIds,new_source_position_ids)

      _.each removedSourcePositionIds, (position_id) ->
        position_name = _.findWhere(gon.all_related_employees, {position_type_id: position_id}).position_type_name
        $("[data-position-block-name=\"#{ position_name }\"] table").attr("data-position-is-a-source", false)
        $("[data-position-block-name=\"#{ position_name }\"] .employee-distribution-line").remove()

    generateHtmlForTeam: (params) ->
      JST["calculation/distributions/distributions_team_table"](params)

    toggleTipOuts: ->
      $("#distributions-list").attr("data-tip-outs-shown", $(".toggle-tip-outs")[0].checked)

    toggleSales: ->
      $("#distributions-list").attr("data-sales-shown", $(".toggle-sales")[0].checked)

    addEmployee: (e) ->
      position = $(e.currentTarget).attr("data-position")
      $("[data-action='edit-employee-cancel'][data-position=\"#{ position }\"]").addClass("hidden")
      $("[data-action='edit-employee'][data-position=\"#{ position }\"]").removeClass("hidden")
      $("table[data-position-table=\"#{position}\"]").find(".actions").addClass("hidden")

      # table[data-position-table]
      table = $("table[data-position-table=\"#{ $(e.currentTarget).attr('data-position') }\"][data-team='#{ $(e.currentTarget).attr('data-team') }']").first()
      # tr_example = $(table).find("tbody tr").first().clone()
      if $(table).attr("data-position-is-a-source") is "false" || $(table).attr("data-team-count") is "1"
        team_td = ""
      else
        team_td = "<td>" + $(e.currentTarget).attr('data-team') + "</td>"

      moneyInFields = "
        <td class='notactive sales-summ source-only-fields sales-cell'>
            <div class='input-group m-b'><span class='input-group-addon'>$</span> <input type='text' placeholder='0.00' class='form-control' value='0.00' data-recalculate='true'></div>
        </td>
        <td class='notactive cc-in source-only-fields'>
            <div class='input-group m-b'><span class='input-group-addon'>$</span> <input type='text' placeholder='0.00' class='form-control' value='0.00' data-recalculate='true'></div>
        </td>
        <td class='notactive cash-in source-only-fields'>
            <div class='input-group m-b'><span class='input-group-addon'>$</span> <input type='text' placeholder='0.00' class='form-control' value='0.00' data-recalculate='true'></div>
        </td>
      "

      existedEmployeeIds = _.map(table.find("select.employee-id"), (e) -> return $(e).val() )
      employeeListForPosition = ""
      for emp in gon.related_employees[$(e.currentTarget).attr('data-position')].employees
        unless _.contains(existedEmployeeIds, emp.id)
          employeeListForPosition += "<option value='#{ emp.id }'>#{ emp.name }</option>"

      if employeeListForPosition.length > 0
        # TODO add real emloyees
        tr_example = "
          <tr class='employee-distribution-line' data-emp-distribution-status='new'>
            <td>
              <select class='select-2 employee-id' style='width: 100%'>
                  " + employeeListForPosition + "
              </select>
            </td>
            "  + team_td + "
            <td><input class='number-hrs form-control' type='text'  name='number-hrs' value='0.00' data-recalculate='true'></td>
            " + moneyInFields + "
            <td class='notactive cc-out'>
              -
            </td>
            <td class='notactive cash-out'>
              -
            </td>

            <td class='notactive tip-outs tip-outs-given-cc'>
              0
            </td>
            <td class='notactive tip-outs tip-outs-given-cash'>
              0
            </td>

            <td class='notactive tip-outs tip-outs-received-cc'>
              0
            </td>
            <td class='notactive tip-outs tip-outs-received-cash'>
              0
            </td>

            <td class='active final-tips-distributed-cc'>
              0
            </td>
            <td class='active final-tips-distributed-cash'>
              0
            </td>
            <td class='actions hidden'>
              <button class='btn btn-danger' type='button' data-action='remove-employee-distribution' data-position=\"#{ $(e.currentTarget).attr('data-position') }\" data-team='#{ $(e.currentTarget).attr('data-team') }'><i class='fa fa-minus-circle'></i></button>
            </td>
          </tr>
        "

        $(table).find("tbody tr.info").before(tr_example)

        window.bindSelect2();
        @updateEmployeeLinesIds()
        @scope.calculate()
      else
        toastr["info"]("You have added all employees for this position.", "No employees")

      @updateSelectBoxesIn($(table))

    updateEmployeeLinesIds: (e) ->
      #TODO - updat only this line
      _.each $(".employee-distribution-line"), (line) =>
        id = $(line).find("select.employee-id").val()
        $(line).attr("data-employee-id", id)

      if e
        tr = $(e.currentTarget).closest("tr")

        if tr.attr("data-emp-distribution-status") is 'persisted' and tr.attr("data-emp-distribution-id")
          $.ajax
            url: "/api/employee_distributions/change_employee"
            method: "patch"
            data:
              calculation_id: gon.calculation_id
              employee_distribution_id: tr.attr("data-emp-distribution-id")
              employee_id: tr.attr("data-employee-id")
            success: (event) =>
              console.log "Employee distribution is updated"
              @updateSelectBoxesIn( $(e.currentTarget).closest("table") )
            error: (e) ->
              console.log "Employee distribution is not updated"
        else
          @updateSelectBoxesIn( $(e.currentTarget).closest("table") )

    updateTableSelectBoxes: (table) ->
      _.each $("table[data-table-type='employee-distribution']"), (table) =>
        @updateSelectBoxesIn( $(table) )

    updateSelectBoxesIn: (table) ->
      position = table.attr("data-position-table")
      employees = gon.all_related_employees[position].employees

      busyEmployeeIds = _.map(table.find("select.employee-id"), (e) -> $(e).val())
      freeEmployees = _.filter(employees, (employee) -> !_.contains(busyEmployeeIds, employee.id) )

      _.each table.find("select"), (select) ->
        selectedOption = $(select).val()
        selectedOptionText = _.filter(employees, (employee) -> employee.id is selectedOption )
        selectedOptionText = selectedOptionText[0].full_info

        options = ""
        options += "<option value='#{ selectedOption }'>#{ selectedOptionText }</option>"
        for employee in freeEmployees
          options += "<option value='#{ employee.id }'>#{ employee.full_info }</option>"

        $(select).html(options)

    removeEmployee: (e) ->
      tr = $(e.currentTarget).closest("tr")
      table = $(e.currentTarget).closest("table")

      if tr.attr("data-emp-distribution-status") is "new"
        tr.remove()
        @scope.calculate()
        @updateSelectBoxesIn(table)
      else if tr.attr("data-emp-distribution-status") is "persisted"
        $.ajax
          url: "/api/employee_distributions/remove_distribution"
          method: "delete"
          data:
            calculation_id: gon.calculation_id
            position_type_id: table.attr("data-position-type-id")
            employee_id: tr.attr("data-employee-id")
          success: (e) =>
            toastr["success"]("Employee distribution removed", "Success")
            tr.remove()
            @scope.calculate()
            @updateSelectBoxesIn(table)
          error: (e) =>
            toastr["error"]("Employee distribution was not removed", "Error")

    editEmployee: (e) ->
      position = $(e.currentTarget).attr("data-position")
      action = $("[data-action='edit-employee'][data-position=\"#{ position }\"], [data-action='edit-employee-cancel'][data-position=\"#{ position }\"]").toggleClass("hidden")
      table = $("table[data-position-table=\"#{position}\"]").find(".actions").toggleClass("hidden")
  )

  Tipcalc.Controllers.DistributionsViewPrototype = DistributionsView
)()

