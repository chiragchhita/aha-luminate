angular.module 'ahaLuminateControllers'
  .controller 'CompanyPageCtrl', [
    '$scope'
    '$rootScope'
    '$location'
    '$filter'
    '$timeout'
    '$uibModal'
    'APP_INFO'
    'TeamraiserCompanyService'
    'TeamraiserTeamService'
    'TeamraiserParticipantService'
    'BoundlessService'
    'ZuriService'
    'TeamraiserRegistrationService'
    'TeamraiserCompanyPageService'
    'PageContentService'
    '$sce'
    ($scope, $rootScope, $location, $filter, $timeout, $uibModal, APP_INFO, TeamraiserCompanyService, TeamraiserTeamService, TeamraiserParticipantService, BoundlessService, ZuriService, TeamraiserRegistrationService, TeamraiserCompanyPageService, PageContentService, $sce) ->
      $scope.companyId = $location.absUrl().split('company_id=')[1].split('&')[0].split('#')[0]
      domain = $location.absUrl().split('/site/')[0]
      $rootScope.companyName = ''
      $scope.eventDate = ''
      $scope.totalTeams = ''
      $scope.teamId = ''
      $scope.studentsPledgedTotal = ''
      $scope.activity1amt = ''
      $scope.activity2amt = ''
      $scope.activity3amt = ''
      $scope.topClassRaised = []
      $scope.topClassStudents = []
      
      $scope.trustHtml = (html) ->
        return $sce.trustAsHtml(html)
      
      getLocalSponsors = ->
        if $scope.parentCompanyId and $scope.parentCompanyId isnt ''
          PageContentService.getPageContent 'ym_khc_local_sponsors_' + $scope.parentCompanyId
            .then (response) ->
              if response.search('No data') > -1
                $scope.localSponsorShow = false
              else
                img = response.split('/>')[0]
                if img is undefined
                  $scope.localSponsorShow = false
                else
                  alt = img.split('alt="')
                  src = alt[0].split('src="')
                  $scope.localSponsorShow = true
                  $scope.localSponsorImageSrc = src[1].split('"')[0]
                  $scope.localSponsorImageAlt = alt[1].split('"')[0]
      getLocalSponsors()
      $scope.$watch 'parentCompanyId', ->
        getLocalSponsors()
      
      ZuriService.getSchool $scope.companyId,
        error: (response) ->
          $scope.studentsPledgedTotal = 0
          $scope.activity1amt = 0
          $scope.activity2amt = 0
          $scope.activity3amt = 0
        success: (response) ->
          $scope.studentsPledgedTotal = response.data.studentsPledged
          studentsPledgedActivities = response.data.studentsPledgedByActivity
          if studentsPledgedActivities['1']
            $scope.activity1amt = studentsPledgedActivities['1'].count
          else
            $scope.activity1amt = 0
          if studentsPledgedActivities['2']
            $scope.activity2amt = studentsPledgedActivities['2'].count
          else
            $scope.activity2amt = 0
          if studentsPledgedActivities['3']
            $scope.activity3amt = studentsPledgedActivities['3'].count
          else
            $scope.activity3amt = 0
      
      setCompanyProgress = (amountRaised, goal) ->
        $scope.companyProgress = 
          amountRaised: if amountRaised then Number(amountRaised) else 0
          goal: if goal then Number(goal) else 0
        $scope.companyProgress.amountRaisedFormatted = $filter('currency')($scope.companyProgress.amountRaised / 100, '$').replace '.00', ''
        $scope.companyProgress.goalFormatted = $filter('currency')($scope.companyProgress.goal / 100, '$').replace '.00', ''
        $scope.companyProgress.percent = 0
        if not $scope.$$phase
          $scope.$apply()
        $timeout ->
          percent = $scope.companyProgress.percent
          if $scope.companyProgress.goal isnt 0
            percent = Math.ceil(($scope.companyProgress.amountRaised / $scope.companyProgress.goal) * 100)
          if percent > 100
            percent = 100
          $scope.companyProgress.percent = percent
          if not $scope.$$phase
            $scope.$apply()
        , 500
      
      getCompanyTotals = ->
        TeamraiserCompanyService.getCompanies 'company_id=' + $scope.companyId,
          error: ->
            # TODO
          success: (response) ->
            companies = response.getCompaniesResponse.company
            if not companies
              # TODO
            else
              companies = [companies] if not angular.isArray companies
              participantCount = companies[0].participantCount or '0'
              $scope.participantCount = Number participantCount
              totalTeams = companies[0].teamCount or '0'
              totalTeams = Number totalTeams
              eventId = companies[0].eventId
              amountRaised = companies[0].amountRaised
              goal = companies[0].goal
              name = companies[0].companyName
              coordinatorId = companies[0].coordinatorId
              $rootScope.companyName = name
              setCompanyProgress amountRaised, goal
              
              if coordinatorId and coordinatorId isnt '0' and eventId
                TeamraiserCompanyService.getCoordinatorQuestion coordinatorId, eventId
                  .then (response) ->
                    $scope.eventDate = response.data.coordinator?.event_date
                    if totalTeams is 1
                      $scope.teamId = response.data.coordinator?.team_id
      getCompanyTotals()
      
      $scope.companyTeams = {}
      setCompanyTeams = (teams, totalNumber) ->
        $scope.companyTeams.teams = teams or []
        totalNumber = totalNumber or 0
        $scope.companyTeams.totalNumber = Number totalNumber
        $scope.totalTeams = totalNumber
        if not $scope.$$phase
          $scope.$apply()
      getCompanyTeams = ->
        TeamraiserTeamService.getTeams 'team_company_id=' + $scope.companyId + '&list_page_size=500',
          error: ->
            setCompanyTeams()
          success: (response) ->
            companyTeams = response.getTeamSearchByInfoResponse.team
            if companyTeams
              companyTeams = [companyTeams] if not angular.isArray companyTeams
              angular.forEach companyTeams, (companyTeam) ->
                companyTeam.amountRaised = Number companyTeam.amountRaised
                companyTeam.amountRaisedFormatted = $filter('currency')(companyTeam.amountRaised / 100, '$').replace '.00', ''
              totalNumberTeams = response.getTeamSearchByInfoResponse.totalNumberResults
              setCompanyTeams companyTeams, totalNumberTeams
      getCompanyTeams()
      
      participantsString = ''
      $scope.companyParticipants = {}
      setCompanyParticipants = (participants, totalNumber, totalFundraisers) ->
        $scope.companyParticipants.participants = participants or []
        totalNumber = totalNumber or 0
        $scope.companyParticipants.totalNumber = Number totalNumber
        $scope.companyParticipants.totalFundraisers = Number totalFundraisers
        if not $scope.$$phase
          $scope.$apply()
        if participants and participants.length > 0
          angular.forEach participants, (participant, participantIndex) ->
            participantsString += '{name: "' + participant.name.first + ' ' + participant.name.last + '", raised: "' + participant.amountRaisedFormatted + '"}'
            if participantIndex < (participants.length - 1)
              participantsString += ', '
          companyParticipantsString = '{participants: [' + participantsString + '], totalNumber: ' + participants.length + '}'
          angular.element('.ym-school-animation iframe')[0].contentWindow.postMessage companyParticipantsString, domain
          angular.element('.ym-school-animation iframe').on 'load', ->
            angular.element('.ym-school-animation iframe')[0].contentWindow.postMessage companyParticipantsString, domain
      getCompanyParticipants = ->
        TeamraiserParticipantService.getParticipants 'team_name=' + encodeURIComponent('%') + '&first_name=' + encodeURIComponent('%%') + '&last_name=' + encodeURIComponent('%') + '&list_filter_column=team.company_id&list_filter_text=' + $scope.companyId + '&list_sort_column=total&list_ascending=false&list_page_size=50',
            error: ->
              setCompanyParticipants()
            success: (response) ->
              participants = response.getParticipantsResponse?.participant
              companyParticipants = []
              totalNumberParticipants = response.getParticipantsResponse?.totalNumberResults or '0'
              totalFundraisers = 0
              if participants
                participants = [participants] if not angular.isArray participants
                angular.forEach participants, (participant) ->
                  participant.amountRaised = Number participant.amountRaised
                  if participant.name?.first and participant.amountRaised > 0
                    participant.firstName = participant.name.first
                    participant.lastName = participant.name.last || ""
                    participant.name.last =  participant.lastName.substring(0, 1) + '.'
                    participant.fullName = participant.name.first + ' ' + participant.name.last
                    participant.amountRaisedFormatted = $filter('currency')(participant.amountRaised / 100, '$').replace '.00', ''
                    if participant.donationUrl
                      participant.donationFormId = participant.donationUrl.split('df_id=')[1].split('&')[0]
                    companyParticipants.push participant
                    totalFundraisers++
              setCompanyParticipants companyParticipants, totalNumberParticipants, totalFundraisers
      getCompanyParticipants()
      
      if $scope.consId
        TeamraiserRegistrationService.getRegistration
          success: (response) ->
            participantRegistration = response.getRegistrationResponse?.registration
            if participantRegistration
              $scope.participantRegistration = participantRegistration
      
      $scope.companyPagePhoto1 =
        defaultUrl: APP_INFO.rootPath + 'dist/ym-primary/image/company-default.jpg'
      
      $scope.editCompanyPhoto1 = ->
        delete $scope.updateCompanyPhoto1Error
        $scope.editCompanyPhoto1Modal = $uibModal.open
          scope: $scope
          templateUrl: APP_INFO.rootPath + 'dist/ym-primary/html/modal/editCompanyPhoto1.html'
      
      $scope.closeCompanyPhoto1Modal = ->
        delete $scope.updateCompanyPhoto1Error
        $scope.editCompanyPhoto1Modal.close()
      
      $scope.cancelEditCompanyPhoto1 = ->
        $scope.closeCompanyPhoto1Modal()
      
      $scope.deleteCompanyPhoto1 = (e) ->
        if e
          e.preventDefault()
        angular.element('.js--delete-company-photo-1-form').submit()
        false
      
      window.trPageEdit =
        uploadPhotoError: (response) ->
          errorResponse = response.errorResponse
          photoNumber = errorResponse.photoNumber
          errorCode = errorResponse.code
          errorMessage = errorResponse.message
          
          if errorCode is '5'
            window.location = luminateExtend.global.path.secure + 'UserLogin?NEXTURL=' + encodeURIComponent('TR?fr_id=' + $scope.frId + '&pg=company&company_id=' + $scope.companyId)
          else
            if photoNumber is '1'
              $scope.updateCompanyPhoto1Error =
                message: errorMessage
            if not $scope.$$phase
              $scope.$apply()
        uploadPhotoSuccess: (response) ->
          delete $scope.updateCompanyPhoto1Error
          if not $scope.$$phase
            $scope.$apply()
          successResponse = response.successResponse
          photoNumber = successResponse.photoNumber
          
          TeamraiserCompanyPageService.getCompanyPhoto
            error: (response) ->
              # TODO
            success: (response) ->
              photoItems = response.getCompanyPhotoResponse?.photoItem
              if photoItems
                photoItems = [photoItems] if not angular.isArray photoItems
                angular.forEach photoItems, (photoItem) ->
                  photoUrl = photoItem.customUrl
                  if photoItem.id is '1'
                    $scope.companyPagePhoto1.customUrl = photoUrl
              if not $scope.$$phase
                $scope.$apply()
              $scope.closeCompanyPhoto1Modal()
      
      $scope.companyPageContent =
        mode: 'view'
        serial: new Date().getTime()
        textEditorToolbar: [
          [
            'bold'
            'italics'
            'underline'
          ]
          [
            'ul'
            'ol'
          ]
          [
            'insertImage'
            'insertLink'
          ]
          [
            'undo'
            'redo'
          ]
        ]
        rich_text: angular.element('.js--default-page-content').html()
        ng_rich_text: angular.element('.js--default-page-content').html()
      
      $scope.editCompanyPageContent = ->
        richText = $scope.companyPageContent.ng_rich_text
        $richText = jQuery '<div />',
          html: richText
        richText = $richText.html()
        richText = richText.replace(/<strong>/g, '<b>').replace(/<strong /g, '<b ').replace /<\/strong>/g, '</b>'
        .replace(/<em>/g, '<i>').replace(/<em /g, '<i ').replace /<\/em>/g, '</i>'
        $scope.companyPageContent.ng_rich_text = richText
        $scope.companyPageContent.mode = 'edit'
        $timeout ->
          angular.element('[ta-bind][contenteditable]').focus()
        , 100
      
      $scope.resetCompanyPageContent = ->
        $scope.companyPageContent.ng_rich_text = $scope.companyPageContent.rich_text
        $scope.companyPageContent.mode = 'view'
      
      $scope.saveCompanyPageContent = (isRetry) ->
        richText = $scope.companyPageContent.ng_rich_text
        $richText = jQuery '<div />', 
          html: richText
        richText = $richText.html()
        richText = richText.replace /<\/?[A-Z]+.*?>/g, (m) ->
          m.toLowerCase()
        .replace(/<font>/g, '<span>').replace(/<font /g, '<span ').replace /<\/font>/g, '</span>'
        .replace(/<b>/g, '<strong>').replace(/<b /g, '<strong ').replace /<\/b>/g, '</strong>'
        .replace(/<i>/g, '<em>').replace(/<i /g, '<em ').replace /<\/i>/g, '</em>'
        .replace(/<u>/g, '<span style="text-decoration: underline;">').replace(/<u /g, '<span style="text-decoration: underline;" ').replace /<\/u>/g, '</span>'
        .replace /[\u00A0-\u9999\&]/gm, (i) ->
          '&#' + i.charCodeAt(0) + ';'
        .replace /&#38;/g, '&'
        .replace /<!--[\s\S]*?-->/g, ''
        TeamraiserCompanyPageService.updateCompanyPageInfo 'rich_text=' + encodeURIComponent(richText),
          error: ->
            # TODO
          success: (response) ->
            if response.teamraiserErrorResponse
              errorCode = response.teamraiserErrorResponse.code
              if errorCode is '2647' and not isRetry
                $scope.companyPageContent.ng_rich_text = response.teamraiserErrorResponse.body
                $scope.savePageContent true
            else
              isSuccess = response.updateCompanyPageResponse?.success is 'true'
              if not isSuccess
                # TODO
              else
                $scope.companyPageContent.rich_text = richText
                $scope.companyPageContent.ng_rich_text = richText
                $scope.companyPageContent.mode = 'view'
                if not $scope.$$phase
                  $scope.$apply()  
     
      $scope.getLeaderboards: ->
        BoundlessService.getLeaderboardRaised $scope.companyId,
          error: (response) ->
          success: (response) ->
            teachers = response.data.teachers
            angular.forEach teachers, (teacher) ->
              $scope.topClassRaised.push
                name: teacher.name
                grade: teacher.grade
                raised: teacher.raised
                msg: 'Amount Raised'

            i = $scope.topClassRaised.length
            while i < 5
              $scope.topClassRaised.push
                name: ''
                grade: ''
                raised: ''
                msg: ''
              i++ 
              
        BoundlessService.getLeaderboardStudents $scope.companyId,
          error: (response) ->
          success: (response) ->
            teachers = response.data.teachers
            angular.forEach teachers, (teacher) ->
              $scope.topClassStudents.push
                name: teacher.name
                grade: teacher.grade
                students: teacher.students
                msg: '# Online Students'

            i = $scope.topClassStudents.length
            while i < 5
              $scope.topClassStudents.push
                name: ''
                grade: ''
                raised: ''
                msg: ''
              i++ 
              
      
      $scope.getLeaderboards()
      
]
