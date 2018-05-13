window.bindSelect2 = ->
  $( ".select-2" ).select2(theme: "bootstrap")

window.bindSelectTo = (element) ->
  $(element).select2(theme: 'bootstrap')

window.bindPercentSelect = ->
  $(".touch-spin").TouchSpin({
      postfix: "
        <span data-distribution-type-elements='percents'>%</span>
        <span data-distribution-type-elements='points'>pts</span>
      ",
      postfix_extraclass: "btn btn-default btn-xs",
      decimals: 2,
      step: 0.01
  })

window.bindCheckboxes = ->
  $('body.setup input[type=checkbox], body.dashboard input[type=checkbox]').iCheck(
    checkboxClass: 'icheckbox_square-green',
    radioClass: 'iradio_square-green'
  )

window.setBrowserSupport = ->
  if (navigator.userAgent.match(/OS X.*Safari/) && ! navigator.userAgent.match(/Chrome/))
    document.body.className += ' safari'

String.prototype.cleanup = ->
  this.replace(/[^a-zA-Z0-9]+/g, "");

$(document).ready ->
  if gon?
    $("#profileChart").sparkline(gon.total_collected_money_data, {
        type: 'bar',
        barWidth: 7,
        height: '30px',
        barColor: '#62cb31',
        negBarColor: '#53ac2a'
    });

  window.bindSelect2()
  window.bindPercentSelect();
  # window.bindHrsSelect();
  window.bindCheckboxes();
  window.setBrowserSupport();
