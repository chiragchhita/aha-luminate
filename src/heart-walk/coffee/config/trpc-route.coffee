angular.module 'trPcApp'
  .config [
    '$routeProvider'
    'APP_INFO'
    ($routeProvider, APP_INFO) ->
      $routeProvider
        .when '/dashboard',
          templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/view/dashboard.html'
          controller: 'DashboardViewCtrl'
        .when '/email',
          redirectTo: '/email/compose'
        .when '/email/compose/:messageType?/:messageId?',
          templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/view/emailCompose.html'
          controller: 'EmailComposeViewCtrl'
        .when '/email/message/:messageType',
          redirectTo: '/email/message/:messageType/list'
        .when '/email/message/:messageType/list',
          templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/view/emailMessageList.html'
          controller: 'EmailMessageListViewCtrl'
        .when '/email/contacts',
          redirectTo: '/email/contacts/email_rpt_show_all/list'
        .when '/email/contacts/:filter',
          redirectTo: '/email/contacts/:filter/list'
        .when '/email/contacts/:filter/list',
          templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/view/emailContactsList.html'
          controller: 'EmailContactsListViewCtrl'
        .when '/social',
          templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/view/social.html'
          controller: 'socialViewCtrl'
        .when '/profile',
          templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/view/consProfile.html'
          controller: 'ConsProfileViewCtrl'
        .when '/profile/questions',
          templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/view/surveyQuestions.html'
          controller: 'SurveyQuestionsViewCtrl'
        .when '/profile/options',
          templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/view/eventOptions.html'
          controller: 'EventOptionsViewCtrl'
        .when '/edit-page',
          templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/view/editPage.html'
          controller: 'EditPageViewCtrl'
        .when '/tools',
          templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/view/tools.html'
          controller: 'ToolsViewCtrl'
        .otherwise
          redirectTo: do ->
            # redirect PC1-style URLs
            $embedRoot = angular.element '[data-embed-root]'
            pcPage = $embedRoot.data('pc-page') if $embedRoot.data('pc-page') isnt ''
            if pcPage is 'mtype'
              '/email/compose'
            else
              '/dashboard'
  ]

angular.module 'trPcApp'
  .run [
    '$rootScope'
    '$location'
    '$route'
    '$uibModal'
    'APP_INFO'
    'AuthService'
    'TeamraiserEventService'
    'TeamraiserRegistrationService'
    'ThankYouRegService'
    ($rootScope, $location, $route, $uibModal, APP_INFO, AuthService, TeamraiserEventService, TeamraiserRegistrationService, ThankYouRegService) ->
      $rootScope.$on '$routeChangeStart', ($event, next, current) ->
        # set active tab
        if next.originalPath
          if next.originalPath.indexOf('/email') is 0
            $rootScope.activeTab = 1
          else if next.originalPath is '/edit-page'
            $rootScope.activeTab = 2
          else if next.originalPath is '/tools'
            $rootScope.activeTab = 3
          else
            $rootScope.activeTab = 0

        # ensure window is scrolled
        window.scrollTo 0, 0

        # redirect to a different route
        redirectRoute = (newRoute) ->
          $rootScope.$evalAsync ->
            $location.path newRoute

        # avoid race condition with reloading route
        reloadRoute = ->
          if $location.path() not in ['', next.originalPath]
            redirectRoute next.originalPath
          else
            $route.reload()

        # prompt logged out users to login
        showLoginModal = ->
          if not $rootScope.loginModal
            $rootScope.loginModal = $uibModal.open
              scope: $rootScope
              backdrop: 'static'
              templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/modal/login.html'

        # event config unknown
        if not $rootScope.teamraiserConfig
          $event.preventDefault()
          TeamraiserEventService.getConfig()
            .then ->
              if $rootScope.teamraiserConfig is -1
                # TODO
              else
                reloadRoute()

        # no event config
        else if $rootScope.teamraiserConfig is -1
          $event.preventDefault()
          # TODO

        # event closed
        else if $rootScope.teamraiserConfig.acceptingDonations isnt 'true' and $rootScope.teamraiserConfig.acceptingRegistrations isnt 'true'
          $event.preventDefault()
          # TODO: redirect to site homepage

        # login state unknown
        else if not $rootScope.consId
          $event.preventDefault()
          AuthService.getLoginState()
            .then ->
              if $rootScope.consId is -1
                showLoginModal()
              else
                $route.reload()

        # logged out
        else if $rootScope.consId is -1
          $event.preventDefault()
          showLoginModal()

        # no auth token
        else if not $rootScope.authToken
          $event.preventDefault()
          AuthService.getAuthToken()
            .then ->
              reloadRoute()

        # registration status unknown
        else if not $rootScope.participantRegistration
          $event.preventDefault()
          TeamraiserRegistrationService.getRegistration()
            .then ->
              if $rootScope.participantRegistration is -1
                # TODO
              else
                reloadRoute()

        # not registered
        else if $rootScope.participantRegistration is -1
          $event.preventDefault()
          # TODO: redirect to greeting page

        # event info unknown
        else if not $rootScope.eventInfo
          $event.preventDefault()
          TeamraiserEventService.getTeamraiser()
            .then (response) ->
              if $rootScope.eventInfo is -1
                # TODO
              else
                reloadRoute()

        # no event info
        else if $rootScope.eventInfo is -1
          $event.preventDefault()
          # TODO

        # not allowed to edit survey questions
        else if next.originalPath is '/profile/questions' and $rootScope.teamraiserConfig.personalSurveyEditAllowed isnt 'true'
          redirectRoute '/profile'
  ]
