angular.module 'trPcControllers'
  .controller 'socialViewCtrl', [
    '$rootScope'
    '$scope'
    '$sce'
    ($rootScope, $scope, $sce) ->
      urlPrefix = ''
      if $scope.tablePrefix == 'heartdev'
        urlPrefix = 'bfstage'
      else
        urlPrefix = 'bfapps1'
      consId = $scope.consId
      frId = $scope.frId
      url = 'https://' + urlPrefix + '.boundlessfundraising.com/applications/ahahw/social/app/ui/#/addsocial/' + consId + '/' + frId + '?source=PCSocial'
      $scope.socialURL = $sce.trustAsResourceUrl(url)
  ]
