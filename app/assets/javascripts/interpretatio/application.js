// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require_tree .
  


  jQuery.ajaxSetup({
  	'beforeSend': function(xhr) {xhr.setRequestHeader("Accept", "text/javascript")}
  })
  
  // Must use BOTH removeClass and fadeIn if ever there is Bootstrap around
  function notify_me(txt) {
  	$('#notices').html(txt);
    $('#notices').fadeIn().removeClass('hidden').delay(7000).fadeOut();
      };
    
  $(document).ready( function() {
    // $('#notices').hide()
    if ($('#flash_error').text() != '') {$('#flash_error').fadeIn().removeClass('hidden').delay(7000).fadeOut()};
    if ($('#flash_notice').text() != '') {$('#flash_notice').fadeIn().removeClass('hidden').delay(3000).fadeOut()};
    if ($('#flash_warning').text() != '') {$('#flash_warning').fadeIn().removeClass('hidden').delay(4000).fadeOut()};
  });

