(->
  SubmitView = Backbone.View.extend(
    el: "body.submit-tips"

    events:
      "change #employee_distribution_area_type": "areaUpdated"
      "change #employee_distribution_shift_type": "shiftUpdated"
      "change #employee_distribution_position_type": "positionUpdated"
      "click [type=submit]": "submitStarted"

    initialize: ->
      @dateUpdated()
      $("select#employee_distribution_employee").select2()

    submitStarted: ->
      console.log "submit"
      Tipcalc.Controllers.spinner.show()

    dateUpdated: ->
      dayName = moment(gon.time).format('dddd').toLowerCase()

      if gon.restaurant_inheritance_data[dayName]
        areas = _.map(gon.restaurant_inheritance_data[dayName].areas, (e) -> {
          id: e.id, name: e.name
        })

        options = ""
        for area in areas
          options += "<option value='#{ area.id }'>#{ area.name }</option>"

        savedVal = $("select#employee_distribution_area_type").val()
        if savedVal is null or savedVal.length < 0
          savedVal = ""

        $("select#employee_distribution_area_type").html(options)
        $("select#employee_distribution_area_type").val(savedVal).trigger("change")

        savedVal = $("select#employee_distribution_area_type").val()
        if savedVal is null or savedVal.length < 0
          $("select#employee_distribution_area_type").val("").trigger("change")
      else
        $("select#employee_distribution_area_type").val("").trigger("change").html("<option value=''>Area</option>")
        $("select#employee_distribution_shift_type").val("").trigger("change").html("<option value=''>Shift</option>")
        $("select#employee_distribution_position_type").val("").trigger("change")

      @areaUpdated()
    areaUpdated: ->
      dayName = moment(gon.time).format('dddd').toLowerCase()
      areaName = $("select#employee_distribution_area_type option[value='#{ $("select#employee_distribution_area_type").val() }']").text()

      if gon.restaurant_inheritance_data[dayName] and gon.restaurant_inheritance_data[dayName].areas[areaName]
        shifts = _.map(gon.restaurant_inheritance_data[dayName].areas[areaName].shifts, (e) -> {
          id: e.id, name: e.name
        })

        options = ""
        for shift in shifts
          options += "<option value='#{ shift.id }'>#{ shift.name }</option>"

        savedVal = $("select#employee_distribution_shift_type").val()

        if savedVal is null and shifts[0]
          savedVal = shifts[0].id

        $("select#employee_distribution_shift_type").html(options)
        $("select#employee_distribution_shift_type option[value='#{savedVal}']").attr("selected", true).trigger("change")
      else
        $("select#employee_distribution_shift_type").val("").trigger("change").html("")
        $("select#employee_distribution_position_type").val("").trigger("change").html("")

      @shiftUpdated()
    shiftUpdated: ->
      dayName = moment(gon.time).format('dddd').toLowerCase()
      areaName = $("select#employee_distribution_area_type option[value='#{ $("select#employee_distribution_area_type").val() }']").text()
      shiftName = $("select#employee_distribution_shift_type option[value='#{ $("select#employee_distribution_shift_type").val() }']").text()

      areaData = gon.restaurant_inheritance_data[dayName].areas[areaName]

      if areaData and areaData.shifts[shiftName]
        positions = _.map(areaData.shifts[shiftName].positions, (e) -> {
          id: e.id, name: e.name
        })

        options = ""
        for position in positions
          options += "<option value='#{ position.id }'>#{ position.name }</option>"

        savedVal = $("select#employee_distribution_position_type").val()
        if !savedVal and positions[0]
          savedVal = positions[0].id

        $("select#employee_distribution_position_type").html(options)
        $("select#employee_distribution_position_type option[value='#{savedVal}']").attr("selected", true).trigger("change")
      else
        $("select#employee_distribution_position_type").val("").trigger("change").html("")

      @positionUpdated()
    positionUpdated: ->
      dayName = moment(gon.time).format('dddd').toLowerCase()
      areaName = $("select#employee_distribution_area_type option[value='#{ $("select#employee_distribution_area_type").val() }']").text()
      shiftName = $("select#employee_distribution_shift_type option[value='#{ $("select#employee_distribution_shift_type").val() }']").text()
      positionName = $("select#employee_distribution_position_type option[value='#{ $("select#employee_distribution_position_type").val() }']").text()

      shiftData = gon.restaurant_inheritance_data[dayName].areas[areaName].shifts[shiftName]

      if shiftData and shiftData.positions[positionName]
        employeesData = shiftData.positions[positionName]

        employees = _.map(employeesData.employees, (e) -> {
          id: e._id.$oid, name: e.first_name + " " + e.last_name
        })

        options = ""
        for employee in employees
          options += "<option value='#{ employee.id }'>#{ employee.name }</option>"

        savedVal = $("select#employee_distribution_employee").val()
        if !savedVal and employees[0] and !_.findWhere(employees, {id: savedVal})
          savedVal = employees[0].id

        "mark2"
        $("select#employee_distribution_employee").html(options)
        $("select#employee_distribution_employee option[value='#{savedVal}']").attr("selected", true).trigger("change")
      else
        $("select#employee_distribution_employee").val("").trigger("change").html("")

  )

  $(document).ready ->
    if $("body").hasClass("submit-tips")
      Tipcalc.Controllers.submitView = new SubmitView()
)()