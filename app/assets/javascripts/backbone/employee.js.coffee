(->
  EmployeeView = Backbone.View.extend(
    el: "body.employee"
    events:
        "click [data-emp-action='add']": "empAdd"
        "click [data-emp-action='create']": "empCreate"
        "click [data-emp-action='update']": "empUpdate"
        "click [data-emp-action='edit']": "empEdit"
        "click [data-emp-action='cancel']": "empCancel"
        "click [data-emp-action='remove']": "empRemove"
        "click [data-emp-action='reactivate']": "empReactivate"
        "click [data-emp-action='import-employees']": "saveReceiverPosition"
        "click [data-emp-action='import-start']": "empImport"
        "blur .new-employee-form .emp-id": "checkUser"
        "click .question-line .answers button": "answerToQuestion"

    initialize: ->
      @loadData()
      @initDataTables()
      @restyleRadioBox()

    loadData: ->
      for position in _.pairs(gon.positions)
        html = JST["employees/position"](position[1])
        $("#positions-list").append(html)

        positionBlock = $("table[data-position-type-id='#{ position[1].id }']")

        for employee in _.pairs(position[1].employees)
          emp_html = JST["employees/employee"](employee[1])
          positionBlock.append(emp_html)

    restyleRadioBox: ->
      $('body.employee input[type=radio]').iCheck(
        checkboxClass: 'icheckbox_square-green',
        radioClass: 'iradio_square-green'
      )

    initDataTables: ->
      _.each($('table[data-position-name]'), (e) ->
        $(e).dataTable( {
          "order": [],
          "bInfo": false,
          "paging": false,
          "searching": false,
          "columnDefs": [ {
            "targets"  : 'no-sort',
            "orderable": false,
          }]
        });
      )

    saveReceiverPosition: (e) ->
      id = $(e.currentTarget).attr("data-emp-position-type-id")
      $("[data-emp-action='import-start']").attr("data-emp-position-type-id", id)

    updatePositionCount: (positionName) ->
      table = $("[data-position-table-for='#{ positionName }-table']").first()
      tableEmployeesCount = $(table).find(".employee-line").length
      $(".total-position-employees-count[data-position-name='#{ positionName }']").text(tableEmployeesCount)

    empImport: (e) ->
      console.log "Ids"
      sourceId = $(".import-employees-wrapper input:checked").val()
      receiverId = $(e.currentTarget).attr("data-emp-position-type-id")

      console.log "Ids"
      console.log sourceId
      console.log receiverId

      $.ajax
        url: "/api/employees/import_employees"
        method: "patch"
        data:
          sourceId: sourceId
          receiverId: receiverId
        success: (e) ->
          window.location.href = "/employee"
        error: (e) ->
          toastr["error"]("Employees are not imported", "Success")

    empAdd: (e) ->
      position = $(e.currentTarget).attr("data-emp-position-type")
      position_id = $(e.currentTarget).attr("data-emp-position-type-id")
      first_name ="First Name"
      last_name ="Last Name"
      emp_id = "Employee id"

      newEmployee = {
        position: position,
        position_type_id: position_id,
        tr_class: "new-employee-form",
        emp_data_status: "new",
        status: "new",
        available_areas: []
      }

      template = JST["employees/employee"](newEmployee)
      positionTypesTable = $("[data-position-table-for=\"#{ position }-table\"]")
      positionTypesTable.find("tbody").append(template)
      positionTypesTable.find("tr[data-emp-data-status='new']").find(".emp-id, .first-name, .last-name").editAndFocus(true)

    checkUser: (e) ->
      #transfer to integer
      empId = $(e.currentTarget).val().cleanup()
      empId ||= ""

      $(e.currentTarget).val(empId)

      empId = $(e.currentTarget).val()
      return if empId.length <= 0
      position = $(e.currentTarget).attr("data-position")
      tr = $(e.currentTarget).closest("tr")
      table = $(e.currentTarget).closest("table")
      position_id = table.attr("data-position-type-id")
      tr.attr("data-emp-id", empId)

      trs = table.find("tr[data-emp-data-status='persisted']")
      tableIds = _.map(trs, (e) -> return $(e).find(".emp-id").val())

      if _.contains(tableIds, empId)
        userLine = _.find(trs, (e) -> $(e).find(".emp-id").val() is empId )

        firstName = $(userLine).find(".first-name").val()
        lastName = $(userLine).find(".last-name").val()

        $(e.currentTarget).val("")
        $(e.currentTarget).focus()
        toastr["info"]("#{ firstName } #{ lastName } already exists in the table.", "Employee exists")
      else
        $.ajax
          url: "/api/employees/check_user"
          method: "get"
          data:
            empId: empId
          success: (response) =>
            table.find(".question-line").remove()

            if $("table[data-position-table-for=\"#{ position }-table\"] tr[data-emp-id='#{ response.employee.emp_id }'].question-line").length == 0
              tr = $("table[data-position-table-for=\"#{ position }-table\"] .new-employee-form").first()
              tr.after("
                <tr class='question-line' data-emp-id='#{ response.employee.emp_id }' data-position=\"#{ position }\" data-position-type-id=\"#{ position_id }\">
                  <td colspan='6'>
                    <div class='question-block'>
                      <p class='question-text'>#{ response.employee.first_name } #{ response.employee.last_name } has already been assigned this ID. Do you want to use existing user data?</p>
                      <p class='answers'>
                        <button class='btn btn-success btn-xs' type='button' data-emp-answer='yes'>yes</button>
                        <button class='btn btn-warning btn-xs' type='button' data-emp-answer='no'>no</button>
                      </p>
                    </div>
                  </td>
                </tr>
              ")

    answerToQuestion: (e) ->
      questionTable = $(e.currentTarget).closest("table")
      questionTr = $(e.currentTarget).closest("tr")
      empId = questionTr.attr("data-emp-id")
      position = questionTr.attr("data-position")
      position_id = questionTr.attr("data-position-type-id")

      formTr = questionTable.find(".new-employee-form[data-emp-id='#{ empId }']")

      if $(e.currentTarget).attr("data-emp-answer") == "yes"
        if @idIsFree(empId, questionTable)
          $.ajax
            url: "api/employees/add_position"
            method: "patch"
            data:
              empId: empId
              position: position
            success: (response) =>
              formTr.find(".first-name").val(response.employee.first_name)
              formTr.find(".last-name").val(response.employee.last_name)

              if response.employee.active == true
                status = "active"
              else
                status = "deactivated"

              formTr.attr("data-employee-status", status)
              formTr.attr("data-employee-id", response.employee.id)
              formTr.attr("data-emp-data-status", "persisted")
              formTr.attr("data-position-type-id", position_id )
              formTr.removeClass("new-employee-form")
              formTr.find(".emp-id, .first-name, .last-name").editAndFocus(false)
              $("table[data-position-table-for=\"#{ position }-table\"] .question-line").remove()
              @updatePositionCount(position)
      else
        formTr.find(".emp-id").val("")
        $("table[data-position-table-for=\"#{ position }-table\"] .question-line").remove()

    empCreate: (e)->
      positionTypesTable = $(e.currentTarget).closest("table")
      positionTypeId = positionTypesTable.attr("data-position-type-id")
      positionTypeName = positionTypesTable.attr("data-position-name")
      tr = $(e.currentTarget).closest("tr")
      table = $(e.currentTarget).closest("table")

      if @idIsFree(tr.find(".emp-id").val(), table)
        $.ajax
          url: "api/employees"
          method: "post"
          data:
            employee:
              position_type_ids: [positionTypeId]
              first_name: tr.find(".first-name").val()
              last_name: tr.find(".last-name").val()
              emp_id: tr.find(".emp-id").val()
          success: (e) =>
            tr.removeClass("new-employee-form")
            tr.attr("data-employee-id", e['employee']['id'])
            tr.attr("data-emp-data-status", "persisted")
            tr.find(".emp-id, .first-name, .last-name").editAndFocus(false)

            toastr["success"]("Employee successfully added", "Success")
            @updatePositionCount(positionTypeName)

          error: (response) ->
            toastr["error"](response.responseText, "Error")

    empRemove: (e) ->
      tr = $(e.currentTarget).closest("tr")
      id = tr.attr("data-employee-id")
      table = tr.closest("table")
      position_type_id = table.attr("data-position-type-id")
      positionTypeName = table.attr("data-position-name")

      swal(
        title: "",
        text: "Are you sure you want to remove employee?",
        type: "info",
        confirmButtonColor: "#28C256",
        confirmButtonText: "Remove",
        showCancelButton: true,
        cancelButtonText: "Cancel"

      , (isDelete) =>
        console.log isDelete
        if isDelete
          $.ajax
            url: "api/employees/#{ id }"
            method: "delete"
            data:
              position_type_id: position_type_id
            success: (response) =>
              console.log response.employee_status
              switch response.employee_status
                when "depositioned"
                  tr.remove()
                  toastr["success"]("Employee removed from this position", "Success")
                when "deactivated"
                  $("tr[data-employee-id='#{ id }']").attr("data-employee-status", "deactivated")
                  toastr["success"]("Employee successfully deactivated", "Success")
                when "destroyed"
                  $("tr[data-employee-id='#{ id }']").remove()
                  toastr["success"]("Employee is successfully removed", "Success")
              @updatePositionCount(positionTypeName)
            error: ->
              toastr["error"]("Employee is not deactivated", "Error")
      )

    empReactivate: (e) ->
      tr = $(e.currentTarget).closest("tr")
      id = tr.attr("data-employee-id")

      swal(
        title: "",
        text: "Are you sure you want to reactivate employee?",
        type: "info",
        confirmButtonColor: "#28C256",
        confirmButtonText: "Reactivate",
        showCancelButton: true,
        cancelButtonText: "Cancel"

      , (isReactivate) =>
        if isReactivate
          $.ajax
            url: "api/employees/#{ id }/reactivate"
            method: "patch"
            data:
              employee_id: id
            success: =>
              $("tr[data-employee-id='#{ id }']").attr("data-employee-status", "active")
              toastr["success"]("Employee successfully reactivated", "Success")
            error: ->
              toastr["error"]("Employee is not reactivated", "Error")

      )

    empEdit: (e) ->
      tr = $(e.currentTarget).closest("tr")
      tr.attr("data-emp-data-status", "editing")
      tr.find(".first-name, .last-name, .emp-id").saveData().editAndFocus(true)

      selectedAreas = _.map(tr.find(".list p"), (div) ->
        return $(div).attr("data-area-id")
      )

      options = ""
      for area in gon.areas
        if _.contains(selectedAreas, area.id)
          options+= "<option value=\"#{ area.id }\" selected='selected'>#{ area.name }</option>"
        else
          options+= "<option value=\"#{ area.id }\">#{ area.name }</option>"

      form = "<select class=\"form-control area_select\" multiple placeholder='Areas'>" + options + "</select>"
      tr.find(".form").html(form)
      window.bindSelectTo(tr.find("select"))

    empCancel: (e) ->
      tr = $(e.currentTarget).closest("tr")

      if tr.attr("data-emp-data-status") is "new"
        tr.remove()
      else
        id = tr.attr("data-employee-id")
        tr.attr("data-emp-data-status", "persisted")
        tr.find(".emp-id, .first-name, .last-name").restoreData().editAndFocus(false)

    empUpdate: (e)->
      tr = $(e.currentTarget).closest("tr")
      id = tr.attr("data-employee-id")

      $.ajax
        url: "api/employees/#{ id }"
        method: "patch"
        data:
          employee:
            allowed_area_ids: tr.find(".area_select").val()
            first_name: tr.find(".first-name").val()
            last_name: tr.find(".last-name").val()
            emp_id: tr.find(".emp-id").val()
        success: (employee) =>
          console.log "1"
          console.log employee

          available_areas = ""
          for area in employee.allowed_areas
            available_areas += "<p data-area-id='#{ area.id }'>#{ area.name }</p>"
          tr.find(".list").html(available_areas)

          tr.attr("data-emp-data-status", "persisted")
          tr.find("[contenteditable='true']").attr("contenteditable", false).clearCashedData().attr("disabled", true)
          toastr["success"]("Emloyee successfully edited", "Success")
        error: ->
          toastr["error"]("Emloyee not edited", "Success")

    idIsFree: (empId, table) ->
      idExist = _.find(table.find("tbody [data-emp-data-status='persisted']"), (e) -> return $(e).find(".emp-id").val() is empId)

      if idExist
        toastr["warning"]("Employee id already exist in this table", "Error")
        false
      else
        true

  )

  $(document).ready ->
    if $("body").hasClass("employee")
      Tipcalc.Controllers.employeeView = new EmployeeView()
)()
