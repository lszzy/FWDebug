
var _path = null;
var _title = null;
var _pendingReloads = [];
var _reloadingDisabled = 0;
var _interval = true;
var _intervalId = null;
var _page = 1;
var _perpage = 10;
var _sortAsc = false;

function _showMessage(title) {
    $("#alerts").prepend(tmpl("template-alert", {
      level: "success",
      title: title,
      description: ""
    }));
    setTimeout(function() {
      $('#alert-close').alert('close');
    }, 2000);
}

function _copyText() {
    var element = document.getElementById("copy-textarea");
    element.select();
    document.execCommand('Copy');
    
    _showMessage("Copy Successful");
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
    url: path == "/" ? 'requests' : 'request',
    type: 'GET',
    data: {path: path, page: _page, perpage: _perpage, sort: _sortAsc ? 1 : 0, keywords: _keywords},
    dataType: 'json'
  }).done(function(data, textStatus, jqXHR) {
    var scrollPosition = $(document).scrollTop();
    
    if (path != _path) {
      $("#path").empty();
      if (path == "/") {
        $("#path").append('<li class="active">' + _device + '</li>');
      } else {
        $("#path").append('<li data-path="/"><a>' + _device + '</a></li>');
        $("#path > li").click(function(event) {
          _reload($(this).data("path"));
          event.preventDefault();
        });
        $("#path").append('<li class="active">' + _title + '</li>');
      }
      _path = path;
    }
    
    $("#listing").empty();
    for (var i = 0, file; file = data.list[i]; ++i) {
      $(tmpl("template-listing", file)).data(file).appendTo("#listing");
    }
    if (data.debug) {
      $("#toggle-icon").addClass("glyphicon-off").removeClass("glyphicon-phone");
    } else {
      $("#toggle-icon").addClass("glyphicon-phone").removeClass("glyphicon-off");
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
    if (data.pager) {
      $("#pager").addClass("show").removeClass("hidden");
    } else {
      $("#pager").addClass("hidden").removeClass("show");
    }
    
    $(".column-copy").click(function(event) {
      var copy = $(this).parent().data("copy");
      var fast = $(this).parent().data("fast");
      if (fast != null && fast != "") {
        $("#copy-textarea").val(fast);
      } else {
        $("#copy-textarea").val(copy);
      }
      _copyText();
    });
    
    $(".button-detail").click(function(event) {
      var path = $(this).parent().parent().data("path");
      _title = $(this).parent().parent().data("title");
      _reload(path);
    });
      
    $(".button-view").click(function(event) {
      var type = $(this).parent().parent().data("type");
      if (type == "link") {
        var path = $(this).parent().parent().data("path");
        window.open(path, "_blank");
      } else if (type == "image") {
        var path = $(this).parent().parent().data("path");
        var title = $(this).parent().parent().data("title");
        var copy = $(this).parent().parent().data("copy");
        $("#image-title").text(title);
        $("#image-view").attr("src", path);
        $("#copy-textarea").val(copy);
        $("#image-modal").modal("show");
      } else {
        var title = $(this).parent().parent().data("title");
        var copy = $(this).parent().parent().data("copy");
        $("#share-title").text(title);
        if (type == "json") {
          $("#share-pre").text(copy);
          $("#share-text").removeClass("show").addClass("hidden");
          $("#share-pre").removeClass("hidden").addClass("show");
        } else {
          $("#share-text").text(copy);
          $("#share-pre").removeClass("show").addClass("hidden");
          $("#share-text").removeClass("hidden").addClass("show");
        }
        $("#copy-textarea").val(copy);
        $("#share-modal").modal("show");
      }
    });
    
    $(".button-share").click(function(event) {
      var title = $(this).parent().parent().data("title");
      var copy = $(this).parent().parent().data("copy");
      var type = $(this).parent().parent().data("type");
      $("#share-title").text(title);
      if (type != null && type == "json") {
        $("#share-pre").text(copy);
        $("#share-text").removeClass("show").addClass("hidden");
        $("#share-pre").removeClass("hidden").addClass("show");
      } else {
        $("#share-text").text(copy);
        $("#share-pre").removeClass("show").addClass("hidden");
        $("#share-text").removeClass("hidden").addClass("show");
      }
      $("#copy-textarea").val(copy);
      $("#share-modal").modal("show");
    });
    
    $(document).scrollTop(scrollPosition);
  }).always(function() {
    _enableReloads();
  });
}

$(document).ready(function() {
  
  $("#share-confirm").click(function(event) {
    $("#share-modal").modal("hide");
    _copyText();
    event.preventDefault();
  });
    
  $("#image-confirm").click(function(event) {
    $("#image-modal").modal("hide");
    _copyText();
    event.preventDefault();
  });
  
  $("#reload").click(function(event) {
    _reload(_path);
    event.preventDefault();
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
  
  $("#sort").click(function(event) {
    _sortAsc = !_sortAsc;
    $(this).text(_sortAsc ? "Sort Descending" : "Sort Ascending");
    _reload("/");
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
  
  $("#clear").click(function(event) {
    $.ajax({
      url: 'requests',
      type: 'DELETE',
      data: {},
      dataType: 'json'
    }).done(function(data, textStatus, jqXHR) {
      _reload("/");
    });
    event.preventDefault();
  });
  
  $("#wkwebview").click(function(event) {
    $.ajax({
      url: 'wkwebview',
      type: 'DELETE',
      data: {},
      dataType: 'json'
    }).done(function(data, textStatus, jqXHR) {
      _showMessage("Clear Successful");
    });
    event.preventDefault();
  });

  _reload("/");
  
  _setInterval(5000);
  
});
