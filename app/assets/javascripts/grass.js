/**
 * JavaScript grass animation
 * Requires Fabric.js
 * @author Andrew Richardson <awrichardson6@gmail.com>
 *
 * Usage:
 *   // Attach to <canvas> with id "my_canvas"
 *   var field = new grassyField('my_canvas');
 */
function grassyField(canvasId) {
  var self = this;
  self.element = document.getElementById(canvasId);
  self.canvas = new fabric.Canvas(canvasId);
  self.blades = null;
  self.lastUpdate = new Date().getTime();

  var green = { r: 0, g: 128, b: 0 },
    brown = { r: 222, g: 184, b: 135 };

  /**
   * Resize the canvas
   */
  self.resizeCanvas = function(width, height) {
    var curWidth = self.canvas.getWidth();
    var curHeight = self.canvas.getHeight();

    if (curWidth != width || curHeight != height) {
      self.canvas.clear();
      self.canvas.setWidth(width);
      self.canvas.setHeight(height);
      self._prepareCanvas();
    }
  };

  /**
   * Get a color partially between two other colors
   * c1 - starting color
   * c2 - ending color
   * t - position in the range 0-1
   */
  function colorStep(c1, c2, t) {
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

  /**
   * Return a random number within the given range
   */
  function randRange(min, max) {
    var range = max - min;
    return Math.floor((Math.random() * range) + min);
  }

  /**
   * Return x or -x with a 50/50 probability
   */
  function maybeNegative(x) {
    return (Math.random() > .5) ? x : -x;
  }

  self._makeBlade = function(centerX, height) {
    var topY = randRange(0, 15);
    var bottomY = height;
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
    var color = colorStep(brown, green, window.saturation + colorVariance);

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
      speed: maybeNegative(randRange(1, 5)) / 1000
    };
  };

  self._prepareCanvas = function() {
    var width = self.canvas.getWidth();
    var height = self.canvas.getHeight();
    var numBlades = width / 10;
    self.blades = [];

    for (var i=0; i<numBlades; i++) {
      var blade = self._makeBlade(randRange(0, width), height);
      self.blades.push(blade);
      self.canvas.add(blade.path);
    }
  };

  self._getTipX = function(i) {
    return self.blades[i].path.path[1][3];
  };

  self._setTipX = function(i, x) {
    self.blades[i].path.path[1][3] = x;
  };

  self._updatePaths = function() {
    var now = new Date().getTime();
    var elapsed = now - self.lastUpdate;
    self.lastUpdate = now;

    for (var i=0; i<self.blades.length; i++) {
      var blade = self.blades[i];

      var x = self._getTipX(i) + blade.speed * elapsed;
      if (x >= blade.right) {
        x = blade.right;
        blade.speed *= -1;
      } else if (x <= blade.left) {
        x = blade.left;
        blade.speed *= -1;
      }
      self._setTipX(i, x);
    }

    self.canvas.renderAll();
    self._scheduleUpdate();
  };

  self._scheduleUpdate = function() {
    requestAnimationFrame(function() {
      self._updatePaths();
    });
  };

  self._prepareCanvas();
  self._scheduleUpdate();
}