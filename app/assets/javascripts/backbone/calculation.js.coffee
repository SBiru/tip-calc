(->
  CalculationView = Backbone.View.extend(
    el: "body.calculation"
    data: {}
    events:
      "keyup [data-recalculate='true']": "updateTotalNumbers"
      "change [data-recalculate='true']": "updateTotalNumbers"
      "keyup [data-recalculate-total-numbers='true']": "updateTotalNumbers"
      "change [data-recalculate-total-numbers='true']": "updateTotalNumbers"
      "change input[name='distribution_type']": "changeDistributionType"
      "change select.employee-id": (e) ->
        @distributionsView.updateEmployeeLinesIds(e)
      "click #save-calculation": "saveCalculationIfExist"
      "click .show-percent-variations": "showPercentVariations"
      "click .implement-percents button": "implementPercents"

    # =============================== #
    # Helpers
    # =============================== #

    empDistrTables: -> $("[data-table-type='employee-distribution']")
    positionDistrTables: (position) -> $("[data-table-type='employee-distribution'][data-position-table=\"#{ position }\"]")
    distribution_type: -> $("[name='distribution_type']:checked").val()
    dataChanged: -> $("#save-calculation").removeAttr("disabled")
    isDataSaved: -> $("#save-calculation").attr("disabled") is "disabled"

    # =============================== #
    # Initialization
    # =============================== #

    initialize: ->
      @loadModules()

      @updateTotalNumbers()
      @dataSaved()
      @bindWindowClose()
      @distributionsView.updateTableSelectBoxes()
      @restyleCheckbox()

    loadModules: ->
      @tipOutView = new Tipcalc.Controllers.TipOutViewPrototype({scope: @})
      @distributionsView = new Tipcalc.Controllers.DistributionsViewPrototype({scope: @})

    restyleCheckbox: ->
      $('body.calculation input[type=checkbox]').iCheck(
        checkboxClass: 'icheckbox_square-green',
        radioClass: 'iradio_square-green'
      )

    bindWindowClose: ->
      window.onbeforeunload = (e) ->
        if $("#save-calculation").attr("disabled") is undefined
          message = "Please save information before close the window."
          if typeof e is "undefined"
            e = window.event;

          if e
            e.returnValue = message;

          return message;

    changeDistributionType: (e) ->
      $("#percentage").attr("data-distribution-type", $(e.currentTarget).val())
      @dataChanged()
      @updateTotalNumbers()

    updateTotalNumbers: (e) ->
      numbers = _.map($("#given-tipouts-table .tip-out-line .tip-out-percentage"), (num) -> return parseFloat($(num).val()) )
      totalTipOutsGiven = _.reduce(numbers, (memo, num) -> return memo + num) || 0
      $(".total-tip-out-summ .percentage-point").closest("tr").attr("data-total-tip-out-given-percentage", totalTipOutsGiven)
      $(".total-tip-out-summ .percentage-point .number").text(totalTipOutsGiven)

      givenTipoutsTotal = parseFloat($(".total-tip-out-summ .percentage-point").closest("tr").attr("data-total-tip-out-given-percentage"))

      if givenTipoutsTotal > 0
        multiplier = 100/(100 - givenTipoutsTotal)
      else
        multiplier = 1

      _.each $("#percentage .percentage-point"), (e) ->
        $(e).attr("percentage-final-value", parseFloat($(e).val())*multiplier)

      if @distribution_type() == "percents"
        numbers = _.map($("#percentage .percentage-point"), (num) -> return parseFloat($(num).val() || $(num).text()) )
        total = _.reduce(numbers, (memo, num) -> return memo + num) || 0

        if total != 100
          $(".percentage-total-cell").addClass("danger")
        else
          $(".percentage-total-cell").removeClass("danger")
      else
        $(".percentage-total-cell").removeClass("danger")
        total = @totalPoints()

      @calculate()

      $(".percentage-total").text(total.toFixed(2))

    clearDataForSaving: (data) ->
      delete data.totalPointsSumm;
      delete data.totalCollectedMoney;
      delete data.tipOuts;
      delete data.finalToDistribute;
      delete data.collectedMoneyDistributePercentsPart;
      delete data.initialPointsHourPrice;

      _.each data.positionsMoney, (v, positionName) ->
        delete data.positionsMoney[positionName].positionTeamsCount
        delete data.positionsMoney[positionName].totalHoursForPosition
        delete data.positionsMoney[positionName].positionPoints
        delete data.positionsMoney[positionName].positionTotalPoints
        delete data.positionsMoney[positionName].totalPositionMoney
        delete data.positionsMoney[positionName].totalPositionMoneyToShow

        _.each data.positionsMoney[positionName].teams, (team) ->
          delete team.totalTeamMoneyToDistribute
          delete team.totalTeamCollectedMoney
          delete team.hourPrice
          delete team.teamTotal

          _.each team.employees, (emp, id) ->
              delete team.employees[id].totalMoneyOut
              delete team.employees[id].employeePointsPart
              delete team.employees[id].totalTipOutsGiven
              delete team.employees[id].totalTipOutsReceived
              delete team.employees[id].finalMoneyToDistribute

      data

    # =============================== #
    # Duplicating percents
    # =============================== #

    showPercentVariations: ->
      Tipcalc.Controllers.spinner.show()
      $.ajax
        url: "/api/calculations/#{ gon.calculation_id }/percent_variations"
        method: "get"
        success: (response) =>
          Tipcalc.Controllers.spinner.hide()
          @data.percentVariations = response.percent_variations
          html = JST["calculation/percent_variations"](response.percent_variations)
          $(".implement-percents-wrapper").html(html)
          $('.modal').modal('toggle');
 
    implementPercents: (e) ->
      calculationId = $(e.currentTarget).closest('.implement-percents').attr('data-calculation-id')

      calculations = _.filter(Tipcalc.Controllers.calculationView.data.percentVariations, (e) ->
        _.pairs(e)[0][0] is calculationId
      )

      for position in calculations[0][calculationId]
        $("#positions-table").find(".percentage-point[data-percentage-for='#{ position.position_type_name }']").val(position.percentage.toFixed(2))

      @dataChanged()
      @updateTotalNumbers()
      $('.modal').modal('toggle');

    # =============================== #
    # Saving process
    # =============================== #

    saveCalculationIfExist: (e) ->
      e.preventDefault()
      @checkCalculationExistance({})

    checkCalculationExistance: (params) ->
      $.ajax
        url: "/api/calculations/#{ gon.calculation_id }/check_existance"
        method: "get"
        success: (response) =>
          @saveCalculation(params)
        error: (response) ->
          # $(".row.percentage, #distributions-list, .distributions-list-header").fadeOut()
          $("#save-calculation").attr("disabled", "disabled")

          swal(
            title: "",
            text: "Looks like somebody destroyed this calculation from another tab/computer. Please click \"Show\" button and recreate it again.",
            type: "info",
            confirmButtonColor: "#28C256",
            confirmButtonText: "OK",
            showCancelButton: false
          , (isDelete) =>
            console.log isDelete
          )

    saveCalculation: (params) ->
      Tipcalc.Controllers.spinner.show()

      forceSave = params.updateCalculationRequired

      if $("#save-calculation").attr("disabled") isnt "disabled" or forceSave
        data = @buildData(params)

        $.ajax
          url: "/api/calculations/#{ data.calculationId }"
          method: "patch"
          data: data
          success: (response) =>
            toastr["success"]("Calculation successfully saved", "Success") unless params.afterUpdateCallback
            @updateNewdistributions(response.distributions)
            @tipOutView.syncTipOutsWithData(response.tip_outs)
            @updateGonCalculationParams(response.calculation_params)
            Tipcalc.Controllers.spinner.hide()
            params.afterUpdateCallback.action(params.afterUpdateCallback.event) if params.afterUpdateCallback
            @calculate()
            @dataSaved()
          error: (response) ->
            toastr["error"](response.responseText, "Error")
            Tipcalc.Controllers.spinner.hide()

    updateNewdistributions: (distributions) ->
      for distribution in distributions
        position_type_id = distribution.position_type_id.$oid
        employee_id = distribution.employee_id.$oid
        distribution_id = distribution._id.$oid

        line = $("table[data-position-type-id='#{ position_type_id}'] .employee-distribution-line[data-employee-id='#{ employee_id }']")[0]

        $(line).attr("data-emp-distribution-id", distribution_id)
        $(line).attr("data-emp-distribution-status", "persisted")

    # =============================== #
    # Changing page data
    # =============================== #

    updateGonCalculationParams: (params) ->
      gon.calculation_params = params
      Tipcalc.Controllers.calculationFormView.calculationChanged()

    dataSaved: ->
      $("#save-calculation").attr("disabled", "disabled")
      $(".employee-distribution-line").attr("data-emp-distribution-status", "persisted")

    seedData: (data) ->
      _.each data.positionsMoney, (positionData, positionName) =>
        tableCss = "[data-table-type='employee-distribution'][data-position-table=\"#{positionName}\"]"

        percentageTable = $("#positions-table [data-position-type=\"#{ positionName }\"]")
        percentageTable.find(".total-position-cc-tips").text(positionData.totalPositionMoneyToShow.cc.toFixed(2))
        percentageTable.find(".total-position-cash-tips").text(positionData.totalPositionMoneyToShow.cash.toFixed(2))

        _.each positionData.teams, (teamData, teamNumber) =>
          teamTable = $("#{ tableCss }[data-team='#{teamNumber}']")

          _.each teamData.employees, (empData, id) =>
            tr = $(teamTable).find(".employee-distribution-line[data-employee-id='#{id}']")
            tr.find(".cc-out").text( empData.totalMoneyOut.cc.toFixed(2))
            tr.find(".cash-out").text( empData.totalMoneyOut.cash.toFixed(2))

            tr.find(".tip-outs-given-cc").text(empData.totalTipOutsGiven.cc.toFixed(2))
            tr.find(".tip-outs-given-cash").text(empData.totalTipOutsGiven.cash.toFixed(2))

            tr.find(".tip-outs-received-cc").text(empData.totalTipOutsReceived.cc.toFixed(2))
            tr.find(".tip-outs-received-cash").text(empData.totalTipOutsReceived.cash.toFixed(2))

            tr.find(".final-tips-distributed-cc").text(empData.finalMoneyToDistribute.cc.toFixed(2))
            tr.find(".final-tips-distributed-cash").text(empData.finalMoneyToDistribute.cash.toFixed(2))

          return true if teamData.employees.length == 0

          totalTeamTr = teamTable.find(".info")

          totalTeamTr.find(".total-hours h4").text(teamData.teamTotal.totalPositionHoursWorked.toFixed(2))
          totalTeamTr.find(".total-sales-summ h4").text(teamData.teamTotal.totalTeamSales.toFixed(2))
          totalTeamTr.find(".total-cc-out h4").text(teamData.teamTotal.ccToDistribute.toFixed(2))
          totalTeamTr.find(".total-cash-out h4").text(teamData.teamTotal.cashToDistribute.toFixed(2))
          totalTeamTr.find(".total-tip-outs-given-cc h4").text(teamData.teamTotal.totalTeamTOGivenCC.toFixed(2))
          totalTeamTr.find(".total-tip-outs-given-cash h4").text(teamData.teamTotal.totalTeamTOGivenCash.toFixed(2))
          totalTeamTr.find(".total-tip-outs-received-cc h4").text(teamData.teamTotal.totalTeamTOReceivedCC.toFixed(2))
          totalTeamTr.find(".total-tip-outs-received-cash h4").text(teamData.teamTotal.totalTeamTOReceivedCash.toFixed(2))
          totalTeamTr.find(".total-tips-distributed-cc h4").text(teamData.teamTotal.finalTeamTODistributeCC.toFixed(3))
          totalTeamTr.find(".total-tips-distributed-cash h4").text(teamData.teamTotal.finalTeamTODistributeCash.toFixed(3))

          if positionData.positionTypeIsASource == "true"
            totalTeamTr.find(".total-cc-in h4").text(teamData.totalTeamCollectedMoney.cc.toFixed(2))
            totalTeamTr.find(".total-cash-in h4").text(teamData.totalTeamCollectedMoney.cash.toFixed(2))

          totalTr = teamTable.find(".total-position-tips")
          totalTr.find(".total-position-cc-tips").text(teamData.totalTeamMoneyToDistribute.cc.toFixed(2))
          totalTr.find(".total-position-cash-tips").text(teamData.totalTeamMoneyToDistribute.cash.toFixed(2))

      $("#total-block .hours").text(data.totalHoursWorked)
      $("#total-block .sales").text(data.totalSales)

      $("#positions-table .total-tip-out-cc-tips").text(data.tipOuts.given.cc.toFixed(2))
      $("#positions-table .total-tip-out-cash-tips").text(data.tipOuts.given.cash.toFixed(2))

      $("#total-block .cc-out-total, .tips-total .cc-out-total, .total .total-collected-cc-tips").text(data.totalCollectedMoney.cc.toFixed(2))
      $("#total-block .cash-out-total, .tips-total .cash-out-total, .total .total-collected-cash-tips").text(data.totalCollectedMoney.cash.toFixed(2))

      $("#total-block .tip-outs-given-cc").text(data.tipOuts.given.cc.toFixed(2))
      $("#total-block .tip-outs-given-cash").text(data.tipOuts.given.cash.toFixed(2))

      $("#total-block .tip-outs-received-cc").text(data.tipOuts.received.cc.toFixed(2))
      $("#total-block .tip-outs-received-cash").text(data.tipOuts.received.cash.toFixed(2))

      $("#total-block .tips-distributed-cc").text(data.finalToDistribute.cc.toFixed(2))
      $("#total-block .tips-distributed-cash").text(data.finalToDistribute.cash.toFixed(2))

    # =============================== #
    # Calculation process
    # =============================== #

    calculate: (params) ->
      data = @buildData()
      @seedData(data)
      @dataChanged()
      @varianceCheck()

    totalPoints: ->
      totalPointsMap = _.map $("[data-table-type='employee-distribution']"), (empDistrTable) =>
        positionType = $(empDistrTable).attr("data-position-table")
        hoursMap = _.map($(empDistrTable).find(".employee-distribution-line .number-hrs"), (num) -> return parseFloat($(num).val()) )
        totalHoursForPosition = _.reduce(hoursMap, (sum, num) -> return sum + num ) || 0
        positionPoints = ($("#positions-table input[data-percentage-for=\"#{positionType}\"]").val()) || 0
        positionTotalPoints = positionPoints * totalHoursForPosition

        positionTotalPoints

      totalPoints = _.reduce(totalPointsMap, (sum, num) -> return sum + num ) || 0
      totalPoints = totalPoints

      totalPoints

    buildPosTotals: ->
      {
        calculationPosTotal: parseFloat($("#calculation-pos-total").val()) || 0,
        dayPosTotal: parseFloat($("#day-pos-total").val()) || 0
      }

    totalHoursWorked: ->
      totalHoursWorked = _.map($(".employee-distribution-line .number-hrs"), (input) -> return parseFloat($(input).val()) )
      totalHoursWorked = _.reduce(totalHoursWorked, (sum, num) -> return sum + num ) || 0
      totalHoursWorked = totalHoursWorked.toFixed(2)


    totalSales: ->
      totalSales = _.map($(".employee-distribution-line .sales-summ input"), (input) -> return parseFloat($(input).val()) )
      totalSales = _.reduce(totalSales, (sum, num) -> return sum + num ) || 0
      totalSales = totalSales.toFixed(2)

    buildTotalCollectedMoney: ->
      ccMap = _.map(@empDistrTables().find(".employee-distribution-line .cc-in input"), (num) -> return parseFloat($(num).val()) )
      ccTotalSum = _.reduce(ccMap, (sum, num) -> return sum + num ) || 0

      cashMap = _.map(@empDistrTables().find(".employee-distribution-line .cash-in input"), (num) -> return parseFloat($(num).val()) )
      cashTotalSum = _.reduce(cashMap, (sum, num) -> return sum + num ) || 0

      {
        cc: ccTotalSum,
        cash: cashTotalSum
      }

    buildTipOuts: (data) ->
      givenTipOutsPercents = _.map($("#tip-out #given-tipouts-table tbody tr input.tip-out-percentage"), (num) -> return parseFloat($(num).val()) )
      givenTipOutsTotalPercents = _.reduce(givenTipOutsPercents, (sum, num) -> return sum + num ) || 0
      givenTipOutsTotalMoneyCC = givenTipOutsTotalPercents*@data.totalCollectedMoney.cc/100
      givenTipOutsTotalMoneyCash = givenTipOutsTotalPercents*@data.totalCollectedMoney.cash/100

      _.each $("#tip-out #given-tipouts-table tbody tr"), (tipOutLine) ->
        percent = parseFloat($(tipOutLine).find("input.tip-out-percentage").val() || 0)/100
        ccSumm = data.totalCollectedMoney.cc*percent
        cashSumm = data.totalCollectedMoney.cash*percent

        $(tipOutLine).find(".cc_summ").text(ccSumm.toFixed(2))
        $(tipOutLine).find(".cash_summ").text(cashSumm.toFixed(2))

      $("#tip-out #given-tipouts-table .total .cc_summ").text(givenTipOutsTotalMoneyCC.toFixed(2))
      $("#tip-out #given-tipouts-table .total .cash_summ").text(givenTipOutsTotalMoneyCash.toFixed(2))

      receivedTipOutsCc = _.map($("#tip-out #received-tipouts-table tbody tr .cc-received"), (num) -> return parseFloat($(num).text()) )
      receivedTipOutsTotalCc = _.reduce(receivedTipOutsCc, (sum, num) -> return sum + num ) || 0
      receivedTipOutsTotalCc = parseFloat(receivedTipOutsTotalCc)

      receivedTipOutsCash = _.map($("#tip-out #received-tipouts-table tbody tr .cash-received"), (num) -> return parseFloat($(num).text()) )
      receivedTipOutsTotalCash = _.reduce(receivedTipOutsCash, (sum, num) -> return sum + num ) || 0
      receivedTipOutsTotalCash = parseFloat(receivedTipOutsTotalCash)

      {
        givenTipOutsTotalPercents: givenTipOutsTotalPercents,
        given: {
          cc: givenTipOutsTotalMoneyCC || 0,
          cash: givenTipOutsTotalMoneyCash || 0
        },
        received: {
          cc: receivedTipOutsTotalCc || 0,
          cash: receivedTipOutsTotalCash || 0
        }
      }

    buildFinalDistributionMoney: (data) ->
      {
        cc: data.totalCollectedMoney.cc - data.tipOuts.given.cc + data.tipOuts.received.cc,
        cash: data.totalCollectedMoney.cash - data.tipOuts.given.cash + data.tipOuts.received.cash
      }

    buildPercentsPart: (data) ->
      collectedMoneyDistributePercents = (100 - data.tipOuts.givenTipOutsTotalPercents)
      collectedMoneyDistributePercents/100

    buildTips: () ->
      tips = {
        given: {}
      }

      for tr in $("#given-tipouts-table").find(".tip-out-line")
        tips.given[$(tr).attr("data-area-name")] = {
          area_type_id: $(tr).find(".area-id").val(),
          shift_type_id: $(tr).find(".shift-type-id").val(),
          status: $(tr).attr("data-tip-out-status"),
          id: $(tr).attr("data-tip-out-id"),
          percentage: $(tr).find(".tip-out-percentage").val(),
        }

      tips

    buildPercentage: () ->    
      percentage = {}

      if @distribution_type() == "percents"
        for positionLine in $(".total-position-tips")
          percentage[$(positionLine).find(".percentage-point").attr("data-percent-distribution-id")] = $(positionLine).find(".percentage-point").attr("percentage-final-value")
      else
        for positionLine in $(".total-position-tips")
          percentage[$(positionLine).find(".percentage-point").attr("data-percent-distribution-id")] = $(positionLine).find(".percentage-point").val()

      percentage

    buildData: (params) ->
      @data = {
        calculationId: gon.calculation_id,
        distribution_type: @distribution_type(),
        totalHoursWorked: @totalHoursWorked(),
        totalSales: @totalSales()
      }

      @data.newCalculationParams = Tipcalc.Controllers.calculationFormView.getNewPositionsAndTeams() if params and params.updateCalculationRequired

      # tip outs to other calculations
      @data.tips = @buildTips()

      # data from percent tables
      @data.percentage = @buildPercentage()

      # Pos totals
      @data.posTotals = @buildPosTotals()

      # Total money collected for this shift
      @data.totalCollectedMoney = @buildTotalCollectedMoney()

      # Tip outs
      @data.tipOuts = @buildTipOuts(@data)

      # Total money to distribute (including tip outs received and given)
      @data.finalToDistribute = @buildFinalDistributionMoney(@data)

      # How much money to distribute after subtract
      @data.collectedMoneyDistributePercentsPart = @buildPercentsPart(@data)

      # Distribution type vased calculations
      if @distribution_type() == "percents"
        Tipcalc.Modules.calculationPercentsHelper.processPercents(@data, @)
      else
        Tipcalc.Modules.calculationPercentsHelper.processPoints(@data, @)
      
      @data

    # =============================== #
    # Validations
    # =============================== #

    # Here we if distribution summs distributed to employees via calculations equal to numbers that are displayed on a page
    varianceCheck: ->
      allowedVariance = 0.01

      ccMap = _.map($("[data-table-type='employee-distribution'] .total-tips-distributed-cc h4"), (num) -> return parseFloat($(num).text()) )
      ccToDistributeTotalSum = _.reduce(ccMap, (sum, num) -> return sum + num ) || 0
      ccToDistributeTotalSum = ccToDistributeTotalSum.toFixed(2)
      $(".tips-to-distribute-cc").text(ccToDistributeTotalSum)

      cashMap = _.map($("[data-table-type='employee-distribution'] .total-tips-distributed-cash h4"), (num) -> return parseFloat($(num).text()) )
      cashToDistributeTotalSum = _.reduce(cashMap, (sum, num) -> return sum + num ) || 0
      cashToDistributeTotalSum = cashToDistributeTotalSum.toFixed(2)
      $(".tips-to-distribute-cash").text(cashToDistributeTotalSum)

      distributedCc = parseFloat($(".tips-distributed-cc").text()).toFixed(2)
      distributedCash = parseFloat($(".tips-distributed-cash").text()).toFixed(2)

      numbersAreAlmostEqual = Math.abs(distributedCc - ccToDistributeTotalSum).toFixed(2) <= allowedVariance and Math.abs(distributedCash - cashToDistributeTotalSum).toFixed(2) <= allowedVariance
      noPendingDistributions = $("#pending-distributions-view table tbody tr").length is 0

      if numbersAreAlmostEqual and noPendingDistributions
        varianceStatus = "yes"
      else
        varianceStatus = "no"

      $(".variance-status").attr("data-variance-status", varianceStatus)

  )

  $(document).ready ->
    if $("body").hasClass("calculation")
      Tipcalc.Controllers.calculationView = new CalculationView()
)()
