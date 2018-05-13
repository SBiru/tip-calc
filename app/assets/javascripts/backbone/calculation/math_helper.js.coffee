(->
  class CalculationPercentsHelper
    processPoints: (data, scope) ->
      @data = data

      # totalPoints = add each position tables * all hours * hour value
      totalPointsSumm = scope.totalPoints()

      totalCalculationHoursMap = _.map($(".employee-distribution-line .number-hrs"), (num) -> return parseFloat($(num).val()) )
      totalCalculationHourSumm = _.reduce(totalCalculationHoursMap, (sum, num) -> return sum + num ) || 0

      @data.initialPointsHourPrice = {
        cc: @data.totalCollectedMoney.cc/totalPointsSumm,
        cash: @data.totalCollectedMoney.cash/totalPointsSumm
      }

      @data.totalPointsSumm = totalPointsSumm

      _.each $("[data-table-type='employee-distribution']"), (empDistrTable) =>
        positionType = $(empDistrTable).attr("data-position-table")
        positionTypeIsASource = $(empDistrTable).attr("data-position-is-a-source")
        positionTeamsCount = $("[data-table-type='employee-distribution'][data-position-table=\"#{ positionType }\"]").length  || 0
        teamNumber = $(empDistrTable).attr("data-team")
        hoursMap = _.map($(empDistrTable).find(".employee-distribution-line .number-hrs"), (num) -> return parseFloat($(num).val()) )
        totalHoursForPosition = _.reduce(hoursMap, (sum, num) -> return sum + num ) || 0
        salesMap = _.map($(empDistrTable).find(".employee-distribution-line .sales-summ input"), (num) -> return parseFloat($(num).val()) )
        totalSalesForPosition = _.reduce(salesMap, (sum, num) -> return sum + num ) || 0
        positionPoints = ($("#positions-table input[data-percentage-for=\"#{positionType}\"]").val()) || 0
        positionTotalPoints = positionPoints * totalHoursForPosition
        totalPositionHoursWorked = totalHoursForPosition

        @data.positionsMoney ||= {}
        @data.positionsMoney[positionType] ||= {
          positionTypeIsASource: positionTypeIsASource,
          positionTeamsCount: positionTeamsCount,
          totalHoursForPosition: totalHoursForPosition,
          positionPoints: positionPoints,
          positionTotalPoints: positionTotalPoints,
          totalSalesForPosition: totalSalesForPosition
        }
        @data.positionsMoney[positionType].totalPositionMoney = {
          cc: ((@data.totalCollectedMoney.cc/totalPointsSumm) * positionTotalPoints) || 0,
          cash: ((@data.totalCollectedMoney.cash/totalPointsSumm) * positionTotalPoints) || 0
        }
        @data.positionsMoney[positionType].totalPositionMoneyToShow = {
          cc: ((@data.totalCollectedMoney.cc/totalPointsSumm) * positionTotalPoints * @data.collectedMoneyDistributePercentsPart) || 0,
          cash: ((@data.totalCollectedMoney.cash/totalPointsSumm) * positionTotalPoints * @data.collectedMoneyDistributePercentsPart) || 0
        }

        # Calculate team % to another teams
        # =================================================================

        @data.positionsMoney[positionType].teams ||= {}

        if positionTypeIsASource == "true"

          ccTeamMap = _.map($(empDistrTable).find(".employee-distribution-line .cc-in input"), (num) -> return parseFloat($(num).val()) )
          ccTeamTotalSum = _.reduce(ccTeamMap, (sum, num) -> return sum + num) || 0

          cashTeamMap = _.map($(empDistrTable).find(".employee-distribution-line .cash-in input"), (num) -> return parseFloat($(num).val()) )
          cashTeamTotalSum = _.reduce(cashTeamMap, (sum, num) -> return sum + num ) || 0

          totalTeamCollectedMoney = {
            cc: parseFloat(ccTeamTotalSum),
            cash: parseFloat(cashTeamTotalSum)
          }

          totalTeamMoneyToDistribute = {
            cc: ((totalTeamCollectedMoney.cc/totalPointsSumm) * positionTotalPoints),
            cash: ((totalTeamCollectedMoney.cash/totalPointsSumm) * positionTotalPoints)
          }

          @data.positionsMoney[positionType].teams[teamNumber] = {
            totalTeamCollectedMoney: totalTeamCollectedMoney
            totalTeamMoneyToDistribute: totalTeamMoneyToDistribute
          }
        else
          @data.positionsMoney[positionType].teams[teamNumber] = {
            totalTeamMoneyToDistribute: @data.positionsMoney[positionType].totalPositionMoney
          }

        # 1 workig hour's price
        # =================================================================

        hourPrice = @data.initialPointsHourPrice
        @data.positionsMoney[positionType].teams[teamNumber].hourPrice = @data.initialPointsHourPrice

        # Employee distributions
        # =================================================================

        @data.positionsMoney[positionType].teams[teamNumber].employees = {}

        _.each $(empDistrTable).find(".employee-distribution-line"), (empDistrTableLine) =>
          salesSumm = parseFloat($(empDistrTableLine).find(".sales-summ input").val() || 0)
          hoursWorkedInHours = parseFloat($(empDistrTableLine).find(".number-hrs").val() || 0)
          id = $(empDistrTableLine).find(".employee-id").val()
          empDistrId = $(empDistrTableLine).attr("data-emp-distribution-id")
          empDistrStatus = $(empDistrTableLine).attr("data-emp-distribution-status")
          employeePointsPart = (hoursWorkedInHours*positionPoints)/(totalPointsSumm) || 0

          @data.positionsMoney[positionType].teams[teamNumber].employees[id] = {
            salesSumm: salesSumm,
            hoursWorkedInHours: hoursWorkedInHours,
            distributionStatus: empDistrStatus,
            distributionId: empDistrId,
            totalMoneyIn: {
              cc: $(empDistrTableLine).find(".cc-in input").val() || 0,
              cash: $(empDistrTableLine).find(".cash-in input").val() || 0
            },
            totalMoneyOut: {
              cc: (hourPrice.cc*hoursWorkedInHours*positionPoints) || 0,
              cash: (hourPrice.cash*hoursWorkedInHours*positionPoints) || 0
            }
          }

          @data.positionsMoney[positionType].teams[teamNumber].employees[id].employeePointsPart = employeePointsPart

          #sent
          totalTipOutsGivenCC = employeePointsPart * @data.tipOuts.givenTipOutsTotalPercents * @data.totalCollectedMoney.cc * 1/100
          totalTipOutsGivenCash = employeePointsPart * @data.tipOuts.givenTipOutsTotalPercents * @data.totalCollectedMoney.cash * 1/100

          @data.positionsMoney[positionType].teams[teamNumber].employees[id].totalTipOutsGiven = {
            cc: totalTipOutsGivenCC || 0,
            cash: totalTipOutsGivenCash || 0
          }

          #received
          totalTipOutsReceivedCC = employeePointsPart * @data.tipOuts.received.cc
          totalTipOutsReceivedCash = employeePointsPart * @data.tipOuts.received.cash

          @data.positionsMoney[positionType].teams[teamNumber].employees[id].totalTipOutsReceived = {
            cc: totalTipOutsReceivedCC || 0,
            cash: totalTipOutsReceivedCash || 0
          }

          @data.positionsMoney[positionType].teams[teamNumber].employees[id].finalMoneyToDistribute = {
            cc: ((@data.totalCollectedMoney.cc*employeePointsPart) + totalTipOutsReceivedCC - totalTipOutsGivenCC) || 0,
            cash: ((@data.totalCollectedMoney.cash*employeePointsPart) + totalTipOutsReceivedCash - totalTipOutsGivenCash) || 0
          }

        # Total money to distribute for the team
        # =================================================================

        totalPositionHoursWorked = {}

        totalPositionHoursWorked = _.map(@data.positionsMoney[positionType].teams[teamNumber].employees, (data, id) -> return parseFloat(data.hoursWorkedInHours) )
        totalPositionHoursWorked = _.reduce(totalPositionHoursWorked, (sum, num) -> return sum + num ) || 0

        # Total sales for the team
        # =================================================================

        totalTeamSales = {}

        totalTeamSales = _.map(@data.positionsMoney[positionType].teams[teamNumber].employees, (data, id) -> return parseFloat(data.salesSumm) )
        totalTeamSales = _.reduce(totalTeamSales, (sum, num) -> return sum + num ) || 0


        # Total money to distribute for the team
        # =================================================================

        totalMoneyToDistribute = {}

        totalMoneyToDistribute.cc = _.map(@data.positionsMoney[positionType].teams[teamNumber].employees, (data, id) -> return (data.totalMoneyOut.cc) )
        totalMoneyToDistribute.cc = _.reduce(totalMoneyToDistribute.cc, (sum, num) -> return sum + num ) || 0

        totalMoneyToDistribute.cash = _.map(@data.positionsMoney[positionType].teams[teamNumber].employees, (data, id) -> return (data.totalMoneyOut.cash) )
        totalMoneyToDistribute.cash = _.reduce(totalMoneyToDistribute.cash, (sum, num) -> return sum + num ) || 0

        # totalIptoutsGiven

        totalTeamTOGivenCC= _.map(@data.positionsMoney[positionType].teams[teamNumber].employees, (data, id) -> return (data.totalTipOutsGiven.cc) )
        totalTeamTOGivenCC = _.reduce(totalTeamTOGivenCC, (sum, num) -> return sum + num ) || 0
        totalTeamTOGivenCash= _.map(@data.positionsMoney[positionType].teams[teamNumber].employees, (data, id) -> return (data.totalTipOutsGiven.cash) )
        totalTeamTOGivenCash = _.reduce(totalTeamTOGivenCash, (sum, num) -> return sum + num ) || 0

        # totalIptoutsReceived

        totalTeamTOReceivedCC= _.map(@data.positionsMoney[positionType].teams[teamNumber].employees, (data, id) -> return (data.totalTipOutsReceived.cc) )
        totalTeamTOReceivedCC = _.reduce(totalTeamTOReceivedCC, (sum, num) -> return sum + num ) || 0
        totalTeamTOReceivedCash= _.map(@data.positionsMoney[positionType].teams[teamNumber].employees, (data, id) -> return (data.totalTipOutsReceived.cash) )
        totalTeamTOReceivedCash = _.reduce(totalTeamTOReceivedCash, (sum, num) -> return sum + num ) || 0

        # distributionsFinal

        finalTeamTODistributeCC= _.map(@data.positionsMoney[positionType].teams[teamNumber].employees, (data, id) -> return (data.finalMoneyToDistribute.cc) )
        finalTeamTODistributeCC = _.reduce(finalTeamTODistributeCC, (sum, num) -> return sum + num ) || 0
        finalTeamTODistributeCash= _.map(@data.positionsMoney[positionType].teams[teamNumber].employees, (data, id) -> return (data.finalMoneyToDistribute.cash) )
        finalTeamTODistributeCash = _.reduce(finalTeamTODistributeCash, (sum, num) -> return sum + num ) || 0

        @data.positionsMoney[positionType].teams[teamNumber].teamTotal = {
          totalTeamSales: totalTeamSales || 0,
          totalPositionHoursWorked: totalPositionHoursWorked || 0,
          ccToDistribute: totalMoneyToDistribute.cc || 0,
          cashToDistribute: totalMoneyToDistribute.cash || 0,
          totalTeamTOGivenCC: totalTeamTOGivenCC || 0,
          totalTeamTOGivenCash: totalTeamTOGivenCash || 0,
          totalTeamTOReceivedCC: totalTeamTOReceivedCC || 0,
          totalTeamTOReceivedCash: totalTeamTOReceivedCash || 0,
          finalTeamTODistributeCC: finalTeamTODistributeCC || 0,
          finalTeamTODistributeCash: finalTeamTODistributeCash || 0
        }

      @data
    processPercents: (data, scope) ->
      @data = data

      _.each $("[data-table-type='employee-distribution']"), (empDistrTable) =>
        positionType = $(empDistrTable).attr("data-position-table")
        positionTypeIsASource = $(empDistrTable).attr("data-position-is-a-source")
        positionPercentage = parseFloat($("#positions-table input[data-percentage-for=\"#{positionType}\"]").attr("percentage-final-value")) || 0
        positionTeamsCount = $("[data-table-type='employee-distribution'][data-position-table=\"#{ positionType }\"]").length  || 0
        teamNumber = $(empDistrTable).attr("data-team")
        salesMap = _.map($(empDistrTable).find(".employee-distribution-line .sales-summ input"), (num) -> return parseFloat($(num).val()) )
        totalSalesForPosition = _.reduce(salesMap, (sum, num) -> return sum + num ) || 0

        # Total money collected for this shift
        # =================================================================

        ccPositionMap = _.map(scope.positionDistrTables(positionType).find(".employee-distribution-line .cc-in input"), (num) -> return parseFloat($(num).val()) )
        ccPositionTotalSum = _.reduce(ccPositionMap, (sum, num) -> return sum + num ) || 0

        cashPositionMap = _.map(scope.positionDistrTables(positionType).find(".employee-distribution-line .cash-in input"), (num) -> return parseFloat($(num).val()) )
        cashPositionTotalSum = _.reduce(cashPositionMap, (sum, num) -> return sum + num ) || 0

        @data.totalPositionCollectedMoney = {
          cc: ccPositionTotalSum,
          cash: cashPositionTotalSum
        }

        @data.positionsMoney ||= {}
        @data.positionsMoney[positionType] ||= {
          positionTypeIsASource: positionTypeIsASource,
          positionPercentage: positionPercentage,
          positionTeamsCount: positionTeamsCount,
          totalSalesForPosition: totalSalesForPosition
        }
        @data.positionsMoney[positionType].totalPositionMoney = {
          cc: (@data.totalCollectedMoney.cc * positionPercentage)/100,
          cash: (@data.totalCollectedMoney.cash * positionPercentage)/100
        }
        @data.positionsMoney[positionType].totalPositionMoneyToShow = {
          cc: (@data.totalCollectedMoney.cc * positionPercentage * @data.collectedMoneyDistributePercentsPart)/100,
          cash: (@data.totalCollectedMoney.cash * positionPercentage * @data.collectedMoneyDistributePercentsPart)/100
        }

        # Calculate team % to another teams
        # =================================================================

        @data.positionsMoney[positionType].teams ||= {}

        if positionTypeIsASource == "true"

          ccTeamMap = _.map($(empDistrTable).find(".employee-distribution-line .cc-in input"), (num) -> return parseFloat($(num).val()) )
          ccTeamTotalSum = _.reduce(ccTeamMap, (sum, num) -> return sum + num) || 0

          cashTeamMap = _.map($(empDistrTable).find(".employee-distribution-line .cash-in input"), (num) -> return parseFloat($(num).val()) )
          cashTeamTotalSum = _.reduce(cashTeamMap, (sum, num) -> return sum + num ) || 0

          totalTeamCollectedMoney = {
            cc: parseFloat(ccTeamTotalSum),
            cash: parseFloat(cashTeamTotalSum)
          }

          if positionTeamsCount is 1
            teamPart = {
              cc: 1,
              cash: 1
            }
          else
            teamPart = {
              cc: totalTeamCollectedMoney.cc/@data.totalPositionCollectedMoney.cc,
              cash: totalTeamCollectedMoney.cash/@data.totalPositionCollectedMoney.cash
            }

          totalTeamMoneyToDistribute = {
            cc: (@data.totalCollectedMoney.cc * positionPercentage * teamPart.cc)/100,
            cash: (@data.totalCollectedMoney.cash * positionPercentage * teamPart.cash)/100
          }

          @data.positionsMoney[positionType].teams[teamNumber] = {
            totalTeamCollectedMoney: totalTeamCollectedMoney
            totalTeamMoneyToDistribute: totalTeamMoneyToDistribute
          }

        else
          @data.positionsMoney[positionType].teams[teamNumber] = {
            totalTeamMoneyToDistribute: @data.positionsMoney[positionType].totalPositionMoney
          }

        # 1 workig hour's price
        # =================================================================

        hoursMap = _.map($(empDistrTable).find(".employee-distribution-line .number-hrs"), (num) -> return parseFloat($(num).val()) )
        totalHoursForPosition = _.reduce(hoursMap, (sum, num) -> return sum + num ) || 0

        hourPrice = {
          cc: (@data.positionsMoney[positionType].teams[teamNumber].totalTeamMoneyToDistribute.cc/totalHoursForPosition) || 0,
          cash: (@data.positionsMoney[positionType].teams[teamNumber].totalTeamMoneyToDistribute.cash/totalHoursForPosition) || 0
        }

        @data.positionsMoney[positionType].teams[teamNumber].hourPrice = hourPrice

        # Empoyee distributions
        # =================================================================

        @data.positionsMoney[positionType].teams[teamNumber].hourPrice = hourPrice
        @data.positionsMoney[positionType].teams[teamNumber].employees = {}

        _.each $(empDistrTable).find(".employee-distribution-line"), (empDistrTableLine) =>
          salesSumm = parseFloat($(empDistrTableLine).find(".sales-summ input").val() || 0)
          hoursWorkedInHours = parseFloat($(empDistrTableLine).find(".number-hrs").val() || 0)
          id = $(empDistrTableLine).find(".employee-id").val()
          empDistrId = $(empDistrTableLine).attr("data-emp-distribution-id")
          empDistrStatus = $(empDistrTableLine).attr("data-emp-distribution-status")

          @data.positionsMoney[positionType].teams[teamNumber].employees[id] = {
            salesSumm: salesSumm,
            hoursWorkedInHours: hoursWorkedInHours,
            distributionStatus: empDistrStatus,
            distributionId: empDistrId,
            totalMoneyIn: {
              cc: $(empDistrTableLine).find(".cc-in input").val() || 0,
              cash: $(empDistrTableLine).find(".cash-in input").val() || 0
            },
            totalMoneyOut: {
              cc: (hourPrice.cc*hoursWorkedInHours) || 0,
              cash: (hourPrice.cash*hoursWorkedInHours) || 0
            }
          }

          #sent

          totalTipOutsGivenCC = (((hourPrice.cc*hoursWorkedInHours)*@data.tipOuts.given.cc)/@data.totalCollectedMoney.cc) || 0
          totalTipOutsGivenCash = (((hourPrice.cash*hoursWorkedInHours)*@data.tipOuts.given.cash)/@data.totalCollectedMoney.cash) || 0

          @data.positionsMoney[positionType].teams[teamNumber].employees[id].totalTipOutsGiven = {
            cc: totalTipOutsGivenCC || 0,
            cash: totalTipOutsGivenCash || 0
          }

          #received
          totalTipOutsReceivedCC = (@data.tipOuts.received.cc * ( positionPercentage * (1/100) * hoursWorkedInHours/totalHoursForPosition ))/positionTeamsCount
          totalTipOutsReceivedCash = (@data.tipOuts.received.cash * ( positionPercentage * (1/100) * hoursWorkedInHours/totalHoursForPosition ))/positionTeamsCount

          @data.positionsMoney[positionType].teams[teamNumber].employees[id].totalTipOutsReceived = {
            cc: totalTipOutsReceivedCC || 0,
            cash: totalTipOutsReceivedCash || 0
          }

          @data.positionsMoney[positionType].teams[teamNumber].employees[id].finalMoneyToDistribute = {
            cc: ((hourPrice.cc*hoursWorkedInHours) + totalTipOutsReceivedCC - totalTipOutsGivenCC) || 0,
            cash: ((hourPrice.cash*hoursWorkedInHours) + totalTipOutsReceivedCash - totalTipOutsGivenCash) || 0
          }

        # Total money to distribute for the team
        # =================================================================

        totalPositionHoursWorked = {}

        totalPositionHoursWorked = _.map(@data.positionsMoney[positionType].teams[teamNumber].employees, (data, id) -> return parseFloat(data.hoursWorkedInHours) )
        totalPositionHoursWorked = _.reduce(totalPositionHoursWorked, (sum, num) -> return sum + num ) || 0

        # Total sales for the team
        # =================================================================

        totalTeamSales = {}

        totalTeamSales = _.map(@data.positionsMoney[positionType].teams[teamNumber].employees, (data, id) -> return parseFloat(data.salesSumm) )
        totalTeamSales = _.reduce(totalTeamSales, (sum, num) -> return sum + num ) || 0

        # Total money to distribute for the team
        # =================================================================

        totalMoneyToDistribute = {}

        totalMoneyToDistribute.cc = _.map(@data.positionsMoney[positionType].teams[teamNumber].employees, (data, id) -> return parseFloat(data.totalMoneyOut.cc) )
        totalMoneyToDistribute.cc = _.reduce(totalMoneyToDistribute.cc, (sum, num) -> return sum + num ) || 0

        totalMoneyToDistribute.cash = _.map(@data.positionsMoney[positionType].teams[teamNumber].employees, (data, id) -> return parseFloat(data.totalMoneyOut.cash) )
        totalMoneyToDistribute.cash = _.reduce(totalMoneyToDistribute.cash, (sum, num) -> return sum + num ) || 0

        # totalIptoutsGiven

        totalTeamTOGivenCC= _.map(@data.positionsMoney[positionType].teams[teamNumber].employees, (data, id) -> return parseFloat(data.totalTipOutsGiven.cc) )
        totalTeamTOGivenCC = _.reduce(totalTeamTOGivenCC, (sum, num) -> return sum + num ) || 0
        totalTeamTOGivenCash= _.map(@data.positionsMoney[positionType].teams[teamNumber].employees, (data, id) -> return parseFloat(data.totalTipOutsGiven.cash) )
        totalTeamTOGivenCash = _.reduce(totalTeamTOGivenCash, (sum, num) -> return sum + num ) || 0

        # totalIptoutsReceived

        totalTeamTOReceivedCC= _.map(@data.positionsMoney[positionType].teams[teamNumber].employees, (data, id) -> return parseFloat(data.totalTipOutsReceived.cc) )
        totalTeamTOReceivedCC = _.reduce(totalTeamTOReceivedCC, (sum, num) -> return sum + num ) || 0
        totalTeamTOReceivedCash= _.map(@data.positionsMoney[positionType].teams[teamNumber].employees, (data, id) -> return parseFloat(data.totalTipOutsReceived.cash) )
        totalTeamTOReceivedCash = _.reduce(totalTeamTOReceivedCash, (sum, num) -> return sum + num ) || 0

        # distributionsFinal

        finalTeamTODistributeCC= _.map(@data.positionsMoney[positionType].teams[teamNumber].employees, (data, id) -> return parseFloat(data.finalMoneyToDistribute.cc) )
        finalTeamTODistributeCC = _.reduce(finalTeamTODistributeCC, (sum, num) -> return sum + num ) || 0
        finalTeamTODistributeCash= _.map(@data.positionsMoney[positionType].teams[teamNumber].employees, (data, id) -> return parseFloat(data.finalMoneyToDistribute.cash) )
        finalTeamTODistributeCash = _.reduce(finalTeamTODistributeCash, (sum, num) -> return sum + num ) || 0

        @data.positionsMoney[positionType].teams[teamNumber].teamTotal = {
          totalTeamSales: totalTeamSales || 0,
          totalPositionHoursWorked: totalPositionHoursWorked || 0,
          ccToDistribute: totalMoneyToDistribute.cc || 0,
          cashToDistribute: totalMoneyToDistribute.cash || 0,
          totalTeamTOGivenCC: totalTeamTOGivenCC || 0,
          totalTeamTOGivenCash: totalTeamTOGivenCash || 0,
          totalTeamTOReceivedCC: totalTeamTOReceivedCC || 0,
          totalTeamTOReceivedCash: totalTeamTOReceivedCash || 0,
          finalTeamTODistributeCC: finalTeamTODistributeCC || 0,
          finalTeamTODistributeCash: finalTeamTODistributeCash || 0
        }
      
      @data

  Tipcalc.Modules.calculationPercentsHelper = new CalculationPercentsHelper

)()