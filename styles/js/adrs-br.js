/*! adrs v2.0.1 | (c) 2022 ADRS | Contact hello@adrs-global.com */
(function () {
  'use strict';

  /**
   * Simple test for JavaScript to add/remove body class.
   *
   * @author Ben Rush | https://github.com/bnjmnrsh
   * @version 0.0.1
   * @returns void
   */

  (function jsTest() {
    var root = document.getElementsByTagName('html')[0];
    root.className += ' js';
    root.classList.remove('no-js');
  })();

  /**
   * Conditionally load the picturefill polyfill
   *
   * https://philipwalton.com/articles/loading-polyfills-only-when-needed/
   * https://github.com/scottjehl/picturefill/issues/677#issuecomment-289569292
   *
   * @author Philip Walton
   * @author Ben Rush | https://github.com/bnjmnrsh
   * @version 0.0.1
   */

  (function () {
    if (typeof window !== 'undefined' && !('picturefill' in window)) {
      var image = document.createElement('img');

      if (!('srcset' in image) || !('sizes' in image) || !window.HTMLPictureElement) {
        // load
        console.log('picturefill loading');
        script.src = window.ADRS.SOURCE_PATH + '/picturefill.min.js';
        document.head.appendChild(script);
      }
    }
  })();

  // TODO: Refactor using vanilla js

  /**
   * @discription Detect if we in a large viewport
   * @author Ben Rush | https://github.com/bnjmnrsh
   * @version 0.0.2
   * @requires jquery: 'jquery'
   * @requires u-scroll.js
   * @param {string} medBrkptLg // selector string
   */
  function mediaBreakpointLg(medBrkptLg) {
    // Though open and closing the hamburger will reset the tabindex
    // we need to keep things accessable and detect viewport changes and reset tabindex accordingly
    if (medBrkptLg.matches) {
      // console.log('Breakpoint lg')
      navTopMenusTabindex(0);
      navSubMenusTabindex(-1); // Unbind the return to hamburger .keydown event from the last link node

      unbindLastMenuItemKeydown(); // rebind submenu keydown event which closes submenues

      submenuTabNavigation();
      $('body').removeClass('-is-noScroll');
      $('#topNavBar').removeClass('-is-visible');
      $('#topNavBar').addClass('-is-brkpt_lg');
    } else {
      // top menu items inaccessable (dont want to tab to hidden items)
      navTopMenusTabindex(-1);
      navSubMenusTabindex(-1);
      $('#topNavBar').removeClass('-is-brkpt_lg'); // Reset the click handelers
      // smallViewportMenuModalTabindex();
    }
  }
  /**
   * @discription Toggles the menu when the user clicks the 'hamburger'
   * @author Ben Rush | https://github.com/bnjmnrsh
   * @requires jquery: 'jquery'
   * @requires u-scroll.js
   */


  function hamburgerToggle() {
    // toggle the atributes
    $('#topNavBarControl').toggleClass('-is-expanded');

    if ('true' === $('#topNavBarControl').attr('aria-expanded')) {
      $('#topNavBarControl').attr('aria-expanded', 'false');
    } else {
      $('#topNavBarControl').attr('aria-expanded', 'true');
    } // open the menu


    $('#topNavBar').toggleClass('-is-visible'); // prevent the background from scrolling behind the modal

    $('body').toggleClass('-is-noScroll'); /// Here we are making the menu elements in/accessable to tabindex
    // based on if the hamburger menu is open or closed

    if ($('#topNavBar').hasClass('-is-visible')) {
      // top & sub menu items accessable
      navTopMenusTabindex(0);
      navSubMenusTabindex(0);
      loginLinksTabindex(-1); // console.log('menu open');
    } else {
      // top & sub menu items inaccessable
      navTopMenusTabindex(-1);
      navSubMenusTabindex(-1);
      loginLinksTabindex(0); // console.log('menu closed');
    }
  }
  /**
   * @discription Collapse any open menus when a user clicks outside of them
   * @author Ben Rush | https://github.com/bnjmnrsh
   * @requires jquery: 'jquery'
   * @requires u-scroll.js
   */


  function closeSubmenusOnClick() {
    $(document).on('click', function () {
      // prevent clicks from within a container from closing the container
      $('.v1-m-navContainer').on('click', function (event) {
        event.stopImmediatePropagation();
      }); // Close the rest

      $('.-is-dropDown').next('.v1-m-navContainer.-is-visible').slideUp('fast').toggleClass('-is-visible').prev('.-is-dropDown').attr('aria-expanded', 'false');
    });
  }
  /**
   * @discription Handel click events for top level menus
   * @author Ben Rush | https://github.com/bnjmnrsh
   * @requires jquery: 'jquery'
   * @requires u-scroll.js
   */


  function menusDropDownsClickHandler() {
    $('.-is-dropDown').on('click', function (e) {
      if ('true' === $(this).attr('aria-expanded')) {
        $(this).attr('aria-expanded', 'false');
      } else {
        $(this).attr('aria-expanded', 'true');
      } // prevent default behavior of links on top of dropdown


      e.preventDefault(); // Slide up/down the submenus

      $(this).next('.v1-m-navContainer').slideToggle('fast', function () {
        if ($(this).is(':visible')) {
          // because jquery slideToggle resets the container to block rather then flex
          $(this).css('display', 'flex').toggleClass('-is-visible').removeClass('-is-overflowY'); // Append shadow to bottom of scrolling economic models div if needed
          // if ($(this).hasOverflowY()) {
          //   $(this).addClass('-is-overflowY')
          // }
        } // toggel the tabindex on sub-menus - fix for wide displays?


        $('.v1-m-navContainer__list a').attr('tabindex', function (index, attr) {
          return -1 == attr ? null : 0;
        });
      });
    });
  }
  /**
   * @discription  Prevent tabbing into elements behind the modal only when the hamburger menu is open
   */


  function smallViewportMenuModalTabindex() {
    var lastTopLevelMenuItem = $('#topNavBar.-is-visible .v01-o-navBar__menu > li:last-child .v1-m-navContainer'); // This keydown binding is destroyed when switching to larger viewport in mediaBreakpointLg()

    $('#topNavBar.-is-visible .v01-o-navBar__menu > li:last-child').keydown(function (e) {
      if (lastTopLevelMenuItem.hasClass('-is-visible')) {
        // Last tab is open
        $('#topNavBar.-is-visible .v01-o-navBar__menu > li:last-child li:last-child a').keydown(function (e) {
          tabReturnToHamburger(e);
        });
      } else if (9 == e.which) {
        tabReturnToHamburger(e);
      }
    });
    /**
     * @param {object} e event object
     */

    function tabReturnToHamburger(e) {
      if (9 == e.which && e.shiftKey) ; else if (9 == e.which) {
        $('#mainNav #topNavBarControl').focus();
        e.preventDefault(); // console.log('return focus to hamburger');
      }
    }
  }
  /**
   * @discription Handels tabbing in and out of submenus
   */


  function submenuTabNavigation() {
    $('.v1-m-navContainer > .-is-tabGroup:last-of-type li:last-child a').keydown(function (e) {
      if (9 == e.which && e.shiftKey) ; else if (9 == e.which) {
        // console.log('SUBMENU: last element tabbed out');
        // close the container
        $('.v1-m-navContainer.-is-visible').slideUp('fast').toggleClass('-is-visible').prev('.-is-dropDown').attr('aria-expanded', false);
      }
    });
    $('.v1-m-navContainer > .-is-tabGroup:first-of-type li:first-child a').keydown(function (e) {
      if (9 == e.which && e.shiftKey) {
        // console.log('SUBMENU: first element reverse-tabbed out');
        // close the container
        $('.v1-m-navContainer.-is-visible').slideUp('fast').toggleClass('-is-visible').prev('.-is-dropDown').attr('aria-expanded', false);
      } else if (9 == e.which) ;
    });
  }
  /**
   * @discription Fix header nav to top when scrolling up (large displays)
   */


  function fixHeaderNav() {
    $(window).scroll(function () {
      var headertop = $('.v1-o-topHeader').outerHeight(true);
      var scrolltop = $(window).scrollTop();

      if (scrolltop >= headertop) {
        $('.v1-o-bottomHeader').addClass('-is-fixed');
      } else {
        $('.v1-o-bottomHeader').removeClass('-is-fixed');
      }
    });
  }
  /**
   * Will remove these events regardelss of vewport size or if the 'hanburger' menu is open.
   *
   * @discription Helper function to unbind all keydown listeners for the last menu item, and the last item in any following submenu.
   * @author Ben Rush | https://github.com/bnjmnrsh
   * @requires jquery: 'jquery'
   * @requires u-scroll.js
   */


  function unbindLastMenuItemKeydown() {
    $('#topNavBar .v01-o-navBar__menu > li:last-child li:last-child a').unbind('keydown');
    $('#topNavBar .v01-o-navBar__menu li:last-child').unbind('keydown');
  }
  /**
   * @discription Helper function to target the nav submenu link elements and set thier tabindex value
   * @author Ben Rush | https://github.com/bnjmnrsh
   * @requires jquery: 'jquery'
   * @requires u-scroll.js
   * @param {string} x the tabindex
   */


  function navSubMenusTabindex(x) {
    $('.v1-m-navContainer__list a').attr('tabindex', x);
  }
  /**
   * @discription Helper function to target the nav top-level menu link elements and set thier tabindex value
   * @author Ben Rush | https://github.com/bnjmnrsh
   * @requires jquery: 'jquery'
   * @requires u-scroll.js
   * @param {string} x the tabindex
   */


  function navTopMenusTabindex(x) {
    $('.v01-o-navBar__menu li a').attr('tabindex', x); // console.log("TOP LEVEL nav menu links tabindex: " + x);
  }
  /**
   * @discription  Helper function to target the login menu link elements and set thier tabindex value
   * @author Ben Rush | https://github.com/bnjmnrsh
   * @requires jquery: 'jquery'
   * @requires u-scroll.js
   * @param {string} x the tabindex
   */


  function loginLinksTabindex(x) {
    $('#v1-m-login a').attr('tabindex', x); // console.log("SUB MENU links tabindex: " + x);
  }

  $(document).ready(function () {
    var medBrkptLg = window.matchMedia('screen and (min-width: 71.5em)'); // SASS $breakpoint-large
    // Top menu sticky scrolling on large viewports

    fixHeaderNav(); // inital setup of menus conditions
    // Add inital style hooks and aria attributes for dropdowns.

    $('.-is-dropDown').attr('data-role', 'button').attr('aria-expanded', false);
    $('.-is-dropDown').next('.v1-m-navContainer').addClass('-is-jsDropDown'); // we have js, so initially make submenu items tab inaccessable at all display sizes

    navSubMenusTabindex(-1); // Handel click events for top level menus

    menusDropDownsClickHandler(); // Close submenus when user clicks away from them

    closeSubmenusOnClick(); // Handel keyboard tab navigation through submenus

    submenuTabNavigation(); // The hamburger menu open-close

    $('#topNavBarControl').on('click', function () {
      // Open/close hamburger menu
      hamburgerToggle(); // Prevent tabbing into elements behind the modal only when the hamburger menu is open

      smallViewportMenuModalTabindex();
    }); // Media Breakpoints

    mediaBreakpointLg(medBrkptLg); // call on inital load

    medBrkptLg.addListener(mediaBreakpointLg); // add listener
  });

  function _typeof(obj) {
    "@babel/helpers - typeof";

    if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") {
      _typeof = function (obj) {
        return typeof obj;
      };
    } else {
      _typeof = function (obj) {
        return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj;
      };
    }

    return _typeof(obj);
  }

  function _classCallCheck(instance, Constructor) {
    if (!(instance instanceof Constructor)) {
      throw new TypeError("Cannot call a class as a function");
    }
  }

  function _defineProperties(target, props) {
    for (var i = 0; i < props.length; i++) {
      var descriptor = props[i];
      descriptor.enumerable = descriptor.enumerable || false;
      descriptor.configurable = true;
      if ("value" in descriptor) descriptor.writable = true;
      Object.defineProperty(target, descriptor.key, descriptor);
    }
  }

  function _createClass(Constructor, protoProps, staticProps) {
    if (protoProps) _defineProperties(Constructor.prototype, protoProps);
    if (staticProps) _defineProperties(Constructor, staticProps);
    return Constructor;
  }

  function _slicedToArray(arr, i) {
    return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest();
  }

  function _toConsumableArray(arr) {
    return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread();
  }

  function _arrayWithoutHoles(arr) {
    if (Array.isArray(arr)) return _arrayLikeToArray(arr);
  }

  function _arrayWithHoles(arr) {
    if (Array.isArray(arr)) return arr;
  }

  function _iterableToArray(iter) {
    if (typeof Symbol !== "undefined" && iter[Symbol.iterator] != null || iter["@@iterator"] != null) return Array.from(iter);
  }

  function _iterableToArrayLimit(arr, i) {
    var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"];

    if (_i == null) return;
    var _arr = [];
    var _n = true;
    var _d = false;

    var _s, _e;

    try {
      for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) {
        _arr.push(_s.value);

        if (i && _arr.length === i) break;
      }
    } catch (err) {
      _d = true;
      _e = err;
    } finally {
      try {
        if (!_n && _i["return"] != null) _i["return"]();
      } finally {
        if (_d) throw _e;
      }
    }

    return _arr;
  }

  function _unsupportedIterableToArray(o, minLen) {
    if (!o) return;
    if (typeof o === "string") return _arrayLikeToArray(o, minLen);
    var n = Object.prototype.toString.call(o).slice(8, -1);
    if (n === "Object" && o.constructor) n = o.constructor.name;
    if (n === "Map" || n === "Set") return Array.from(o);
    if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen);
  }

  function _arrayLikeToArray(arr, len) {
    if (len == null || len > arr.length) len = arr.length;

    for (var i = 0, arr2 = new Array(len); i < len; i++) arr2[i] = arr[i];

    return arr2;
  }

  function _nonIterableSpread() {
    throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.");
  }

  function _nonIterableRest() {
    throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.");
  }

  function _createForOfIteratorHelper(o, allowArrayLike) {
    var it = typeof Symbol !== "undefined" && o[Symbol.iterator] || o["@@iterator"];

    if (!it) {
      if (Array.isArray(o) || (it = _unsupportedIterableToArray(o)) || allowArrayLike && o && typeof o.length === "number") {
        if (it) o = it;
        var i = 0;

        var F = function () {};

        return {
          s: F,
          n: function () {
            if (i >= o.length) return {
              done: true
            };
            return {
              done: false,
              value: o[i++]
            };
          },
          e: function (e) {
            throw e;
          },
          f: F
        };
      }

      throw new TypeError("Invalid attempt to iterate non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.");
    }

    var normalCompletion = true,
        didErr = false,
        err;
    return {
      s: function () {
        it = it.call(o);
      },
      n: function () {
        var step = it.next();
        normalCompletion = step.done;
        return step;
      },
      e: function (e) {
        didErr = true;
        err = e;
      },
      f: function () {
        try {
          if (!normalCompletion && it.return != null) it.return();
        } finally {
          if (didErr) throw err;
        }
      }
    };
  }

  /*! Lity - v3.0.0-dev-svg - 2022-06-16
  * http://sorgalla.com/lity/
  * Copyright (c) 2015-2022 Jan Sorgalla; Licensed MIT; FORK REPO https://github.com/bnjmnrsh/lity-svg */
  (function (window, factory) {
    if (typeof define === 'function' && define.amd) {
      define(['jquery'], function ($) {
        return factory(window, $);
      });
    } else if ((typeof module === "undefined" ? "undefined" : _typeof(module)) === 'object' && _typeof(module.exports) === 'object') {
      module.exports = factory(window, require('jquery'));
    } else {
      window.lity = factory(window, window.jQuery || window.Zepto);
    }
  })(typeof window !== "undefined" ? window : undefined, function (window, $) {

    var document = window.document;

    var _win = $(window);

    var _deferred = $.Deferred;

    var _html = $('html');

    var _instances = [];
    var _attrAriaHidden = 'aria-hidden';

    var _dataAriaHidden = 'lity-' + _attrAriaHidden;

    var _focusableElementsSelector = 'a[href],area[href],input:not([disabled]),select:not([disabled]),textarea:not([disabled]),button:not([disabled]),iframe,object,embed,[contenteditable],[tabindex]:not([tabindex^="-"])';
    var _defaultOptions = {
      esc: true,
      handler: null,
      handlers: {
        image: imageHandler,
        inline: inlineHandler,
        iframe: iframeHandler
      },
      template: '<div class="lity" role="dialog" aria-label="Dialog Window (Press escape to close)" tabindex="-1"><div class="lity-wrap" data-lity-close role="document"><div class="lity-loader" aria-hidden="true">Loading...</div><div class="lity-container"><div class="lity-content"></div><button class="lity-close" type="button" aria-label="Close (Press escape to close)" data-lity-close>&times;</button></div></div></div>'
    };
    var _imageRegexp = /(^data:image\/)|(\.(png|jpe?g|gif|svg|webp|bmp|ico|tiff?)(\?\S*)?$)/i;

    var _transitionEndEvent = function () {
      var el = document.createElement('div');
      var transEndEventNames = {
        WebkitTransition: 'webkitTransitionEnd',
        MozTransition: 'transitionend',
        OTransition: 'oTransitionEnd otransitionend',
        transition: 'transitionend'
      };

      for (var name in transEndEventNames) {
        if (el.style[name] !== undefined) {
          return transEndEventNames[name];
        }
      }

      return false;
    }();
    /**
     * @param element
     */


    function transitionEnd(element) {
      var deferred = _deferred();

      if (!_transitionEndEvent || !element.length) {
        deferred.resolve();
      } else {
        element.one(_transitionEndEvent, deferred.resolve);
        setTimeout(deferred.resolve, 500);
      }

      return deferred.promise();
    }
    /**
     * @param currSettings
     * @param key
     * @param value
     */


    function settings(currSettings, key, value) {
      if (arguments.length === 1) {
        return $.extend({}, currSettings);
      }

      if (typeof key === 'string') {
        if (typeof value === 'undefined') {
          return typeof currSettings[key] === 'undefined' ? null : currSettings[key];
        }

        currSettings[key] = value;
      } else {
        $.extend(currSettings, key);
      }

      return this;
    }
    /**
     * @param params
     */


    function parseQueryParams(params) {
      var pos = params.indexOf('?');

      if (pos > -1) {
        params = params.substr(pos + 1);
      }

      var pairs = decodeURI(params.split('#')[0]).split('&');
      var obj = {},
          p;

      for (var i = 0, n = pairs.length; i < n; i++) {
        if (!pairs[i]) {
          continue;
        }

        p = pairs[i].split('=');
        obj[p[0]] = p[1];
      }

      return obj;
    }
    /**
     * @param url
     * @param params
     */


    function appendQueryParams(url, params) {
      if (!params) {
        return url;
      }

      if ('string' === $.type(params)) {
        params = parseQueryParams(params);
      }

      if (url.indexOf('?') > -1) {
        var split = url.split('?');
        url = split.shift();
        params = $.extend({}, parseQueryParams(split[0]), params);
      }

      return url + '?' + $.param(params);
    }
    /**
     * @param originalUrl
     * @param newUrl
     */


    function transferHash(originalUrl, newUrl) {
      var pos = originalUrl.indexOf('#');

      if (-1 === pos) {
        return newUrl;
      }

      if (pos > 0) {
        originalUrl = originalUrl.substr(pos);
      }

      return newUrl + originalUrl;
    }
    /**
     * @param iframeUrl
     * @param instance
     * @param queryParams
     * @param hashUrl
     */


    function iframe(iframeUrl, instance, queryParams, hashUrl) {
      instance && instance.element().addClass('lity-iframe');

      if (queryParams) {
        iframeUrl = appendQueryParams(iframeUrl, queryParams);
      }

      if (hashUrl) {
        iframeUrl = transferHash(hashUrl, iframeUrl);
      }

      return '<div class="lity-iframe-container"><iframe frameborder="0" allowfullscreen allow="autoplay; fullscreen" src="' + iframeUrl + '"/></div>';
    }
    /**
     * @param msg
     */


    function error(msg) {
      return $('<span class="lity-error"></span>').append(msg);
    }
    /**
     * @param target
     * @param instance
     */


    function imageHandler(target, instance) {
      var desc = instance.opener() && instance.opener().data('lity-desc') || 'Image with no description';
      var img = $('<img src="' + target + '" alt="' + desc + '"/>');

      var deferred = _deferred();

      var failed = function failed() {
        deferred.reject(error('Failed loading image'));
      };

      img.on('load', function () {
        if (this.naturalWidth === 0) {
          return failed();
        }

        deferred.resolve(img);
      }).on('error', failed);
      return deferred.promise();
    }

    imageHandler.test = function (target) {
      return _imageRegexp.test(target);
    };
    /**
     * @param target
     * @param instance
     */


    function inlineHandler(target, instance) {
      var el, placeholder, hasHideClass;

      try {
        el = $(target);
      } catch (e) {
        return false;
      }

      if (!el.length) {
        return false;
      }

      placeholder = $('<i style="display:none !important"></i>');
      hasHideClass = el.hasClass('lity-hide');
      instance.element().one('lity:remove', function () {
        placeholder.before(el).remove();

        if (hasHideClass && !el.closest('.lity-content').length) {
          el.addClass('lity-hide');
        }
      });
      return el.removeClass('lity-hide').after(placeholder);
    }
    /**
     * @param target
     * @param instance
     */


    function iframeHandler(target, instance) {
      return iframe(target, instance);
    }
    /**
     * @param e
     */


    function keydown(e) {
      var current = currentInstance();

      if (!current) {
        return;
      } // ESC key


      if (e.keyCode === 27 && !!current.options('esc')) {
        current.close();
      } // TAB key


      if (e.keyCode === 9) {
        handleTabKey(e, current);
      }
    }
    /**
     * @param e
     * @param instance
     */


    function handleTabKey(e, instance) {
      var focusableElements = instance.element().find(_focusableElementsSelector);
      var focusedIndex = focusableElements.index(document.activeElement);

      if (e.shiftKey && focusedIndex <= 0) {
        focusableElements.get(focusableElements.length - 1).focus();
        e.preventDefault();
      } else if (!e.shiftKey && focusedIndex === focusableElements.length - 1) {
        focusableElements.get(0).focus();
        e.preventDefault();
      }
    }
    /**
     *
     */


    function resize() {
      $.each(_instances, function (i, instance) {
        instance.resize();
      });
    }
    /**
     * @param instanceToRegister
     */


    function registerInstance(instanceToRegister) {
      if (1 === _instances.unshift(instanceToRegister)) {
        _html.addClass('lity-active');

        _win.on({
          resize: resize,
          keydown: keydown
        });
      }

      $('body > *').not(instanceToRegister.element()).addClass('lity-hidden').each(function () {
        var el = $(this);

        if (undefined !== el.data(_dataAriaHidden)) {
          return;
        }

        el.data(_dataAriaHidden, el.attr(_attrAriaHidden) || null);
      }).attr(_attrAriaHidden, 'true');
    }
    /**
     * @param instanceToRemove
     */


    function removeInstance(instanceToRemove) {
      var show;
      instanceToRemove.element().attr(_attrAriaHidden, 'true');

      if (1 === _instances.length) {
        _html.removeClass('lity-active');

        _win.off({
          resize: resize,
          keydown: keydown
        });
      }

      _instances = $.grep(_instances, function (instance) {
        return instanceToRemove !== instance;
      });

      if (!!_instances.length) {
        show = _instances[0].element();
      } else {
        show = $('.lity-hidden');
      }

      show.removeClass('lity-hidden').each(function () {
        var el = $(this),
            oldAttr = el.data(_dataAriaHidden);

        if (!oldAttr) {
          el.removeAttr(_attrAriaHidden);
        } else {
          el.attr(_attrAriaHidden, oldAttr);
        }

        el.removeData(_dataAriaHidden);
      });
    }
    /**
     *
     */


    function currentInstance() {
      if (0 === _instances.length) {
        return null;
      }

      return _instances[0];
    }
    /**
     * @param target
     * @param instance
     * @param handlers
     * @param preferredHandler
     */


    function factory(target, instance, handlers, preferredHandler) {
      var handler = 'inline',
          content;
      var currentHandlers = $.extend({}, handlers);

      if (preferredHandler && currentHandlers[preferredHandler]) {
        content = currentHandlers[preferredHandler](target, instance);
        handler = preferredHandler;
      } else {
        // Run inline and iframe handlers after all other handlers
        $.each(['inline', 'iframe'], function (i, name) {
          delete currentHandlers[name];
          currentHandlers[name] = handlers[name];
        });
        $.each(currentHandlers, function (name, currentHandler) {
          // Handler might be "removed" by setting callback to null
          if (!currentHandler) {
            return true;
          }

          if (currentHandler.test && !currentHandler.test(target, instance)) {
            return true;
          }

          content = currentHandler(target, instance);

          if (false !== content) {
            handler = name;
            return false;
          }
        });
      }

      return {
        handler: handler,
        content: content || ''
      };
    }
    /**
     * @param target
     * @param options
     * @param opener
     * @param activeElement
     */


    function Lity(target, options, opener, activeElement) {
      var self = this;
      var result;
      var isReady = false;
      var isClosed = false;
      var element;
      var content;
      options = $.extend({}, _defaultOptions, options);
      element = $(options.template); // -- API --

      self.element = function () {
        return element;
      };

      self.opener = function () {
        return opener;
      };

      self.content = function () {
        return content;
      };

      self.options = $.proxy(settings, self, options);
      self.handlers = $.proxy(settings, self, options.handlers);

      self.resize = function () {
        if (!isReady || isClosed) {
          return;
        } // content.css('max-height', winHeight() + 'px').trigger('lity:resize', [self]);


        content.trigger('lity:resize', [self]);
      };

      self.close = function () {
        if (!isReady || isClosed) {
          return;
        }

        isClosed = true;
        removeInstance(self);

        var deferred = _deferred(); // console.log('active element', activeElement)
        // console.log('document.activeElement',  document.activeElement)
        // console.log('element[0]', element[0])
        // console.log('$.contains',  $.contains(element[0], document.activeElement))
        // console.log('document.activeElement === element[0]',  document.activeElement === element[0])
        // We return focus only if the current focus is inside this instance


        if (activeElement // &&
        // (
        //     document.activeElement === element[0] ||
        //     $.contains(element[0], document.activeElement)
        // )
        ) {
          try {
            activeElement.focus();
          } catch (e) {// Ignore exceptions, eg. for SVG elements which can't be
            // focused in IE11
          }
        }

        content.trigger('lity:close', [self]);
        element.removeClass('lity-opened').addClass('lity-closed');
        transitionEnd(content.add(element)).always(function () {
          content.trigger('lity:remove', [self]);
          element.remove();
          element = undefined;
          deferred.resolve();
        });
        return deferred.promise();
      }; // -- Initialization --


      result = factory(target, self, options.handlers, options.handler);
      element.attr(_attrAriaHidden, 'false').addClass('lity-loading lity-opened lity-' + result.handler).appendTo('body').focus().on('click', '[data-lity-close]', function (e) {
        if ($(e.target).is('[data-lity-close]')) {
          self.close();
        }
      }).trigger('lity:open', [self]);
      registerInstance(self);
      $.when(result.content).always(ready);
      /**
       * @param result
       */

      function ready(result) {
        // content = $(result).css('max-height', winHeight() + 'px');
        content = $(result);
        element.find('.lity-loader').each(function () {
          var loader = $(this);
          transitionEnd(loader).always(function () {
            loader.remove();
          });
        });
        element.removeClass('lity-loading').find('.lity-content').empty().append(content);
        isReady = true;
        content.trigger('lity:ready', [self]);
      }
    }
    /**
     * @param target
     * @param options
     * @param opener
     */


    function lity(target, options, opener) {
      if (!target.preventDefault) {
        opener = $(opener);
      } else {
        target.preventDefault();
        opener = $(this);
        target = opener.data('lity-target') || opener.attr('href') || opener.attr('src');
      }

      var instance = new Lity(target, $.extend({}, opener.data('lity-options') || opener.data('lity'), options), opener, document.activeElement);

      if (!target.preventDefault) {
        return instance;
      }
    }

    lity.version = '3.0.0-dev-svg';
    lity.options = $.proxy(settings, lity, _defaultOptions);
    lity.handlers = $.proxy(settings, lity, _defaultOptions.handlers);
    lity.current = currentInstance;
    lity.iframe = iframe;
    $(document).on('click.lity', '[data-lity]', lity);
    return lity;
  });

  /*
   * jQuery Navgoco Menus Plugin v0.2.1 (2014-04-11)
   * https://github.com/tefra/navgoco
   *
   * Copyright (c) 2014 Chris T (@tefra)
   * BSD - https://github.com/tefra/navgoco/blob/master/LICENSE-BSD
   */
  !function (a) {

    var b = function b(_b, c, d) {
      return this.el = _b, this.$el = a(_b), this.options = c, this.uuid = this.$el.attr("id") ? this.$el.attr("id") : d, this.state = {}, this.init(), this;
    };

    b.prototype = {
      init: function init() {
        var b = this;
        b._load(), b.$el.find("ul").each(function (c) {
          var d = a(this);
          d.attr("data-index", c), b.options.save && b.state.hasOwnProperty(c) ? (d.parent().addClass(b.options.openClass), d.show()) : d.parent().hasClass(b.options.openClass) ? (d.show(), b.state[c] = 1) : d.hide();
        });
        var c = a("<span></span>").prepend(b.options.caretHtml),
            d = b.$el.find("li > a");
        b._trigger(c, !1), b._trigger(d, !0), b.$el.find("li:has(ul) > a").prepend(c);
      },
      _trigger: function _trigger(b, c) {
        var d = this;
        b.on("click", function (b) {
          b.stopPropagation();
          var e = c ? a(this).next() : a(this).parent().next(),
              f = !1;

          if (c) {
            var g = a(this).attr("href");
            f = void 0 === g || "" === g || "#" === g;
          }

          if (e = e.length > 0 ? e : !1, d.options.onClickBefore.call(this, b, e), !c || e && f) b.preventDefault(), d._toggle(e, e.is(":hidden")), d._save();else if (d.options.accordion) {
            var h = d.state = d._parents(a(this));

            d.$el.find("ul").filter(":visible").each(function () {
              var b = a(this),
                  c = b.attr("data-index");
              h.hasOwnProperty(c) || d._toggle(b, !1);
            }), d._save();
          }
          d.options.onClickAfter.call(this, b, e);
        });
      },
      _toggle: function _toggle(b, c) {
        var d = this,
            e = b.attr("data-index"),
            f = b.parent();

        if (d.options.onToggleBefore.call(this, b, c), c) {
          if (f.addClass(d.options.openClass), b.slideDown(d.options.slide), d.state[e] = 1, d.options.accordion) {
            var g = d.state = d._parents(b);

            g[e] = d.state[e] = 1, d.$el.find("ul").filter(":visible").each(function () {
              var b = a(this),
                  c = b.attr("data-index");
              g.hasOwnProperty(c) || d._toggle(b, !1);
            });
          }
        } else f.removeClass(d.options.openClass), b.slideUp(d.options.slide), d.state[e] = 0;

        d.options.onToggleAfter.call(this, b, c);
      },
      _parents: function _parents(b, c) {
        var d = {},
            e = b.parent(),
            f = e.parents("ul");
        return f.each(function () {
          var b = a(this),
              e = b.attr("data-index");
          return e ? void (d[e] = c ? b : 1) : !1;
        }), d;
      },
      _save: function _save() {
        if (this.options.save) {
          var b = {};

          for (var d in this.state) {
            1 === this.state[d] && (b[d] = 1);
          }

          c[this.uuid] = this.state = b, a.cookie(this.options.cookie.name, JSON.stringify(c), this.options.cookie);
        }
      },
      _load: function _load() {
        if (this.options.save) {
          if (null === c) {
            var b = a.cookie(this.options.cookie.name);
            c = b ? JSON.parse(b) : {};
          }

          this.state = c.hasOwnProperty(this.uuid) ? c[this.uuid] : {};
        }
      },
      toggle: function toggle(b) {
        var c = this,
            d = arguments.length;
        if (1 >= d) c.$el.find("ul").each(function () {
          var d = a(this);

          c._toggle(d, b);
        });else {
          var e,
              f = {},
              g = Array.prototype.slice.call(arguments, 1);
          d--;

          for (var h = 0; d > h; h++) {
            e = g[h];
            var i = c.$el.find('ul[data-index="' + e + '"]').first();

            if (i && (f[e] = i, b)) {
              var j = c._parents(i, !0);

              for (var k in j) {
                f.hasOwnProperty(k) || (f[k] = j[k]);
              }
            }
          }

          for (e in f) {
            c._toggle(f[e], b);
          }
        }

        c._save();
      },
      destroy: function destroy() {
        a.removeData(this.$el), this.$el.find("li:has(ul) > a").unbind("click"), this.$el.find("li:has(ul) > a > span").unbind("click");
      }
    }, a.fn.navgoco = function (c) {
      if ("string" == typeof c && "_" !== c.charAt(0) && "init" !== c) var d = !0,
          e = Array.prototype.slice.call(arguments, 1);else c = a.extend({}, a.fn.navgoco.defaults, c || {}), a.cookie || (c.save = !1);
      return this.each(function (f) {
        var g = a(this),
            h = g.data("navgoco");
        h || (h = new b(this, d ? a.fn.navgoco.defaults : c, f), g.data("navgoco", h)), d && h[c].apply(h, e);
      });
    };
    var c = null;
    a.fn.navgoco.defaults = {
      caretHtml: "",
      accordion: !1,
      openClass: "open",
      save: !0,
      cookie: {
        name: "navgoco",
        expires: !1,
        path: "/"
      },
      slide: {
        duration: 400,
        easing: "swing"
      },
      onClickBefore: a.noop,
      onClickAfter: a.noop,
      onToggleBefore: a.noop,
      onToggleAfter: a.noop
    };
  }(jQuery);

  /*!
   * tabbyjs v12.0.3
   * Lightweight, accessible vanilla JS toggle tabs.
   * (c) 2019 Chris Ferdinandi
   * MIT License
   * http://github.com/cferdinandi/tabby
   */

  /**
   * Element.matches() polyfill (simple version)
   * https://developer.mozilla.org/en-US/docs/Web/API/Element/matches#Polyfill
   */
  if (!Element.prototype.matches) {
    Element.prototype.matches = Element.prototype.msMatchesSelector || Element.prototype.webkitMatchesSelector;
  }
  /**
   * Element.closest() polyfill
   * https://developer.mozilla.org/en-US/docs/Web/API/Element/closest#Polyfill
   */


  if (!Element.prototype.closest) {
    if (!Element.prototype.matches) {
      Element.prototype.matches = Element.prototype.msMatchesSelector || Element.prototype.webkitMatchesSelector;
    }

    Element.prototype.closest = function (s) {
      var el = this;
      var ancestor = this;
      if (!document.documentElement.contains(el)) return null;

      do {
        if (ancestor.matches(s)) return ancestor;
        ancestor = ancestor.parentElement;
      } while (ancestor !== null);

      return null;
    };
  }

  (function (root, factory) {
    if (typeof define === 'function' && define.amd) {
      define([], function () {
        return factory(root);
      });
    } else if ((typeof exports === "undefined" ? "undefined" : _typeof(exports)) === 'object') {
      module.exports = factory(root);
    } else {
      root.Tabby = factory(root);
    }
  })(typeof global !== 'undefined' ? global : typeof window !== 'undefined' ? window : undefined, function (window) {
    // Variables
    //

    var defaults = {
      idPrefix: 'tabby-toggle_',
      default: '[data-tabby-default]'
    }; //
    // Methods
    //

    /**
     * Merge two or more objects together.
     * @param   {Object}   objects  The objects to merge together
     * @returns {Object}            Merged values of defaults and options
     */

    var extend = function extend() {
      var merged = {};
      Array.prototype.forEach.call(arguments, function (obj) {
        for (var key in obj) {
          if (!obj.hasOwnProperty(key)) return;
          merged[key] = obj[key];
        }
      });
      return merged;
    };
    /**
     * Emit a custom event
     * @param  {String} type    The event type
     * @param  {Node}   tab     The tab to attach the event to
     * @param  {Node}   details Details about the event
     */


    var emitEvent = function emitEvent(tab, details) {
      // Create a new event
      var event;

      if (typeof window.CustomEvent === 'function') {
        event = new CustomEvent('tabby', {
          bubbles: true,
          cancelable: true,
          detail: details
        });
      } else {
        event = document.createEvent('CustomEvent');
        event.initCustomEvent('tabby', true, true, details);
      } // Dispatch the event


      tab.dispatchEvent(event);
    };
    /**
     * Remove roles and attributes from a tab and its content
     * @param  {Node}   tab      The tab
     * @param  {Node}   content  The tab content
     * @param  {Object} settings User settings and options
     */


    var destroyTab = function destroyTab(tab, content, settings) {
      // Remove the generated ID
      if (tab.id.slice(0, settings.idPrefix.length) === settings.idPrefix) {
        tab.id = '';
      } // Remove roles


      tab.removeAttribute('role');
      tab.removeAttribute('aria-controls');
      tab.removeAttribute('aria-selected');
      tab.removeAttribute('tabindex');
      tab.closest('li').removeAttribute('role');
      content.removeAttribute('role');
      content.removeAttribute('aria-labelledby');
      content.removeAttribute('hidden');
    };
    /**
     * Add the required roles and attributes to a tab and its content
     * @param  {Node}   tab      The tab
     * @param  {Node}   content  The tab content
     * @param  {Object} settings User settings and options
     */


    var setupTab = function setupTab(tab, content, settings) {
      // Give tab an ID if it doesn't already have one
      if (!tab.id) {
        tab.id = settings.idPrefix + content.id;
      } // Add roles


      tab.setAttribute('role', 'tab');
      tab.setAttribute('aria-controls', content.id);
      tab.closest('li').setAttribute('role', 'presentation');
      content.setAttribute('role', 'tabpanel');
      content.setAttribute('aria-labelledby', tab.id); // Add selected state

      if (tab.matches(settings.default)) {
        tab.setAttribute('aria-selected', 'true');
      } else {
        tab.setAttribute('aria-selected', 'false');
        tab.setAttribute('tabindex', '-1');
        content.setAttribute('hidden', 'hidden');
      }
    };
    /**
     * Hide a tab and its content
     * @param  {Node} newTab The new tab that's replacing it
     */


    var hide = function hide(newTab) {
      // Variables
      var tabGroup = newTab.closest('[role="tablist"]');
      if (!tabGroup) return {};
      var tab = tabGroup.querySelector('[role="tab"][aria-selected="true"]');
      if (!tab) return {};
      var content = document.querySelector(tab.hash); // Hide the tab

      tab.setAttribute('aria-selected', 'false');
      tab.setAttribute('tabindex', '-1'); // Hide the content

      if (!content) return {
        previousTab: tab
      };
      content.setAttribute('hidden', 'hidden'); // Return the hidden tab and content

      return {
        previousTab: tab,
        previousContent: content
      };
    };
    /**
     * Show a tab and its content
     * @param  {Node} tab      The tab
     * @param  {Node} content  The tab content
     */


    var show = function show(tab, content) {
      tab.setAttribute('aria-selected', 'true');
      tab.setAttribute('tabindex', '0');
      content.removeAttribute('hidden');
      tab.focus();
    };
    /**
     * Toggle a new tab
     * @param  {Node} tab The tab to show
     */


    var toggle = function toggle(tab) {
      // Make sure there's a tab to toggle and it's not already active
      if (!tab || tab.getAttribute('aria-selected') == 'true') return; // Variables

      var content = document.querySelector(tab.hash);
      if (!content) return; // Hide active tab and content

      var details = hide(tab); // Show new tab and content

      show(tab, content); // Add event details

      details.tab = tab;
      details.content = content; // Emit a custom event

      emitEvent(tab, details);
    };
    /**
     * Get all of the tabs in a tablist
     * @param  {Node}   tab  A tab from the list
     * @return {Object}      The tabs and the index of the currently active one
     */


    var getTabsMap = function getTabsMap(tab) {
      var tabGroup = tab.closest('[role="tablist"]');
      var tabs = tabGroup ? tabGroup.querySelectorAll('[role="tab"]') : null;
      if (!tabs) return;
      return {
        tabs: tabs,
        index: Array.prototype.indexOf.call(tabs, tab)
      };
    };
    /**
     * Switch the active tab based on keyboard activity
     * @param  {Node} tab The currently active tab
     * @param  {Key}  key The key that was pressed
     */


    var switchTabs = function switchTabs(tab, key) {
      // Get a map of tabs
      var map = getTabsMap(tab);
      if (!map) return;
      var length = map.tabs.length - 1;
      var index; // Go to previous tab

      if (['ArrowUp', 'ArrowLeft', 'Up', 'Left'].indexOf(key) > -1) {
        index = map.index < 1 ? length : map.index - 1;
      } // Go to next tab
      else if (['ArrowDown', 'ArrowRight', 'Down', 'Right'].indexOf(key) > -1) {
        index = map.index === length ? 0 : map.index + 1;
      } // Go to home
      else if (key === 'Home') {
        index = 0;
      } // Go to end
      else if (key === 'End') {
        index = length;
      } // Toggle the tab


      toggle(map.tabs[index]);
    };
    /**
     * Activate a tab based on the URL
     * @param  {String} selector The selector for this instantiation
     */


    var loadFromURL = function loadFromURL(selector) {
      if (window.location.hash.length < 1) return;
      var tab = document.querySelector(selector + ' [role="tab"][href*="' + window.location.hash + '"]');
      toggle(tab);
    };
    /**
     * Create the Constructor object
     */


    var Constructor = function Constructor(selector, options) {
      //
      // Variables
      //
      var publicAPIs = {};
      var settings, tabWrapper; //
      // Methods
      //

      publicAPIs.destroy = function () {
        // Get all tabs
        var tabs = tabWrapper.querySelectorAll('a'); // Add roles to tabs

        Array.prototype.forEach.call(tabs, function (tab) {
          // Get the tab content
          var content = document.querySelector(tab.hash);
          if (!content) return; // Setup the tab

          destroyTab(tab, content, settings);
        }); // Remove role from wrapper

        tabWrapper.removeAttribute('role'); // Remove event listeners

        document.documentElement.removeEventListener('click', clickHandler, true);
        tabWrapper.removeEventListener('keydown', keyHandler, true); // Reset variables

        settings = null;
        tabWrapper = null;
      };
      /**
       * Setup the DOM with the proper attributes
       */


      publicAPIs.setup = function () {
        // Variables
        tabWrapper = document.querySelector(selector);
        if (!tabWrapper) return;
        var tabs = tabWrapper.querySelectorAll('a'); // Add role to wrapper

        tabWrapper.setAttribute('role', 'tablist'); // Add roles to tabs

        Array.prototype.forEach.call(tabs, function (tab) {
          // Get the tab content
          var content = document.querySelector(tab.hash);
          if (!content) return; // Setup the tab

          setupTab(tab, content, settings);
        });
      };
      /**
       * Toggle a tab based on an ID
       * @param  {String|Node} id The tab to toggle
       */


      publicAPIs.toggle = function (id) {
        // Get the tab
        var tab = id;

        if (typeof id === 'string') {
          tab = document.querySelector(selector + ' [role="tab"][href*="' + id + '"]');
        } // Toggle the tab


        toggle(tab);
      };
      /**
       * Handle click events
       */


      var clickHandler = function clickHandler(event) {
        // Only run on toggles
        var tab = event.target.closest(selector + ' [role="tab"]');
        if (!tab) return; // Prevent link behavior

        event.preventDefault(); // Toggle the tab

        toggle(tab);
      };
      /**
       * Handle keydown events
       */


      var keyHandler = function keyHandler(event) {
        // Only run if a tab is in focus
        var tab = document.activeElement;
        if (!tab.matches(selector + ' [role="tab"]')) return; // Only run for specific keys

        if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Up', 'Down', 'Left', 'Right', 'Home', 'End'].indexOf(event.key) < 0) return; // Switch tabs

        switchTabs(tab, event.key);
      };
      /**
       * Initialize the instance
       */


      var init = function init() {
        // Merge user options with defaults
        settings = extend(defaults, options || {}); // Setup the DOM

        publicAPIs.setup(); // Load a tab from the URL

        loadFromURL(selector); // Add event listeners

        document.documentElement.addEventListener('click', clickHandler, true);
        tabWrapper.addEventListener('keydown', keyHandler, true);
      }; //
      // Initialize and return the Public APIs
      //


      init();
      return publicAPIs;
    }; //
    // Return the Constructor
    //


    return Constructor;
  });

  if (typeof window !== 'undefined' && 'Tabby' in window) {
    // Tabs
    var tabSelectors = document.querySelectorAll('[data-tabs]');

    var _iterator = _createForOfIteratorHelper(_toConsumableArray(tabSelectors).entries()),
        _step;

    try {
      for (_iterator.s(); !(_step = _iterator.n()).done;) {
        var _step$value = _slicedToArray(_step.value, 2),
            i$1 = _step$value[0],
            tabs = _step$value[1];

        tabs.setAttribute("data-tabs-".concat(i$1), '');
        new Tabby("[data-tabs-".concat(i$1, "]"));
      }
    } catch (err) {
      _iterator.e(err);
    } finally {
      _iterator.f();
    }
  }

  /**
   * Detects if a scrollbar has been attached to the element provided.
   * Usage: $('#my_div1').hasOverflowY();
   *
   * TODO: Remove jQuery dependancy
   *
   * This is used in areas like tables, where we triger overflow styling when the table is too large to fit in the viewport.
   *
   * @author Ben Rush | https://github.com/bnjmnrsh
   * @version 0.0.1
   * @returns {boolean} true if there's a vertical/horisontal scrollbar, false otherwise.
   */
  jQuery.fn.hasOverflowY = function () {
    if ('undefined' !== this) {
      return this.get(0).scrollHeight > this.outerHeight();
    }
  };

  jQuery.fn.hasOverflowX = function () {
    if ('undefined' !== this) {
      return this.get(0).scrollWidth > this.outerWidth();
    }
  };

  /**
   * Allows css background images to be defined by srcset
   * https://aclaes.com/responsive-background-images-with-srcset-and-sizes/
   *
   * @author Alexandar Cales
   * @author Ben Rush | https://github.com/bnjmnrsh
   * @version 0.0.1
   * @class ResponsiveBackgroundImage
   */
  var ResponsiveBackgroundImage = /*#__PURE__*/function () {
    function ResponsiveBackgroundImage(element) {
      var _this = this;

      _classCallCheck(this, ResponsiveBackgroundImage);

      this.element = element;
      this.img = element.querySelector('img');
      this.src = '';
      this.img.addEventListener('load', function () {
        _this.update();
      });

      if (this.img.complete) {
        this.update();
      }
    }

    _createClass(ResponsiveBackgroundImage, [{
      key: "update",
      value: function update() {
        var src = 'undefined' !== typeof this.img.currentSrc ? this.img.currentSrc : this.img.src;

        if (this.src !== src) {
          this.src = src;
          this.element.style.backgroundImage = 'url("' + this.src + '")';
        }
      }
    }]);

    return ResponsiveBackgroundImage;
  }();

  var elements = document.querySelectorAll('[data-responsive-background-image]');

  for (var i = 0; i < elements.length; i++) {
    new ResponsiveBackgroundImage(elements[i]);
  }

  /**
   * @author David Walsh
   * @author Ben Rush | https://github.com/bnjmnrsh
   * @description Debounce function, attached to window so that it will be available outside of browserify. https://davidwalsh.name/javascript-debounce-function
   * @version 0.0.1
   * @param {*} func
   * @param {*} wait
   * @param {*} immediate
   * @returns function
   */
  window.debounce = function debounce(func, wait, immediate) {
    var timeout;
    return function () {
      var context = this;
      var args = arguments;

      var later = function later() {
        timeout = null;

        if (!immediate) {
          func.apply(context, args);
        }
      };

      var callNow = immediate && !timeout;
      clearTimeout(timeout);
      timeout = setTimeout(later, wait);

      if (callNow) {
        func.apply(context, args);
      }
    };
  };

  /**
   * Adds a .focus class to wrapping parent element of an input which has class .input-block.
   *
   * TODO: add listener to body or window and use event delegation.
   *
   * @author Ben Rush | https://github.com/bnjmnrsh
   * @version 0.0.1
   * @returns void
   */
  document.querySelectorAll('.v1-m-inputBlock input').forEach(function (input) {
    input.addEventListener('focus', function () {
      this.parentNode.classList.add('-is-focused');
    });
    input.addEventListener('blur', function () {
      if ('' == this.value) {
        this.parentNode.classList.remove('-is-focused');
      } else {
        this.parentNode.classList.add('-is-focused');
      }
    });
  });

  /**
   * Used in .v1-m-alert badges
   * This script adds a click event listener to button.-is-dismissible dismissible
   * Click then removes the parent element of the button.
   *
   * on the creation of new dismissible elements, dismissibleAlerts() can be called
   * to register the script.
   *
   * TODO: use event delegation on body or window instead of target element.
   *
   * @author Ben Rush | https://github.com/bnjmnrsh
   * @version 0.0.1
   * @returns void
   */

  (function () {
    window.dismissibleAlerts = function () {
      var dismissAlert = document.querySelectorAll('button.-is-dismissible');
      Array.from(dismissAlert).forEach(function (dismissible) {
        dismissible.addEventListener('click', function (event) {
          dismissible.parentNode.remove();
        });
      });
    };

    dismissibleAlerts();
  })();

  /**
   * Scale io graphs on small(ish) screens.
   *
   * TODO: Refactor, change graphic lib with that is able to scale dynamically.
   *
   * @description Minimum Viable Solution
   * @requires jQuery
   * @requires u-debounce.js
   * @author Ben Rush | https://github.com/bnjmnrsh
   * @version 0.0.1
   * @returns {void}
   */

  (function ($) {
    var wrapper = $('.v1-o-pageModel__content.-is-output');
    $('#main_table');

    if (wrapper.length) {
      var wrapperData = {
        size: {
          width: wrapper.width(),
          height: wrapper.height()
        }
      };
      var $el = $('.stage');
      var elHeight = $el.outerHeight();
      var elWidth = $el.outerWidth();
      var debounceDoScale = debounce(function () {
        wrapperData = {
          size: {
            width: wrapper.width(),
            height: wrapper.height()
          }
        };
        doScale(null, wrapperData);
      }, 250);
      doScale(null, wrapperData);
      window.addEventListener('resize', debounceDoScale);
    }
    /**
     * @param {object} event object
     * @param {object} ui object
     */


    function doScale(event, ui) {
      var scale = Math.min(ui.size.width / elWidth, ui.size.height / elHeight);
      var $offset = $('.v1-o-pageModel__outputMenu');
      var offsetHeight = $offset.outerHeight();

      if (1 > scale) {
        console.log('ui.size.height: ' + ui.size.height);
        console.log('elHeight: ' + elHeight);
        console.log('scale: ' + scale);
        console.log('elWidth * scale: ' + elWidth * scale);
        console.log('offsetHeight: ' + offsetHeight);
        $el.css({
          // "margin-top": -offsetHeight / 4,
          'margin-bottom': -offsetHeight / 2,
          transform: 'translate(-50%, -' + offsetHeight / 2.5 + 'px) scale(' + scale + ')',
          left: elWidth * scale / 2
        });
      } else {
        $el.removeAttr('style');
        $('.navigation').removeAttr('style');
      }
    }
  })(jQuery);

  /**
   * Scroll to top.
   * Add a scroll-to-top link to the bottom of the page.
   *
   * @author bnjmnRsh | bnjmnRsh@gmail.com
   * @version 0.0.1
   * @license MIT
   * @function uScrollToTop
   * @param {object} args - The arguments.
   * @param {string} args.targetEl - The element to target for placement of scroll-to-top link in the DOM.
   * @param {string} args.id - The css ID of the scroll-to-top link.
   * @param {string} args.classBase - The css class of the scroll-to-top link.
   * @param {string} args.classModifier - The css modifyer class of the scroll-to-top link when revealed.
   * @param {string} args.icon - The svg icon markup for the scroll-to-top link.
   * @param {string} args.bgColor - The background color in any valid CSS color scheme.
   * @param {string} args.iconFillColor - The icon fill color in any valid CSS color scheme (only effects the default icon).
   * @param {string} args.widthHeight - The width-height of the Scroll To Top link.
   * @param {string} args.xOffset - The x offset (from right) defaults to 0.5em.
   * @param {string} args.yOffset - The y offest (from bottom) defaults to 10%.
   * @param {number} args.scrollTrigger - Adjust when link -is-revealed, multiplier of window.innerHeight defaults to 0.25.
   * @param {boolean} args.cssOveride - Overide the default css with your own in your stylesheet.
   */
  function scrollToTop() {
    var args = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};

    var _Object$assign = Object.assign({
      targetEl: 'footer:last-of-type',
      id: '#stt',
      classBase: 'scroll-to-top',
      classModifier: '-is-revealed',
      iconFillColor: 'white',
      icon: '',
      bgColor: 'red',
      widthHeight: '40px',
      xOffset: '.5em',
      yOffset: '10%',
      scrollTrigger: 0.25,
      cssOveride: false
    }, args),
        targetEl = _Object$assign.targetEl,
        id = _Object$assign.id,
        classBase = _Object$assign.classBase;
        _Object$assign.classModifier;
        var iconFillColor = _Object$assign.iconFillColor,
        icon = _Object$assign.icon,
        bgColor = _Object$assign.bgColor,
        widthHeight = _Object$assign.widthHeight,
        xOffset = _Object$assign.xOffset,
        yOffset = _Object$assign.yOffset,
        scrollTrigger = _Object$assign.scrollTrigger,
        cssOveride = _Object$assign.cssOveride; // Set the location of the el to append to


    var target = document.querySelector(targetEl);
    if (!target) return; // Assemble icon

    if (!icon) {
      icon = "<svg class=\"icon-chevron-up\" xmlns=\"http://www.w3.org/2000/svg\" xml:space=\"preserve\" x=\"0px\" y=\"0px\" width=\"16px\" height=\"16px\" viewBox=\"0 0 16 16\" enable-background=\"new 0 0 16 16\"><polygon fill=\"".concat(iconFillColor, "\" points=\"8,2.8 16,10.7 13.6,13.1 8.1,7.6 2.5,13.2 0,10.7 \"/></svg>");
    } // Create the scroll-to-top link.


    var nStt = document.createElement('a');
    nStt.id = id.slice(1);
    nStt.classList.add(classBase);
    nStt.innerHTML = icon;
    nStt.href = '#';
    nStt.setAttribute('aria-description', 'Scroll to top of page');
    target.prepend(nStt); // Create default css.

    var nStyle = document.createElement('style');
    var sStyles = "\n#stt {\n  position: fixed;\n  right: 0;\n  bottom: ".concat(yOffset, ";\n  display: block;\n  display: flex;\n  flex-direction: row;\n  align-items: center;\n  justify-content: center;\n  width: 0;\n  height: 0;\n  margin: ").concat(xOffset, ";\n  overflow: none;\n  color: inherit;\n  text-decoration: none;\n  border: none;\n  border-radius: 50%;\n  outline: 0;\n  box-shadow: 0 3px 10px rgb(0 0 0 / 50%);\n  visibility: hidden;\n  cursor: grab;\n  opacity: 0;\n  transition: all 0.3s cubic-bezier(0.25, 0.25, 0, 1);\n  -webkit-tap-highlight-color: none;\n}\n#stt.-is-revealed {\n  width: ").concat(widthHeight, ";\n  height: ").concat(widthHeight, ";\n  background-color: ").concat(bgColor, ";\n  visibility: visible;\n  opacity: 1;\n}\n#stt.icon-chevron-up {\n  padding-bottom: .3em;\n}\n");

    if (!cssOveride) {
      nStyle.innerHTML = sStyles;
      document.head.prepend(nStyle);
    }
    /**
     * show-hide the stt link
     * Based on window.scrollY and window.innerHeight
     *
     * @param {event} e - event
     */


    var sttShowHide = function sttShowHide(e) {
      var el = document.querySelector(id);

      if (window.scrollY > window.innerHeight * scrollTrigger) {
        el.classList.add('-is-revealed');
      } else {
        el.classList.remove('-is-revealed');
      }
    };

    addEventListener('scroll', sttShowHide);
  }

  // !TODO these should be only loaded on the models landing page

  /**
   * Used for the Models Landing Page
   * Depends on globals navgoco, litty
   *
   * @discription Progressively enhance SVG
   * @author Ben Rush | https://github.com/bnjmnrsh
   * @version 0.0.1
   */
  $(document).ready(function () {
    var svg = document.querySelector('#v1-m-models-svg');
    var svgButtons = svg.querySelectorAll('a[role="button"]');
    svgButtons.forEach(function (button) {
      button.setAttribute('tabindex', '0');
      button.setAttribute('data-lightbox', '');
      button.setAttribute('href', button.getAttribute('data-href'));
    });
    /**
     * Handel clicks for lightbox, and passing custom options to lity for custom close button.
     */

    $(document).on('click', '[data-lightbox]', function (e) {
      var options = {
        esc: true,
        handler: null,
        template: "<div class=\"lity\" role=\"dialog\" tabindex=\"-1\"><div class=\"lity-wrap\" data-lity-close role=\"document\"><div class=\"lity-loader\" aria-hidden=\"true\">Loading...</div><div class=\"lity-container\"><div class=\"lity-content\"></div></div></div></div>"
      };
      lity(e.currentTarget.href.baseVal, options);
    });
  });
  /**
   * @discription Intialise accordian menu
   * @author Ben Rush | https://github.com/bnjmnrsh
   * @version 0.0.1
   */

  $(document).ready(function () {
    // Initialize navgoco with default options
    $('#adrs_models_nav').navgoco({
      caretHtml: '',
      accordion: false,
      openClass: 'open',
      save: true,
      cookie: {
        name: 'navgoco',
        expires: false,
        path: '/'
      },
      slide: {
        duration: 400,
        easing: 'swing'
      },
      // Add Active class to clicked menu item
      onClickAfter: 'active_menu_cb'
    });
    $('#collapseAll').click(function (e) {
      e.preventDefault();
      $('#adrs_models_nav').navgoco('toggle', false);
    });
    $('#expandAll').click(function (e) {
      e.preventDefault();
      $('#adrs_models_nav').navgoco('toggle', true);
    });
  });

  /**
   * main-public.js -> main-public-min.js
   *
   * @version 0.0.3
   * @requires jQuery
   */
  // Path of the current running script for realative path references
  window.ADRS = window.ADRS || {};
  window.ADRS.SOURCE_PATH = document.currentScript.src.replace(/\/[^\/]+$/, ''); // JS detection

  scrollToTop({
    bgColor: 'var(--theme-primary, red)',
    iconFillColor: 'var(--theme-white, white)',
    xOffset: '1em',
    yOffset: '7em',
    scrollTrigger: 0.5
  }); // Page specific scripts

})();
//# sourceMappingURL=public.js.map
