(function() {
  var canvas = null;
  var blades = null;
  var curWidth = 0;
  var lastUpdate = new Date().getTime();

  var green = {
    r: 0,
    g: 128,
    b: 0
  };

  var brown = {
    r: 222,
    g: 184,
    b: 135
  };

  function averageColor(c1, c2, t) {
    if (t < 0) {
      t = 0;
    } else if (t > 1) {
      t = 1;
    }

    return {
      r: parseInt(c1['r'] + (c2['r'] - c1['r']) * t),
      g: parseInt(c1['g'] + (c2['g'] - c1['g']) * t),
      b: parseInt(c1['b'] + (c2['b'] - c1['b']) * t)
    };
  }

  function randRange(min, max) {
    var range = max - min;
    return Math.floor((Math.random() * range) + min);
  }

  function maybeNegative(x) {
    return (Math.random() > .5) ? x : -x;
  }

  function makeBlade(centerX) {
    var topY = randRange(0, 15);
    var bottomY = 200;
    var middleY = (topY + bottomY) / 2;

    var width = randRange(20, 40);
    var halfWidth = width / 2;

    var curve = maybeNegative(randRange(width / 3, width * 2 / 3));
    var leftX = centerX - halfWidth;
    var leftCurveX = leftX + curve;

    var rightX = leftX + width;
    var rightCurveX = rightX + curve;

    var startX = randRange(leftX, rightX);

    var colorVariance = maybeNegative(Math.random() * .25);
    var color = averageColor(brown, green, window.saturation + colorVariance);

    var path = new fabric.Path('M ' + leftX + ' ' + bottomY + ' ' +
                               'Q ' + leftCurveX + ' ' + middleY + ' ' + startX + ' ' + topY + ' ' +
                               'Q ' + rightCurveX + ' ' + middleY + ' ' + rightX + ' ' + bottomY + ' z');
    path.set({
      fill: 'rgb(' + color['r'] + ',' + color['g'] + ',' + color['b'] + ')',
      selectable: false
    });

    return {
      path: path,
      left: centerX - width / 3,
      right: centerX + width / 3,
      speed: (maybeNegative(randRange(1, 5))) / 1000
    };
  };

  $(document).on('page:change', function() {
    canvas = new fabric.Canvas('canvas');
    renderCanvas();
    requestAnimationFrame(function() {
      updatePaths();
    });
  });

  $(window).resize(function() {
    renderCanvas();
  });

  function renderCanvas() {
    var width = $(window).width();
    if (curWidth !== width) {
      curWidth = width;
      canvas.clear();
      canvas.setWidth(width);

      var numBlades = width / 10;
      blades = [];

      for (var i=0; i<numBlades; i++) {
        var blade = makeBlade(randRange(0, width));
        blades.push(blade);
        canvas.add(blade.path);
      }
    }
  };

  function updatePaths() {
    var now = new Date().getTime();
    var elapsed = now - lastUpdate;
    lastUpdate = now;

    for (var i=0; i<blades.length; i++) {
      var blade = blades[i];

      var x = blade.path.path[1][3] + blade.speed * elapsed;
      if (x >= blade.right) {
        x = blade.right;
        blade.speed *= -1;
      } else if (x <= blade.left) {
        x = blade.left;
        blade.speed *= -1;
      }
      blade.path.path[1][3] = x;
    }

    canvas.renderAll();
    requestAnimationFrame(function() {
      updatePaths();
    });
  };
}).call(this);
