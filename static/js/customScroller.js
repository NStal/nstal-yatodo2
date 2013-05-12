// Generated by CoffeeScript 1.6.2
(function() {
  var CustomScroller,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  CustomScroller = (function(_super) {
    __extends(CustomScroller, _super);

    function CustomScroller() {
      var _this = this;

      CustomScroller.__super__.constructor.call(this, App.templates["custom-scroller"]);
      this.scrollerPosition = 0;
      this.UI.scroller.onmousedown = function(e) {
        _this.startDrag = true;
        _this.startPoint = [e.pageX, e.pageY];
        _this.startTop = parseInt(_this.UI.scroller.style.top.replace("px", "") || 0);
        e.preventDefault();
        e.stopPropagation();
        return false;
        return $("body").addClass("no-select");
      };
      window.addEventListener("mouseup", function(e) {
        if (_this.startDrag) {
          e.preventDefault();
          e.stopPropagation();
        }
        _this.startDrag = false;
        _this.startPoint = null;
        $("body").removeClass("no-select");
        return false;
      });
      window.addEventListener("mousemove", function(e) {
        var top;

        if (!_this.startDrag) {
          return true;
        }
        e.preventDefault();
        top = _this.startTop + e.pageY - _this.startPoint[1];
        if (top < 0) {
          top = 0;
        }
        if (top > $(_this.parent).height() - _this.UI.scroller$.height()) {
          top = $(_this.parent).height() - _this.UI.scroller$.height();
        }
        _this.UI.scroller$.css({
          top: top
        });
        _this.scrollerPosition = top;
        _this.parent.scrollTop = top / _this.scaleRatio;
        return false;
      });
      this.node$.mousedown(function(e) {
        if (e.offsetY > _this.scrollerPosition) {
          _this.parent.scrollByPages(1);
        }
        if (e.offsetY < _this.scrollerPosition) {
          return _this.parent.scrollByPages(-1);
        }
      });
    }

    CustomScroller.prototype.attachTo = function(node) {
      this.parent = node;
      this.appendTo(this.parent);
      console.log(node, "!!!!!!!!!!!!");
      node.addEventListener("scroll", this.onScroll.bind(this));
      node.addEventListener("resize", this.resize.bind(this));
      this.resize();
      return $(window).resize(this.resize.bind(this));
    };

    CustomScroller.prototype.onScroll = function() {
      this.resize();
      this.UI.scroller$.css({
        top: this.parent.scrollTop * this.scaleRatio
      });
      return this.scrollerPosition = this.parent.scrollTop * this.scaleRatio;
    };

    CustomScroller.prototype.resize = function() {
      this.scaleRatio = $(this.parent).height() / this.parent.scrollHeight;
      this.node$.css({
        height: $(this.parent).height()
      });
      return this.UI.scroller$.height(this.scaleRatio * $(this.parent).height());
    };

    return CustomScroller;

  })(Leaf.Widget);

  window.CustomScroller = CustomScroller;

}).call(this);

/*
//@ sourceMappingURL=customScroller.map
*/
