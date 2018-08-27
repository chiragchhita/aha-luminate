angular.module 'ahaLuminateApp'
  .factory 'BoundlessService', [
    '$rootScope'
    '$http'
    '$sce'
    ($rootScope, $http, $sce) ->
      getLeaderboardRaised: (requestData) ->
        if $rootScope.tablePrefix is 'heartdev'
          url = 'https://khc.dev.ootqa.org/api/points/leaders/school/' + requestData + '/teachers/most-dollars?limit=5'
        else
          url = 'https://kidsheartchallenge.heart.org/api/points/leaders/school/' + requestData + '/teachers/most-dollars?limit=5'
        $http.jsonp($sce.trustAsResourceUrl(url), jsonpCallbackParam: 'callback')
          .then (response) ->
            response
          , (response) ->
            response
      
      getLeaderboardStudents: (requestData) ->
        if $rootScope.tablePrefix is 'heartdev'
          url = 'https://khc.dev.ootqa.org/api/points/leaders/school/' + requestData + '/teachers/most-students?limit=5'
        else
          url = 'https://kidsheartchallenge.heart.org/api/points/leaders/school/' + requestData + '/teachers/most-students?limit=5'
        $http.jsonp($sce.trustAsResourceUrl(url), jsonpCallbackParam: 'callback')
          .then (response) ->
            response
          , (response) ->
            response
      
      getBadges: (requestData) ->
        if $rootScope.tablePrefix is 'heartdev'
          url = 'https://khc.staging.ootqa.org/api/badges/student/' + requestData 
        else
          url = 'https://kidsheartchallenge.heart.org/api/badges/student/' + requestData
        $http.jsonp($sce.trustAsResourceUrl(url), jsonpCallbackParam: 'callback')
          .then (response) ->
            response
          , (response) ->
            response
      
      getRollupTotals: ->
        if $rootScope.tablePrefix is 'heartdev'
          url = 'https://khc.staging.ootqa.org/api/schools/totals/'
        else
          url = 'https://kidsheartchallenge.heart.org/api/schools/totals/'
        $http.jsonp($sce.trustAsResourceUrl(url), jsonpCallbackParam: 'callback')
          .then (response) ->
            response
          , (response) ->
            response
      
      logEmailSent: ->
        if $rootScope.tablePrefix is 'heartdev'
          url = 'https://khc.staging.ootqa.org/api/webhooks/student/emails-sent/' + $rootScope.frId + '/' + $rootScope.consId 
        else
          url = 'https://kidsheartchallenge.heart.org/api/webhooks/student/emails-sent/' + $rootScope.frId + '/' + $rootScope.consId
        $http.jsonp($sce.trustAsResourceUrl(url), jsonpCallbackParam: 'callback')
          .then (response) ->
            response
          , (response) ->
            response
      
      logPersonalPageUpdated: ->
        if $rootScope.tablePrefix is 'heartdev'
          url = 'https://khc.staging.ootqa.org/api/webhooks/student/personal-page-updated/' + $rootScope.frId + '/' + $rootScope.consId 
        else
          url = 'https://kidsheartchallenge.heart.org/api/webhooks/student/personal-page-updated/' + $rootScope.frId + '/' + $rootScope.consId
        $http.jsonp($sce.trustAsResourceUrl(url), jsonpCallbackParam: 'callback')
          .then (response) ->
            response
          , (response) ->
            response
  ]
