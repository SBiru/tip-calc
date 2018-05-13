

$( document ).ready(function() {

  "use strict";




/*----------------------------------
  add preloder
  -----------------------------------*/
  $(window).load(function(){
    $('.sk-folding-cube').fadeOut();
    $('#preloader').delay(200).fadeOut('slow');

  });

    
    



/*-------------------------
add form function
-------------------------*/

$('.field-input').focus(function(){
    $(this).parent().addClass('is-focused has-label');
  });

  $('.field-input').each(function(){
    if($(this).val() != ''){
      $(this).parent().addClass('has-label');
    }
  });

  $('.field-input').blur(function(){
     var $parent = $(this).parent();
    if($(this).val() == ''){
      $parent.removeClass('has-label');
    }
    $parent.removeClass('is-focused');
 });



  /*------------------------
  add ScrollTo.js function
  ------------------------*/
  smoothScroll.init({
    speed: 1000, 
    easing: 'easeOutQuart', // Easing pattern to use
    offset:0
  });











/*--------------------------------
add ajaxchimp
--------------------------------*/


  $('#subscription-form').ajaxChimp({
    url: $('#subscription-form').attr('action'),
    callback: function(response) {
      $('#subscription-message')
        .html(response.msg)
        .slideDown()
        .delay(5000)
        .slideUp();
    }
  });





  /*----------------------------------------------------------------------
   Bootstrap Internet Explorer 10 in Windows 8 and Windows Phone 8 FIX
  -----------------------------------------------------------------------*/
  if (navigator.userAgent.match(/IEMobile\/10\.0/)) {
    var msViewportStyle = document.createElement('style')
    msViewportStyle.appendChild(
      document.createTextNode(
        '@-ms-viewport{width:auto!important}'
      )
    )
    document.querySelector('head').appendChild(msViewportStyle)
  }

/*----------------------------------------------------------------------
end: Bootstrap Internet Explorer 10 in Windows 8 and Windows Phone 8 FIX
-----------------------------------------------------------------------*/ 



/*---------------------------
  add swicher(just for demo)
  ----------------------------*/

  var link = $('link.active');
  var sty = "./assets/css/color/";
  
  $('.swicher'). on("click",function() {
    link.attr('href', sty + $(this).data('file') + '.css');
  });
  
  /*-----swich trigger---*/
  $('.swich-icon').on("click",function() {
    $('.wraper-swicher').toggleClass('wraper-swicher-open');
  });


});
 






