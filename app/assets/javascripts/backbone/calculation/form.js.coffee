(->
  CalculationFormView = Backbone.View.extend(
    el: "body.calculation"
    events:
      "change #area_type_id": "areaUpdated"
      "change #shift_type_id": "shiftUpdated"
      "change [data-required-field='true']": "checkIfDataValid"
      "change .changeble-data select": "calculationChanged"
      "click .show-calculation": "showCalculation"
      "click button[data-calculation-action]": "chooseCalculationVariant"

    initialize: ->
      $('.datapicker').datepicker().on("changeDate", => @dateUpdated())
      @checkIfDataValid()
      @dateUpdated()
      @areaUpdated()
      @shiftUpdated()

    # =============================== #
    # Updating calculation logic
    # =============================== #

    showCalculation: (e) ->
      e.preventDefault()
      if $(".changeble-data").hasClass("changed")
        @updateCalculation(e)
      else
        @checkCalculation()

    updateCalculation: (e) ->
      return false if $(".show-calculation").attr("disabled") is "disabled"

      if @isTeamsQuantityReduced()
        Tipcalc.Controllers.notifier.alert(
          "",
          "All information for removed teams will be deleted and is not reversible. Are you sure you want to continue?",
          false,
          true,
          => @sendUpdateRequest()
        )
      else if @isInitialSourcesQuantityReduced()
        Tipcalc.Controllers.notifier.alert(
          "",
          "All information for removed position will be deleted and is not reversible. Are you sure you want to continue?",
          false,
          true, 
          => @sendUpdateRequest()
        )
      else
        @sendUpdateRequest()

    sendUpdateRequest: ->
      Tipcalc.Controllers.calculationView.distributionsView.addMissingTables()
      Tipcalc.Controllers.calculationView.distributionsView.removeDestroyedTeamsAndPositions()
      params = {
        updateCalculationRequired: true
      }
      Tipcalc.Controllers.calculationView.checkCalculationExistance(params)

    addSourcePositionById: (options) ->
      ids = _.union gon.calculation_params.source_position_ids, [options.id]
      $("select#source_position_ids").val(ids).trigger("change")
      @updateCalculation() if options.forceUpdate

    changeTeamQuantityTo: (options) ->
      $("select#teams_quantity").val(options.teamNumber).trigger("change")
      @updateCalculation() if options.forceUpdate

    getNewPositionsAndTeams: ->
      positions_ids = $("#calculation-form-wrapper").find("select#source_position_ids").val()
      {
        positions: _.map(positions_ids, (id) ->
          {
            position_type_id: id,
            position_type_name: _.findWhere(gon.all_related_employees, {position_type_id: id}).position_type_name
          }),
        team_count: parseInt($("#calculation-form-wrapper").find("select#teams_quantity").val())
      }

    chooseCalculationVariant: (isDelete) ->
      method = "show-old"
      $("input#existed_calculation_method").val(method)
      $(".show-calculation-request").click()

    # =============================== #
    # Seeding form with relative data
    # =============================== #

    dateUpdated: ->
      dayName = moment($("#date").val()).format('dddd').toLowerCase()

      if gon.restaurant_inheritance_data[dayName]
        areas = _.map(gon.restaurant_inheritance_data[dayName].areas, (e) -> {
          id: e.id, name: e.name
        })

        options = ""
        options += "<option value=''>Area</option>"
        for area in areas
          options += "<option value='#{ area.id }'>#{ area.name }</option>"

        savedVal = $("#calculation-form-wrapper").find("select#area_type_id").val()
        if savedVal is null or savedVal.length < 0
          savedVal = ""

        $("#calculation-form-wrapper").find("select#area_type_id").html(options).select2(theme: "bootstrap")
        $("#calculation-form-wrapper").find("select#area_type_id").val(savedVal).trigger("change")

      else
        $("#calculation-form-wrapper").find("select#area_type_id").val("").trigger("change").html("<option value=''>Area</option>")
        $("#calculation-form-wrapper").find("select#shift_type_id").val("").trigger("change").html("<option value=''>Shift</option>")
        $("#calculation-form-wrapper").find("select#source_position_ids").val("").trigger("change")

    areaUpdated: ->
      dayName = moment($("#date").val()).format('dddd').toLowerCase()
      areaName = $("#calculation-form-wrapper").find("select#area_type_id option[value='#{ $("select#area_type_id").val() }']").text()

      if gon.restaurant_inheritance_data[dayName] and gon.restaurant_inheritance_data[dayName].areas[areaName]
        shifts = _.map(gon.restaurant_inheritance_data[dayName].areas[areaName].shifts, (e) -> {
          id: e.id, name: e.name
        })

        options = ""
        options += "<option value=''>Shift</option>"
        for shift in shifts
          options += "<option value='#{ shift.id }'>#{ shift.name }</option>"

        savedVal = $("#calculation-form-wrapper").find("select#shift_type_id").val()
        if savedVal is null or savedVal.length < 0
          savedVal = ""
        $("#calculation-form-wrapper").find("select#shift_type_id").html(options).select2(theme: "bootstrap")
        $("#calculation-form-wrapper").find("select#shift_type_id").val(savedVal).trigger("change")
      else
        $("#calculation-form-wrapper").find("select#shift_type_id").val("").trigger("change").html("<option value=''>Shift</option>")
        $("#calculation-form-wrapper").find("select#source_position_ids").val("").trigger("change")#.html("<option value=''>Source position</option>")

    shiftUpdated: ->
      dayName = moment($("#date").val()).format('dddd').toLowerCase()
      areaName = $("#calculation-form-wrapper").find("select#area_type_id option[value='#{ $('select#area_type_id').val() }']").text()
      shiftName = $("#calculation-form-wrapper").find("select#shift_type_id option[value='#{ $("select#shift_type_id").val() }']").text()

      areaData = gon.restaurant_inheritance_data[dayName].areas[areaName]

      if areaData and areaData.shifts[shiftName]
        positions = _.map(areaData.shifts[shiftName].positions, (e) -> {
          id: e.id, name: e.name
        })

        options = ""
        # options += "<option value=''>Source position</option>"
        for position in positions
          options += "<option value='#{ position.id }'>#{ position.name }</option>"

        savedVal = $("select#source_position_ids").val()
        $("select#source_position_ids").html(options).select2({theme: "bootstrap", multiple: true})
        $("select#source_position_ids").val(savedVal).trigger("change")
      else
        $("select#source_position_ids").val("").trigger("change")#.html("<option value=''>Source position</option>")

    # =============================== #
    # Validations
    # =============================== #

    updatableParamsChanged: ->
      # These params can be changed for existing calculation
      sources1 = $("#calculation-form-wrapper").find("select#source_position_ids").val()
      sources2 = gon.calculation_params.source_position_ids

      teams1 = parseInt($("#calculation-form-wrapper").find("select#teams_quantity").val())
      teams2 = parseInt(gon.calculation_params.teams_quantity)

      !_.isEqual(sources1, sources2) or !_.isEqual(teams1, teams2)

    lockedParamsChanged: ->
      # These params are not changeble for calculation
      date1 = $("#calculation-form-wrapper").find("input#date").val()
      date2 = gon.calculation_params.date

      area_type_id1 = $("#calculation-form-wrapper").find("select#area_type_id").val()
      area_type_id2 = gon.calculation_params.area_type_id

      shift_type_id1 = $("#calculation-form-wrapper").find("select#shift_type_id").val()
      shift_type_id2 = gon.calculation_params.shift_type_id

      !_.isEqual(date1, date2) or
      !_.isEqual(area_type_id1, area_type_id2) or
      !_.isEqual(shift_type_id1, shift_type_id2)

    isTeamsQuantityReduced: (e) ->
      # Checking if team quantity was reduced
      teamsNow = parseInt($("#calculation-form-wrapper").find("select#teams_quantity").val())
      teamsInitially = parseInt(gon.calculation_params.teams_quantity)
      teamsNow < teamsInitially

    isInitialSourcesQuantityReduced: (e) ->
      # We should check if some of the old positions are being cutted, not only sources count
      sourcesNow = $("#calculation-form-wrapper").find("select#source_position_ids").val()
      sourcesInitially = gon.calculation_params.source_position_ids
      commonPositionIds = _.intersection(sourcesNow, sourcesInitially)    
      commonPositionIds.length < sourcesInitially.length

    calculationChanged: (e) ->
      return true unless gon.calculation_id
      if @updatableParamsChanged() && !@lockedParamsChanged()
        $(".changeble-data").addClass("changed")

      else
        $(".changeble-data").removeClass("changed")

    checkCalculation: (e) ->
      dateVal = $("#calculation-form-wrapper").find("input#date").val()

      areaVal = $("#calculation-form-wrapper").find("select#area_type_id").val()
      areaName = $("#calculation-form-wrapper").find("select#area_type_id option[value='" + areaVal + "']").text()

      shiftVal = $("#calculation-form-wrapper").find("select#shift_type_id").val()
      shiftName = $("#calculation-form-wrapper").find("select#shift_type_id option[value='" + shiftVal + "']").text()

      $.ajax
        url: "/api/calculations/check_calculation"
        method: "get"
        data:
          area_type_id: areaVal
          shift_type_id: shiftVal
          date: dateVal
        success: (response) =>
          if response.persisted is true
            swal(
              title: "",
              text: "Tip Record for #{ dateVal } #{ areaName } + #{ shiftName } already exists. Would you like to edit it?",
              type: "info",
              confirmButtonColor: "#28C256",
              confirmButtonText: "Show Tip Record"
              showCancelButton: true,
              cancelButtonText: "Cancel"
            , (isDelete) =>
              if isDelete
                @chooseCalculationVariant(isDelete)
            )
          else
            $(".show-calculation-request").click()
        error: (response) ->
          if response.responseJSON.locked or response.responseJSON.has_no_access_to_area
            toastr["error"](response.responseJSON.errors, "Error")

    checkIfDataValid: (e) ->
      fields = $("#calculation-form-wrapper").find("input[name='date'], select[name='area_type_id'], select[name='shift_type_id'], select[id='source_position_ids'], select[name='teams_quantity']")
      blankFields = _.filter(fields, (e) ->
        return $(e).val() == null || $(e).val().length == 0 || $(e).val().length == undefined
      ) || []
      if blankFields.length == 0
        $(".show-calculation").removeAttr("disabled")
      else
        $(".show-calculation").attr("disabled", "disabled")
  )

  $(document).ready ->
    if $("body").hasClass("calculation")
      Tipcalc.Controllers.calculationFormView = new CalculationFormView()
)()

