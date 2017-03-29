angular.module 'ahaLuminateControllers'
  .controller 'CmsCtrl', [
    '$scope'
    '$timeout'
    ($scope, $timeout) ->
      initCarousel = ->
        owl = jQuery '.owl-carousel'
        owl.owlCarousel
          nav: true
          center: true
          loop: true
          stagePadding: 60
          margin: 60
          responsive:
            0:
              items: 1
            768:
              items: 3
          navText: [
            '<i class="fa fa-chevron-left" aria-hidden="true" />',
            '<i class="fa fa-chevron-right" aria-hidden="true" />'
          ]

      if angular.element('ym-carousel--internal')
        $timeout initCarousel, 1000


      toggleOpen = ->
        angular.element('.collapse').parent().removeClass('active')
        angular.element('.collapse.in').parent().addClass('active')

  ]