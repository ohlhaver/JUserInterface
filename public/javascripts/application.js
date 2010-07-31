// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function showMouseOvers( event ){
  event = event || window.event;
  showMouseOverData( event, '.mo_icon', 'inline' );
  showMouseOverData( event, '.mo_menu', 'block' );
  showMouseOverData( event, '.mo_dialog', 'inline');
}
function hideMouseOvers( event ){
  event = event || window.event;
  hideMouseOverData( event, '.mo_icon' );
  hideMouseOverData( event, '.mo_menu' );
  hideMouseOverData( event, '.mo_dialog' );
}
/* Navigation MouseOvers uses display block for now */
function showNavigationMouseOvers( event ){
  event = event || window.event;
  showMouseOverData( event, '.mo_dialog', 'block');
}
function hideNavigationMouseOvers( event ){
  event = event || window.event;
  hideMouseOverData( event, '.mo_dialog');
}
function showMouseOverData(event, class_name, display_style ){
  event = event || window.event;
  var target = event.findElement( class_name + '_event_src' );
  if( target ) { 
    var element = target.getElementsBySelector( class_name ).first();
    if( element ) element.setStyle({display:display_style});
  }
}
function hideMouseOverData(event, class_name ) {
  event = event || window.event;
  var target = event.findElement( class_name + '_event_src' );
  if( target ) {
    var element = target.getElementsBySelector( class_name ).first();
    if( element ) element.setStyle({display:'none'});
  }
}
function thumbs_up_highlight( elem ){
  var img1 = $(elem).getElementsBySelector( 'span.img1' ).first();
  var img2 = $(elem).getElementsBySelector( 'span.img2' ).first();
  if ( img1 != null && img2 != null ){
    Element.hide( img1 );
    Element.show( img2 );
  }
}
function thumbs_up_reset( elem ){
  var img1 = $(elem).getElementsBySelector( 'span.img1' ).first();
  var img2 = $(elem).getElementsBySelector( 'span.img2' ).first();
  if ( img1 != null && img2 != null ){
    Element.hide( img2 );
    Element.show( img1 );
  }
}