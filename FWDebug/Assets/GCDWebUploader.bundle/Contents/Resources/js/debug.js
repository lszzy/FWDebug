
var _path = null;
var _pendingReloads = [];
var _reloadingDisabled = 0;
var _interval = true;
var _intervalId = null;
var _page = 1;
var _perpage = 10;

function _copyText() {
    var element = document.getElementById("copy-textarea");
    element.select();
    document.execCommand('Copy');
    
    $("#alerts").prepend(tmpl("template-alert", {
      level: "success",
      title: "Copy Successful",
      description: ""
    }));
    setTimeout(function() {
      $('#alert-close').alert('close');
    }, 2000);
}

function _setInterval(time) {
  if (_intervalId != null) {
    clearInterval(_intervalId);
  }
  _intervalId = setInterval(function() {
    if (_interval) {
      _reload(_path);
    }
  }, time);
}

function _disableReloads() {
  _reloadingDisabled += 1;
}

function _enableReloads() {
  _reloadingDisabled -= 1;
  
  if (_pendingReloads.length > 0) {
    _reload(_pendingReloads.shift());
  }
}

function _reload(path) {
  if (_reloadingDisabled) {
    if ($.inArray(path, _pendingReloads) < 0) {
      _pendingReloads.push(path);
    }
    return;
  }
  
  _disableReloads();
  $.ajax({
    url: 'list',
    type: 'GET',
    data: {path: path, page: _page, perpage: _perpage, keywords: _keywords},
    dataType: 'json'
  }).fail(function(jqXHR, textStatus, errorThrown) {
  }).done(function(data, textStatus, jqXHR) {
    var scrollPosition = $(document).scrollTop();
    
    if (path != _path) {
      $("#path").empty();
      if (path == "/") {
        $("#path").append('<li class="active">' + _device + '</li>');
      } else {
        $("#path").append('<li data-path="/"><a>' + _device + '</a></li>');
        var components = path.split("/").slice(1, -1);
        for (var i = 0; i < components.length - 1; ++i) {
          var subpath = "/" + components.slice(0, i + 1).join("/") + "/";
          $("#path").append('<li data-path="' + subpath + '"><a>' + components[i] + '</a></li>');
        }
        $("#path > li").click(function(event) {
          _reload($(this).data("path"));
          event.preventDefault();
        });
        $("#path").append('<li class="active">' + components[components.length - 1] + '</li>');
      }
      _path = path;
    }
    
    $("#listing").empty();
    for (var i = 0, file; file = data.list[i]; ++i) {
      $(tmpl("template-listing", file)).data(file).appendTo("#listing");
    }
    $("#total").text(data.total);
    if (data.prev) {
      $("#previous").addClass("show").removeClass("hidden");
    } else {
      $("#previous").addClass("hidden").removeClass("show");
    }
    if (data.next) {
      $("#next").addClass("show").removeClass("hidden");
    } else {
      $("#next").addClass("hidden").removeClass("show");
    }
    
    $(".button-copy").click(function(event) {
      var path = $(this).parent().parent().data("path");
      $("#copy-textarea").val(path);
      _copyText();
    });
    
    $(".button-share").click(function(event) {
      var path = $(this).parent().parent().data("path");
      $("#copy-text").text(path);
      $("#copy-textarea").val(path);
      $("#share-modal").modal("show");
    });
    
    $(document).scrollTop(scrollPosition);
  }).always(function() {
    _enableReloads();
  });
}

$(document).ready(function() {
  
  $("#copy-confirm").click(function(event) {
    $("#share-modal").modal("hide");
    _copyText();
  });
  
  $("#reload").click(function(event) {
    _reload(_path);
  });
    
  $("#previous").click(function(event) {
    _page = _page - 1;
    _reload(_path);
    event.preventDefault();
  });

  $("#next").click(function(event) {
    _page = _page + 1;
    _reload(_path);
    event.preventDefault();
  });
  
  $("#interval-toggle").click(function(event) {
    _interval = !_interval;
    $("#interval-toggle").text(_interval ? "Interval Off" : "Interval On");
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
    
  $("#page-10").click(function(event) {
    _perpage = 10;
    _page = 1;
    _reload(_path);
    event.preventDefault();
  });
    
  $("#page-20").click(function(event) {
    _perpage = 20;
    _page = 1;
    _reload(_path);
    event.preventDefault();
  });
  
  $("#page-50").click(function(event) {
    _perpage = 50;
    _page = 1;
    _reload(_path);
    event.preventDefault();
  });

  _reload("/");
  
  _setInterval(5000);
  
});
