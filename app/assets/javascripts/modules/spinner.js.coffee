@Tipcalc ||= {}
@Tipcalc.Controllers ||= {}
@Tipcalc.Modules ||= {}

@Tipcalc.Controllers.spinner = {
  show: ->
    $(".loader-spinner").show()
  hide: ->
    $(".loader-spinner").hide()
}