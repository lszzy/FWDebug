
var _interval = true;
var _intervalId = null;

function _setInterval(time) {
  if (_intervalId != null) {
    clearInterval(_intervalId);
  }
  _intervalId = setInterval(function() {
    if (_interval) {
      _reload();
    }
  }, time);
}

function _reload() {
  $("#image-view").attr("src", "/screenshot?t=" + Math.random());
}

$(document).ready(function() {
    
  $("#reload").click(function(event) {
    _reload();
    event.preventDefault();
  });
  
  $("#interval-toggle").click(function(event) {
    _interval = !_interval;
    $("#interval-toggle").text(_interval ? "Interval Off" : "Interval On");
    event.preventDefault();
  });

  $("#interval-2").click(function(event) {
    _interval = true;
    _setInterval(2000);
    event.preventDefault();
  });
  
  $("#interval-5").click(function(event) {
    _interval = true;
    _setInterval(5000);
    event.preventDefault();
  });
  
  $("#interval-10").click(function(event) {
    _interval = true;
    _setInterval(10000);
    event.preventDefault();
  });
  
  $("#interval-60").click(function(event) {
    _interval = true;
    _setInterval(60000);
    event.preventDefault();
  });
  
  $("#toggle").click(function(event) {
    $.ajax({
      url: 'settings',
      type: 'POST',
      data: {},
      dataType: 'json'
    }).done(function(data, textStatus, jqXHR) {
      if (data.debug) {
        $("#toggle-icon").addClass("glyphicon-off").removeClass("glyphicon-phone");
      } else {
        $("#toggle-icon").addClass("glyphicon-phone").removeClass("glyphicon-off");
      }
    });
    event.preventDefault();
  });

  _reload();
  
  _setInterval(5000);
  
});
