angular.module 'trPcApp', [
  'ngRoute'
  'ngSanitize'
  'ui.bootstrap'
  'cgBusy'
  'pascalprecht.translate'
  'textAngular'
  'formly'
  'formlyBootstrap'
  'trPcControllers'
]

angular.module 'trPcControllers', []

angular.module 'trPcApp'
  .constant 'NgPc_APP_INFO',
    version: '0.1.0'

angular.module 'trPcApp'
  .run [
    '$rootScope'
    'NgPc_APP_INFO'
    ($rootScope, NgPc_APP_INFO) ->
      $rootScope.Math = window.Math
      
      # get data from embed container
      $embedRoot = angular.element '[data-embed-root]'
      appVersion = $embedRoot.data('app-version') if $embedRoot.data('app-version') isnt ''
      if appVersion isnt NgPc_APP_INFO.version
        console.warn 'Angular TeamRaiser Participant Center: App version in HTML and JavaScript differ. Please confirm all files are up-to-date.'
      $rootScope.nonsecurePath = $embedRoot.data('nonsecure-path') if $embedRoot.data('nonsecure-path') isnt ''
      $rootScope.securePath = $embedRoot.data('secure-path') if $embedRoot.data('secure-path') isnt ''
      $rootScope.secureDomain = ''
      if $rootScope.securePath
        $rootScope.secureDomain = $rootScope.securePath.replace '/site/', '/'
      $rootScope.apiKey = $embedRoot.data('api-key') if $embedRoot.data('api-key') isnt ''
      if not $rootScope.apiKey
        new Error 'Angular TeamRaiser Participant Center: No Luminate Online API Key is defined.'
      $rootScope.frId = $embedRoot.data('fr-id') if $embedRoot.data('fr-id') isnt ''
      if not $rootScope.frId
        new Error 'Angular TeamRaiser Participant Center: No TeamRaiser ID is defined.'
      
      $rootScope.eventName = $embedRoot.data('event-name') if $embedRoot.data('event-name') isnt ''
      $rootScope.eventCity = $embedRoot.data('event-city') if $embedRoot.data('event-city') isnt ''
      $rootScope.eventState = $embedRoot.data('event-state') if $embedRoot.data('event-state') isnt ''
      $rootScope.eventDate = $embedRoot.data('event-date') if $embedRoot.data('event-date') isnt ''
      $rootScope.prevFrId = $embedRoot.data('prev-fr-id') if $embedRoot.data('prev-fr-id') isnt ''
      $rootScope.prevFrIdForShortcut = $embedRoot.data('prev-frid-for-shortcut') if $embedRoot.data('prev-fr-id') isnt ''
      $rootScope.locale = if $embedRoot.data('locale') is '' then 'en_US' else $embedRoot.data('locale')
      $rootScope.consId = $embedRoot.data('cons-id') if $embedRoot.data('cons-id') isnt ''
      $rootScope.authToken = $embedRoot.data('auth-token') if $embedRoot.data('auth-token') isnt ''
      $rootScope.daysToEvent = $embedRoot.data('days-to-event') if $embedRoot.data('days-to-event') isnt ''
      $rootScope.isSelfDonor = $embedRoot.data('is-self-donor') if $embedRoot.data('is-self-donor') isnt ''
      $rootScope.emailsSent = $embedRoot.data('emails-sent') if $embedRoot.data('emails-sent') isnt ''
      $rootScope.updatedProfile = $embedRoot.data('updated-profile') if $embedRoot.data('updated-profile') isnt ''
      $rootScope.survivorQ = $embedRoot.data('updated-survivor') if $embedRoot.data('updated-survivor') isnt ''
      $rootScope.viewMap = $embedRoot.data('view-map') if $embedRoot.data('view-map') isnt ''
      $rootScope.interactionTypeId = $embedRoot.data 'checklist-interaction-id' if $embedRoot.data('checklist-interaction-id') isnt ''
      $rootScope.frIdMultidate = $embedRoot.data 'tr-id-multidate' if $embedRoot.data('tr-id-multidate') isnt ''
      $rootScope.eventLocation = $embedRoot.data 'event-location' if $embedRoot.data('event-location') isnt ''
      $rootScope.hasBoundlessApp = $embedRoot.data('has-bf-app') if $embedRoot.data('has-bf-app') isnt ''
      $rootScope.isOnSocial = $embedRoot.data('is-on-social') if $embedRoot.data('is-on-social') isnt ''
      $rootScope.overFiveDonations = $embedRoot.data('donations-badge') if $embedRoot.data('donations-badge') isnt ''
  ]