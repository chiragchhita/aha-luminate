angular.module 'trPcControllers'
  .controller 'DashboardViewCtrl', [
    '$rootScope'
    '$scope'
    '$timeout'
    '$filter'
    '$location'
    '$httpParamSerializer'
    '$translate'
    '$uibModal'
    '$uibModalStack'
    'APP_INFO'
    'ConstituentService'
    'TeamraiserRecentActivityService'
    'TeamraiserRegistrationService'
    'TeamraiserProgressService'
    'TeamraiserGiftService'
    'TeamraiserParticipantService'
    'TeamraiserTeamService'
    'TeamraiserNewsFeedService'
    'TeamraiserCompanyService'
    'TeamraiserShortcutURLService'
    'ContactService'
    'TeamraiserSurveyResponseService'
    'TeamraiserEmailService'
    'FacebookFundraiserService'
    ($rootScope, $scope, $timeout, $filter, $location, $httpParamSerializer, $translate, $uibModal, $uibModalStack, APP_INFO, ConstituentService, TeamraiserRecentActivityService, TeamraiserRegistrationService, TeamraiserProgressService, TeamraiserGiftService, TeamraiserParticipantService, TeamraiserTeamService, TeamraiserNewsFeedService, TeamraiserCompanyService, TeamraiserShortcutURLService, ContactService, TeamraiserSurveyResponseService, TeamraiserEmailService, FacebookFundraiserService) ->
      $scope.dashboardPromises = []

      $scope.baseDomain = $location.absUrl().split('/site/')[0]

      constituentPromise = ConstituentService.getUser()
        .then (response) ->
          if response.data.errorResponse
            # TODO
          else
            $scope.constituent = response.data.getConsResponse
            if angular.equals({}, $scope.constituent.primary_address.street1) is true
              $scope.constituent.primary_address.street1 = ''
            if angular.equals({}, $scope.constituent.primary_address.street2) is true
              $scope.constituent.primary_address.street2 = ''
            if angular.equals({}, $scope.constituent.primary_address.city) is true
              $scope.constituent.primary_address.city = ''
            if angular.equals({}, $scope.constituent.primary_address.state) is true
              $scope.constituent.primary_address.state = ''
            if angular.equals({}, $scope.constituent.primary_address.zip) is true
              $scope.constituent.primary_address.zip = ''
            if angular.equals({}, $scope.constituent.mobile_phone) is true
              $scope.constituent.mobile_phone = ''
          response
      $scope.dashboardPromises.push constituentPromise

      $scope.getMessageCounts = (refresh) ->
        $scope.messageCounts = {}
        messageTypes = [
          'draft'
          'sentMessage'
        ]
        angular.forEach messageTypes, (messageType) ->
          apiMethod = 'get' + messageType.charAt(0).toUpperCase() + messageType.slice(1) + 's'
          messageCountPromise = TeamraiserEmailService[apiMethod] 'list_page_size=1'
            .then (response) ->
              $scope.messageCounts[messageType + 's'] = response.data[apiMethod + 'Response'].totalNumberResults
              response
          if not refresh
            $scope.dashboardPromises.push messageCountPromise
      $scope.getMessageCounts()

      $scope.recentActivity = {}
      $scope.getRecentActivity = ->
        recentActivityPromise = TeamraiserRecentActivityService.getRecentActivity()
          .then (response) ->
            recentActivityRecords = response.data.getRecentActivityResponse?.activityRecord
            if not recentActivityRecords
              $scope.recentActivity.records = []
            else
              recentActivityRecords = [recentActivityRecords] if not angular.isArray recentActivityRecords
              $scope.recentActivity.records = recentActivityRecords
            $scope.recentActivity.totalNumber = recentActivityRecords?.length or 0
            response
        $scope.dashboardPromises.push recentActivityPromise
      $scope.getRecentActivity()

      $scope.participantRank = {}
      $scope.topParticipants = {}
      topParticipantsPromise = TeamraiserParticipantService.getParticipants 'first_name=' + encodeURIComponent('%%%') + '&list_sort_column=total&list_ascending=false&list_page_size=500'
        .then (response) ->
          participants = response.data.getParticipantsResponse?.participant
          if not participants
            $scope.participantRank.rank = -1
            $scope.participantRank.totalNumber = 0
            $scope.topParticipants.participants = []
          else
            participants = [participants] if not angular.isArray participants
            topParticipants = []
            angular.forEach participants, (participant) ->
              amountRaised = participant.amountRaised or 0
              amountRaised = Number amountRaised
              if amountRaised isnt 0
                participant.amountRaisedFormatted = $filter('currency')(amountRaised / 100, '$', 0)
                topParticipants.push participant
            angular.forEach topParticipants, (topParticipant, topParticipantIndex) ->
              if ('' + topParticipant.consId) is ('' + $scope.consId)
                $scope.participantRank.rank = topParticipantIndex + 1
            if not $scope.participantRank.rank
              $scope.participantRank.rank = -1
            $scope.participantRank.totalNumber = Number response.data.getParticipantsResponse?.totalNumberResults or 0
            $scope.topParticipants.participants = topParticipants
          response
      $scope.dashboardPromises.push topParticipantsPromise

      $scope.newOfflineGift =
        first_name: ''
        last_name: ''
        gift_amount: ''
        name_error: false

      $scope.paymentTypeOptions = []

      if $scope.teamraiserConfig.offlineGiftTypes.cash is 'true'
        $scope.paymentTypeOptions.push
          value: 'cash'
          name: 'Cash'
      if $scope.teamraiserConfig.offlineGiftTypes.check is 'true'
        $scope.paymentTypeOptions.push
          value: 'check'
          name: 'Check'
      if $scope.teamraiserConfig.offlineGiftTypes.credit is 'true'
        $scope.paymentTypeOptions.push
          value: 'credit'
          name: 'Credit'
      if $scope.teamraiserConfig.offlineGiftTypes.later is 'true'
        $scope.paymentTypeOptions.push
          value: 'later'
          name: 'Pay Later'

      $scope.newOfflineGift.payment_type = $scope.paymentTypeOptions[0].value

      $scope.addOfflineGift = (giftType) ->
        if giftType is 'team'
          $scope.newOfflineGift.team_gift = 'true'
          $scope.newOfflineGift.team_id = $scope.participantRegistration.teamId
        else
          if $scope.newOfflineGift.team_gift
            delete $scope.newOfflineGift.team_gift
          if $scope.newOfflineGift.team_id
            delete $scope.newOfflineGift.team_id
        $scope.addOfflineGiftModal = $uibModal.open
          scope: $scope
          templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/modal/addOfflineGift.html'

      closeAddOfflineGiftModal = ->
        if $scope.newOfflineGift.team_gift
          delete $scope.newOfflineGift.team_gift
        if $scope.newOfflineGift.team_id
          delete $scope.newOfflineGift.team_id
        $scope.addOfflineGiftModal.close()

      $scope.cancelAddOfflineGift = ->
        closeAddOfflineGiftModal()

      $scope.submitOfflineGift = ->
        if not($scope.newOfflineGift.last_name?.length or $scope.newOfflineGift.first_name?.length)
          $scope.newOfflineGift.name_error=true
        else
          $scope.newOfflineGift.name_error=false
          TeamraiserGiftService.addGift $httpParamSerializer($scope.newOfflineGift)
            .then (response) ->
              if response.data.errorResponse
                # TODO
              else
                $scope.refreshFundraisingProgress()
                $scope.participantGifts.page = 1
                $scope.getGifts()
                if $scope.participantRegistration.teamId and $scope.participantRegistration.teamId isnt '-1'
                  $scope.teamMembers.page = 1
                  $scope.getTeamMembers()
                  $scope.teamGifts.page = 1
                  $scope.getTeamGifts()
                closeAddOfflineGiftModal()
                $scope.newOfflineGift.first_name= ''
                $scope.newOfflineGift.last_name= ''
                $scope.newOfflineGift.gift_amount= ''
                $scope.newOfflineGift.email= ''
                $scope.newOfflineGift.name_error= false

      #Profile checklist
      $scope.consProfilePromises = []

      $scope.updateUserProfile = ($event) ->
        $event.preventDefault()
        updateUserPromise = ConstituentService.update 'primary_address.street1=' + (if $scope.constituent.primary_address.street1 is null then '' else $scope.constituent.primary_address.street1) + '&primary_address.street2=' + (if $scope.constituent.primary_address.street2 is null then '' else $scope.constituent.primary_address.street2) + '&primary_address.city=' + (if $scope.constituent.primary_address.city is null then '' else $scope.constituent.primary_address.city) + '&primary_address.state=' + (if $scope.constituent.primary_address.state is null then '' else $scope.constituent.primary_address.state) + '&primary_address.zip=' + (if $scope.constituent.primary_address.zip is null then '' else $scope.constituent.primary_address.zip) + '&primary_address.country=' + (if $scope.constituent.primary_address.country is null then '' else $scope.constituent.primary_address.country) + '&mobile_phone=' + (if $scope.constituent.mobile_phone is null then '' else $scope.constituent.mobile_phone)
          .then (response) ->
            if response.data.errorResponse?
              $scope.updateProfileSuccess = false
              $scope.updateProfileFailure = true
              $scope.updateProfileFailureMessage = response.data.errorResponse.message or "An unexpected error occurred while updating your profile."
            else
              $scope.updateProfileSuccess = true
              $scope.updateProfileFailure = false
            response
        $scope.dashboardPromises.push updateUserPromise

      $scope.resetProfileAlerts = ->
        $scope.updateProfileSuccess = false
        $scope.updateProfileFailure = false
        $scope.updateProfileFailureMessage = ''
        true
      $scope.resetProfileAlerts()

      #Event questions
      $scope.surveyResponsePromises = []

      $scope.sqvm =
        surveyFields: []
        surveyModel: {}
        updateSurveyResponses: $scope.updateSurveyResponses

      $scope.getSurveyResponses = ->
        getSurveyResponsesPromise = TeamraiserSurveyResponseService.getSurveyResponses()
          .then (response) ->

            surveyResponses = response.data.getSurveyResponsesResponse.responses
            surveyResponses = [surveyResponses] if not angular.isArray surveyResponses
            angular.forEach surveyResponses, (surveyResponse) ->
              if surveyResponse
                thisField =
                  type: null
                  questionKey: if surveyResponse.key is null then 'question_' + surveyResponse.questionId else 'question_key_' + surveyResponse.key
                  data:
                    dataType: surveyResponse.questionType
                  templateOptions:
                    label: surveyResponse.questionText
                    required: surveyResponse.questionRequired is 'true'
                switch surveyResponse.questionType
                  when 'Caption'
                    thisField.type = 'caption'
                  when 'DateQuestion'
                    thisField.type = 'datepicker'
                  when 'NumericValue'
                    thisField.type = 'input'
                  when 'ShortTextValue'
                    thisField.type = 'input'
                    thisField.templateOptions.maxChars = 40
                  when 'TextValue'
                    thisField.type = 'input'
                    thisField.templateOptions.maxChars = 255
                  when 'LargeTextValue'
                    thisField.type = 'textarea'
                  when 'TrueFalse'
                    thisField.type = 'select'
                  when 'YesNo'
                    thisField.type = 'select'
                  when 'MultiSingle'
                    thisField.type = 'select'
                  when 'ComboChoice'
                    thisField.type = 'typeahead'
                  when 'Categories'
                    thisField.type = 'checkbox'
                  when 'MultiMulti'
                    thisField.type = 'checkbox'
                  when 'MultiSingleRadio'
                    thisField.type = 'radio'
                  when 'RatingScale'
                    thisField.type = 'radio'
                  when 'Captcha'
                    thisField.type = 'captcha'
                  when 'HiddenInterests'
                    thisField.type = 'hidden'
                  when 'HiddenTextValue'
                    thisField.type = 'hidden'
                  when 'HiddenTrueFalse'
                    thisField.type = 'hidden'
                  else thisField.type = 'input'
                thisField.type = 'hidden' if surveyResponse.isHidden is 'true'
                if surveyResponse.questionAnswer
                  thisField.templateOptions.options = []
                  angular.forEach surveyResponse.questionAnswer, (choice) ->
                    thisField.templateOptions.options.push
                      name: choice.label
                      value: choice.value

                if thisField.questionKey isnt 'no_key_assigned'
                  $scope.sqvm.surveyFields.push thisField
                  if surveyResponse.responseValue is 'User Provided No Response'
                    $scope.sqvm.surveyModel[thisField.questionKey] = null
                  else
                    $scope.sqvm.surveyModel[thisField.questionKey] = surveyResponse.responseValue

            $scope.sqvm.originalFields = angular.copy($scope.sqvm.surveyFields)
            response
        $scope.dashboardPromises.push getSurveyResponsesPromise
      $scope.getSurveyResponses()

      $scope.updateSurveyResponses = ($event) ->
        $event.preventDefault()
        updateSurveyResponsesPromise = TeamraiserSurveyResponseService.updateSurveyResponses $httpParamSerializer($scope.sqvm.surveyModel)
        .then (response) ->
            if response.data?.errorResponse?
              $scope.updateSurveySuccess = false
              $scope.updateSurveyFailure = true
              if response.data?.errorResponse?.message?
                $scope.updateSurveyFailureMessage = response.data.errorResponse.message
              else
                $translate 'survey_save_failure'
                  .then (translation) ->
                    $scope.updateSurveyFailureMessage = translation
                  , (translationId) ->
                    $scope.updateSurveyFailureMessage = translationId
            else
              $scope.updateSurveySuccess = true
              $scope.updateSurveyFailure = false
            response
        $scope.dashboardPromises.push updateSurveyResponsesPromise

      $scope.resetSurveyAlerts = ->
        $scope.updateSurveySuccess = false
        $scope.updateSurveyFailure = false
        $scope.updateSurveyFailureMessage = ''
      $scope.resetSurveyAlerts()

      $scope.updateTellUsWhy = ($event) ->
        $scope.updateSurveyResponses($event)

      logUserInt = (subject, body) ->
        ConstituentService.logInteraction 'interaction_type_id='+ $rootScope.interactionTypeId + '&interaction_subject=' + subject + '&interaction_body=' + body
          .then (response) ->
            if response.data.updateConsResponse?.message
              #todo - confirmation
            else
              console.log 'log interaction failed'

      $scope.userInteractions = {
        facebookFundraiser: 0
        page: 0
        donate: 0
        email: 0
        why: 0
        social: 0
        profile: 0
        goal1: 0
        goal2: 0
      }
      $scope.profileChecklistItems = {
        mobile: 0
        why: 0
        street: 0
        years: 0
      }
      GetUserInt = ->
        userInteractionsPromise = ConstituentService.getUserInteractions '&list_page_size=50&interaction_type_id=' + $rootScope.interactionTypeId
          .then (response) ->
            if not response.data.errorResponse
              interactions = response.data.getUserInteractionsResponse?.interaction
              if interactions
                interactions = [interactions] if not angular.isArray interactions
                if interactions.length > 0
                  angular.forEach interactions, (interaction) ->
                    if interaction.note
                      if interaction.note.text
                        interactionNote = Number(interaction.note.text)
                        if $scope.frId is interactionNote
                          switch interaction.subject
                            when 'facebookFundraiser'
                              $scope.userInteractions.facebookFundraiser = 1
                            when 'page'
                              $scope.userInteractions.page = 1
                            when 'donate'
                              $scope.userInteractions.donate = 1
                            when 'email'
                              $scope.userInteractions.email = 1
                            when 'why'
                              $scope.userInteractions.why = 1
                            when 'social'
                              $scope.userInteractions.social = 1
                            when 'profile'
                              $scope.userInteractions.profile = 1
                            when 'goal1'
                              $scope.userInteractions.goal1 = 1
                            when 'goal2'
                              $scope.userInteractions.goal2 = 1
              if $scope.sqvm.surveyModel.question_key_what_is_why isnt null
                $scope.profileChecklistItems.why = 1
              if $scope.sqvm.surveyModel.question_key_hw_years_participated
                $scope.profileChecklistItems.years = 1
              if $scope.constituent.mobile_phone
                $scope.profileChecklistItems.mobile = 1
              if $scope.constituent.primary_address.street1 and $scope.constituent.primary_address.city and $scope.constituent.primary_address.state and $scope.constituent.primary_address.zip and $scope.constituent.primary_address.country isnt '' | null
                $scope.profileChecklistItems.street = 1
              $scope.profileProgress = $scope.profileChecklistItems.mobile + $scope.profileChecklistItems.years + $scope.profileChecklistItems.street + $scope.profileChecklistItems.why
              if $scope.profileProgress is 0
                $scope.profilePercent = 0
              else
                $scope.profilePercent = $scope.profileProgress / 4 * 100
              if $scope.facebookFundraisersEnabled and $rootScope.facebookFundraiserId and $rootScope.facebookFundraiserId isnt ''
                $scope.userInteractions.facebookFundraiser = 1
                logUserInt 'facebookFundraiser', $scope.frId
              if $rootScope.updatedProfile is 'TRUE' and $scope.userInteractions.page is 0
                $scope.userInteractions.page = 1
                logUserInt 'page', $scope.frId
              if $rootScope.isSelfDonor is 'TRUE' and $scope.userInteractions.donate is 0
                $scope.userInteractions.donate = 1
                logUserInt 'donate', $scope.frId
              if $rootScope.hasBoundlessApp is 'true' and $scope.userInteractions.social is 0
                $scope.userInteractions.social = 1
                logUserInt 'social', $scope.frId
              if $scope.messageCounts.sentMessages > 0 and $scope.userInteractions.email is 0
                $scope.userInteractions.email = 1
                logUserInt 'email', $scope.frId
              if $scope.sqvm.surveyModel.question_key_what_is_why isnt null and $scope.userInteractions.why is 0
                $scope.userInteractions.why = 1
                logUserInt 'why', $scope.frId
              if $scope.profileChecklistItems.why is 1 and $scope.profileChecklistItems.years is 1 and $scope.profileChecklistItems.mobile is 1 and $scope.userInteractions.profile is 0
                $scope.userInteractions.profile = 1
                logUserInt 'profile', $scope.frId
              if $scope.participantProgress.percent >= 100 and $scope.userInteractions.goal1 is 0
                $scope.userInteractions.goal1 = 1
                logUserInt 'goal1', $scope.frId
              runLBroutes()
            response
        $scope.dashboardPromises.push userInteractionsPromise
      $timeout ->
        GetUserInt()
      , 750

      runLBroutes = ->
        skipLBs = 1
        $scope.dashboardGreeting = 'default'
        PCLogin = sessionStorage.getItem 'PCLogin'
        if not PCLogin
          skipLBs = 0
        sessionStorage.setItem 'PCLogin', 'yes'
        if $rootScope.participantRegistration.lastPC2Login is '0' and $rootScope.isSelfDonor != "TRUE"
          $scope.dashboardGreeting = 'page'
          if skipLBs is 0
            $scope.LBthankYouRegisteringModal = $uibModal.open
              scope: $scope
              templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/modal/LBthankYouRegistering.html'
            $timeout ->
              document.getElementById('LBmakeDonation').onclick = ->
                _gaq.push(['t2._trackEvent', 'HW PC', 'click', 'Heck Yeah! - thank you for registering lightbox'])
            , 500
        else if $scope.facebookFundraisersEnabled and $scope.userInteractions.facebookFundraiser is 0
          $scope.dashboardGreeting = 'facebookFundraiser'
          if skipLBs is 0
            $scope.LBwelcomeBackModal = $uibModal.open
              scope: $scope
              templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/modal/LBfacebookFundraiser.html'
        else if $scope.userInteractions.page is 0
          $scope.dashboardGreeting = 'page'
          if skipLBs is 0
            $scope.LBwelcomeBackModal = $uibModal.open
              scope: $scope
              templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/modal/LBwelcomeBack.html'
            $timeout ->
              document.getElementById('update_my_story_welcome_back_lb').onclick = ->
                _gaq.push(['t2._trackEvent', 'HW PC', 'click', 'Update my story - welcome back lightbox'])
            , 500
        else if $scope.userInteractions.donate is 0
          $scope.dashboardGreeting = 'donate'
          if skipLBs is 0
            $scope.LBdonateModal = $uibModal.open
              scope: $scope
              templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/modal/LBdonate.html'
            $timeout ->
              #document.getElementById('LBmakeDonation').onclick = ->
                #_gaq.push(['t2._trackEvent', 'HW PC', 'click', 'Make A Donation - donate lightbox'])
              document.getElementById('LBmakeDonationHoliday').onclick = ->
                _gaq.push(['t2._trackEvent', 'HW PC', 'click', 'Download Healthy Eating Guide'])
              document.getElementById('LBmakeDonationHoliday2').onclick = ->
                _gaq.push(['t2._trackEvent', 'HW PC', 'click', 'Download Healthy Eating Guide'])
            , 500
        else if $scope.userInteractions.email is 0
          $scope.dashboardGreeting = 'email'
          if skipLBs is 0
            $scope.LBemailModal = $uibModal.open
              scope: $scope
              templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/modal/LBemail.html'
            $timeout ->
              document.getElementById('LBsendEmail').onclick = ->
                _gaq.push(['t2._trackEvent', 'HW PC', 'click', 'Send Email - email lightbox'])
            , 500
        else if $scope.userInteractions.why is 0
          $scope.dashboardGreeting = 'why'
          if skipLBs is 0
            $scope.LBwhyModal = $uibModal.open
              scope: $scope
              templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/modal/LBwhy.html'
        else if $scope.userInteractions.social is 0
          $scope.dashboardGreeting = 'social'
          if skipLBs is 0
            $scope.LBsocialModal = $uibModal.open
              scope: $scope
              templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/modal/LBsocial.html'
        else if $scope.userInteractions.profile is 0
          $scope.dashboardGreeting = 'profile'
          if skipLBs is 0
            $scope.LBprofileModal = $uibModal.open
              scope: $scope
              templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/modal/LBprofile.html'
            $timeout ->
              document.getElementById('LBprofileWhy').onclick = ->
                _gaq.push(['t2._trackEvent', 'HW PC', 'click', 'Whats your why - profile lightbox'])
            , 500
        else if $scope.userInteractions.goal1 is 0 and $scope.participantProgress.percent >= 50
          $scope.dashboardGreeting = 'goal1'
          if skipLBs is 0
            $scope.LBgoal1Modal = $uibModal.open
              scope: $scope
              templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/modal/LBgoal1.html'
        else if $scope.userInteractions.goal2 is 0 and $scope.participantProgress.percent >= 100
          $scope.dashboardGreeting = 'goal2'
          if skipLBs is 0
            $scope.LBgoal2Modal = $uibModal.open
              scope: $scope
              templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/modal/LBgoal2.html'

      runHeaderCheck = ->
        if $scope.userInteractions.facebookFundraiser is 0
          $scope.dashboardGreeting = 'facebookFundraiser'
        else if $scope.userInteractions.page is 0
          $scope.dashboardGreeting = 'page'
        else if $scope.userInteractions.donate is 0
          $scope.dashboardGreeting = 'donate'
        else if $scope.userInteractions.email is 0
          $scope.dashboardGreeting = 'email'
        else if $scope.userInteractions.why is 0
          $scope.dashboardGreeting = 'why'
        else if $scope.userInteractions.social is 0
          $scope.dashboardGreeting = 'social'
        else if $scope.userInteractions.profile is 0
          $scope.dashboardGreeting = 'profile'
        else if $scope.userInteractions.goal1 is 0 and $scope.participantProgress.percent >= 50
          $scope.dashboardGreeting = 'goal1'
        else if $scope.userInteractions.goal2 is 0 and $scope.participantProgress.percent >= 100
          $scope.dashboardGreeting = 'goal2'
        else
          $scope.dashboardGreeting = 'default'

      $scope.LBgoalOneSubmit = ->
        logUserInt 'goal1', $scope.frId
        $location.path '/email/compose'

      $scope.LBgoalTwoSubmit = ->
        logUserInt 'goal2', $scope.frId
        $scope.LBgoal2Modal.close()
        $scope.editGoal 'Participant'

      $scope.notRightNow = ->
        $uibModalStack.dismissAll()

      $scope.sendGAEvent = (event) ->
        _gaq.push(['t2._trackEvent', 'HW PC', 'click', event])

      $scope.LBskip = (interaction) ->
        logUserInt interaction, $scope.frId
        $scope.userInteractions[interaction] = 1
        $uibModalStack.dismissAll()
        runHeaderCheck()

      $scope.scrollToFacebookFundraiser = ->
        $timeout ->
          if jQuery('.js--facebook-fundraiser-uncompleted-section').length > 0
            jQuery('html, body').animate
              scrollTop: jQuery('.js--facebook-fundraiser-uncompleted-section').offset().top - 150
            , 250
          else if jQuery('.js--facebook-fundraiser-completed-section').length > 0
            jQuery('html, body').animate
              scrollTop: jQuery('.js--facebook-fundraiser-completed-section').offset().top - 150
            , 250

      $scope.goSocial = ->
        if $rootScope.device.mobileType == 'android'
          window.location = 'https://play.google.com/store/apps/details?id=com.aha.hw.communicator'
        else if $rootScope.device.mobileType == 'ios'
          window.location = 'https://itunes.apple.com/us/app/heart-walk/id451276834?ls=1&mt=8'
        else
          window.location = 'PageServer?pagename=heartwalk_fundraising_tools&amp;pc2_page=center&amp;fr_id=' + $scope.frId + '#/social'

      $scope.profileProgress = 0
      $scope.profileChecklist = ->
        $scope.resetSurveyAlerts()
        $scope.resetProfileAlerts()
        $scope.LBprofileModal = $uibModal.open
          scope: $scope
          templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/modal/LBprofile.html'
        $timeout ->
          document.getElementById('LBprofileWhy').onclick = ->
            _gaq.push(['t2._trackEvent', 'HW PC', 'click', 'Whats your why - profile lightbox'])
        , 500

      $scope.reLaunchprofileChecklist = ->
        $scope.LBprofileModal = $uibModal.open
          scope: $scope
          templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/modal/LBprofile.html'
          $timeout ->
            document.getElementById('LBprofileWhy').onclick = ->
              _gaq.push(['t2._trackEvent', 'HW PC', 'click', 'Whats your why - profile lightbox'])
          , 500

      reCheckProfileItems = ->
        $scope.profileChecklistItems = {
          mobile: 0
          why: 0
          street: 0
          years: 0
        }
        if $scope.sqvm.surveyModel.question_key_what_is_why isnt null
          $scope.profileChecklistItems.why = 1
        if $scope.sqvm.surveyModel.question_key_hw_years_participated
          $scope.profileChecklistItems.years = 1
        if $scope.constituent.mobile_phone
          $scope.profileChecklistItems.mobile = 1
        if $scope.constituent.primary_address.street1 and $scope.constituent.primary_address.city and $scope.constituent.primary_address.state and $scope.constituent.primary_address.zip and $scope.constituent.primary_address.country isnt '' | null
          $scope.profileChecklistItems.street = 1
        $scope.profileProgress = $scope.profileChecklistItems.mobile + $scope.profileChecklistItems.years + $scope.profileChecklistItems.street + $scope.profileChecklistItems.why
        if $scope.profileProgress is 0
          $scope.profilePercent = 0
        else if $scope.profileProgress is 4
          $scope.profilePercent = 100
          $scope.userInteractions.profile = 1
          runHeaderCheck()
        else
          $scope.profilePercent = $scope.profileProgress / 4 * 100
        $scope.reLaunchprofileChecklist()

      $scope.submittedMobile = false
      $scope.updateEditMobile = ($event) ->
        $scope.LBmobileProfileModal.close()
        $scope.updateUserProfile($event)
        $timeout ->
          reCheckProfileItems()
        , 250

      $scope.updateEditYears = ($event) ->
        $scope.LByearsProfileModal.close()
        $scope.updateSurveyResponses($event)
        $timeout ->
          reCheckProfileItems()
        , 250

      $scope.submittedZip = false
      $scope.updateEditStreet = ($event) ->
        $scope.LBstreetProfileModal.close()
        $scope.updateUserProfile($event)
        $timeout ->
          reCheckProfileItems()
        , 250

      $scope.LBprofileLinks = (section) ->
        switch section
          #save for future Why Profile Box
          #when 'why'
            #console.log 'it is why'
            #$scope.LBprofileModal.close()
            #$scope.LBwhyVideoProfileModal = $uibModal.open
              #scope: $scope
              #templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/modal/profileWhyVideo.html'
            #$scope.cancelEditPersonalVideo = ->
              #$scope.LBwhyVideoProfileModal.close()
          when 'mobile'
            $scope.LBprofileModal.close()
            $scope.LBmobileProfileModal = $uibModal.open
              scope: $scope
              templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/modal/profileMobile.html'
            $scope.cancelEditMobile = ->
              $scope.LBmobileProfileModal.close()
              reCheckProfileItems()
          when 'street'
            $scope.LBprofileModal.close()
            $scope.LBstreetProfileModal = $uibModal.open
              scope: $scope
              templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/modal/profileStreet.html'
            $scope.cancelEditStreet = ->
              $scope.LBstreetProfileModal.close()
              reCheckProfileItems()
          when 'years'
            $scope.LBprofileModal.close()
            $scope.LByearsProfileModal = $uibModal.open
              scope: $scope
              templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/modal/profileYears.html'
            $scope.cancelEditYears = ->
              $scope.LByearsProfileModal.close()
              reCheckProfileItems()

      $scope.editSurvivor = ->
        $scope.LBsurvivorModal = $uibModal.open
          scope: $scope
          templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/modal/editSurvivor.html'
        $scope.cancelEditSurvivor = ->
          $scope.LBsurvivorModal.close()

      $scope.updateEditSurvivor = ($event) ->
        $scope.LBsurvivorModal.close()
        $scope.updateSurveyResponses($event)

      $scope.editTeamName = ->
        $scope.editTeamNameModal = $uibModal.open
          scope: $scope
          templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/modal/editTeamName.html'
        $scope.cancelEditTeamName = ->
          $scope.editTeamNameModal.close()

      $scope.updateTeamNameInput =
        name: ''

      $scope.updateTeamName = ->
        dataStr = 'team_name=' + escape($scope.updateTeamNameInput.name)
        updateGoalPromise = TeamraiserTeamService.updateTeamInformation dataStr
          .then (response) ->
            if response.data?.errorResponse?
              $scope.updateTeamNameFailure = true
              if response.data.errorResponse.message
                $scope.updateTeamNameFailureMessage = response.data.errorResponse.message
              else
                $translate 'team_edit_team_name_label'
                  .then (translation) ->
                    $scope.updateTeamNameFailureMessage = translation
                  , (translationId) ->
                    $scope.updateTeamNameFailureMessage = translationId
            else
              $scope.editTeamNameModal.close()
              teamInfoPromise = TeamraiserTeamService.getTeam()
                .then (response) ->
                  team = response.data.getTeamSearchByInfoResponse?.team
                  if team
                    $scope.teamInfo = team
            response
        $scope.dashboardPromises.push updateGoalPromise

      if $scope.facebookFundraisersEnabled and $rootScope.facebookFundraiserId and $rootScope.facebookFundraiserId isnt ''
        $rootScope.facebookFundraiserConfirmedStatus = 'pending'
        FacebookFundraiserService.confirmFundraiserStatus()
          .then (response) ->
            if not response.data.status?.active
              delete $rootScope.facebookFundraiserId
              $rootScope.facebookFundraiserConfirmedStatus = 'deleted'
            else
              $rootScope.facebookFundraiserConfirmedStatus = 'confirmed'

      $scope.participantProgress =
        raised: 0
        raisedFormatted: '$0'
        goal: 0
        goalFormatted: '$0'
        percent: 0
      if $scope.participantRegistration.teamId and $scope.participantRegistration.teamId isnt '-1'
        $scope.teamProgress =
          raised: 0
          raisedFormatted: '$0'
          goal: 0
          goalFormatted: '$0'
          percent: 0
      if $scope.participantRegistration.companyInformation and $scope.participantRegistration.companyInformation.companyId and $scope.participantRegistration.companyInformation.companyId isnt -1
        $scope.companyProgress =
          raised: 0
          raisedFormatted: '$0'
          goal: 0
          goalFormatted: '$0'
          percent: 0
      $scope.refreshFundraisingProgress = ->
        fundraisingProgressPromise = TeamraiserProgressService.getProgress()
          .then (response) ->
            participantProgress = response.data.getParticipantProgressResponse?.personalProgress
            if participantProgress
              participantProgress.raised = Number participantProgress.raised
              participantProgress.raisedFormatted = if participantProgress.raised then $filter('currency')(participantProgress.raised / 100, '$', 0) else '$0'
              participantProgress.goal = Number participantProgress.goal
              participantProgress.goalFormatted = if participantProgress.goal then $filter('currency')(participantProgress.goal / 100, '$', 0) else '$0'
              participantProgress.percent = 0
              $scope.participantProgress = participantProgress
              $timeout ->
                percent = $scope.participantProgress.percent
                if $scope.participantProgress.goal isnt 0
                  percent = Math.ceil(($scope.participantProgress.raised / $scope.participantProgress.goal) * 100)
                if percent > 100
                  percent = 100
                $scope.participantProgress.percent = percent
              , 500
            if $scope.participantRegistration.teamId and $scope.participantRegistration.teamId isnt '-1'
              teamProgress = response.data.getParticipantProgressResponse?.teamProgress
              if teamProgress
                teamProgress.raised = Number teamProgress.raised
                teamProgress.raisedFormatted = if teamProgress.raised then $filter('currency')(teamProgress.raised / 100, '$', 0) else '$0'
                teamProgress.goal = Number teamProgress.goal
                teamProgress.goalFormatted = if teamProgress.goal then $filter('currency')(teamProgress.goal / 100, '$', 0) else '$0'
                teamProgress.percent = 0
                $scope.teamProgress = teamProgress
                $timeout ->
                  percent = $scope.teamProgress.percent
                  if $scope.teamProgress.goal isnt 0
                    percent = Math.ceil(($scope.teamProgress.raised / $scope.teamProgress.goal) * 100)
                  if percent > 100
                    percent = 100
                  $scope.teamProgress.percent = percent
                , 500
            if $scope.participantRegistration.companyInformation and $scope.participantRegistration.companyInformation.companyId and $scope.participantRegistration.companyInformation.companyId isnt -1
              companyProgress = response.data.getParticipantProgressResponse?.companyProgress
              if companyProgress
                companyProgress.raised = Number companyProgress.raised
                companyProgress.raisedFormatted = if companyProgress.raised then $filter('currency')(companyProgress.raised / 100, '$', 0) else '$0'
                companyProgress.goal = Number companyProgress.goal
                companyProgress.goalFormatted = if companyProgress.goal then $filter('currency')(companyProgress.goal / 100, '$', 0) else '$0'
                companyProgress.percent = 0
                $scope.companyProgress = companyProgress
                $timeout ->
                  percent = $scope.companyProgress.percent
                  if $scope.companyProgress.goal isnt 0
                    percent = Math.ceil(($scope.companyProgress.raised / $scope.companyProgress.goal) * 100)
                  if percent > 100
                    percent = 100
                  $scope.companyProgress.percent = percent
                , 500
            response
        $scope.dashboardPromises.push fundraisingProgressPromise
      $scope.refreshFundraisingProgress()

      $scope.editGoalOptions =
        updateGoalFailure: false
        updateGoalFailureMessage: ''
        updateGoalInput: 0

      $scope.closeGoalAlerts = (closeModal) ->
        $scope.editGoalOptions.updateGoalFailure = false
        $scope.editGoalOptions.updateGoalFailureMessage = ''
        if closeModal
          $scope.editGoalModal.close()

      $scope.editGoal = (goalType) ->
        $scope.closeGoalAlerts false
        switch goalType
          when 'Participant' then $scope.editGoalOptions.updateGoalInput = Math.floor parseInt($scope.participantProgress.goal) / 100
          when 'Team' then $scope.editGoalOptions.updateGoalInput = Math.floor parseInt($scope.teamProgress.goal) / 100
          else $scope.editGoalOptions.updateGoalInput = 0
        $scope.editGoalModal = $uibModal.open
          scope: $scope
          templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/modal/edit' + goalType + 'Goal.html'

      $scope.cancelEditGoal = ->
        $scope.editGoalModal.close()

      $scope.updateGoal = (goalType) ->
        $scope.closeGoalAlerts false
        switch goalType
          when 'Participant'
            $scope.editGoalOptions.updateGoalInput = '' + $scope.editGoalOptions.updateGoalInput
            newGoal = $scope.editGoalOptions.updateGoalInput.replace('$', '').replace(/,/g, '')
            if isNaN(newGoal)
              $scope.editGoalOptions.updateGoalInput = 0
              newGoal = 0
            dataStr = 'goal=' + (newGoal * 100)
            updateGoalPromise = TeamraiserRegistrationService.updateRegistration dataStr
              .then (response) ->
                if response.data?.errorResponse?
                  $scope.editGoalOptions.updateGoalFailure = true
                  if response.data.errorResponse.message
                    $scope.editGoalOptions.updateGoalFailureMessage = response.data.errorResponse.message
                  else
                    $translate 'personal_goal_unexpected_error'
                      .then (translation) ->
                        $scope.editGoalOptions.updateGoalFailureMessage = translation
                      , (translationId) ->
                        $scope.editGoalOptions.updateGoalFailureMessage = translationId
                else
                  $scope.editGoalModal.close()
                  $scope.refreshFundraisingProgress()
                  if $rootScope.facebookFundraiserId
                    FacebookFundraiserService.updateFundraiser()
                      .then ->
                        FacebookFundraiserService.syncDonations()
                response
            $scope.dashboardPromises.push updateGoalPromise
          when 'Team'
            $scope.editGoalOptions.updateGoalInput = '' + $scope.editGoalOptions.updateGoalInput
            newGoal = $scope.editGoalOptions.updateGoalInput.replace('$', '').replace /,/g, ''
            if isNaN(newGoal)
              $scope.editGoalOptions.updateGoalInput = 0
              newGoal = 0
            dataStr = 'team_goal=' + (newGoal * 100)
            updateGoalPromise = TeamraiserTeamService.updateTeamInformation dataStr
              .then (response) ->
                if response.data?.errorResponse?
                  $scope.editGoalOptions.updateGoalFailure = true
                  if response.data.errorResponse.message
                    $scope.editGoalOptions.updateGoalFailureMessage = response.data.errorResponse.message
                  else
                    $translate 'team_goal_unexpected_error'
                      .then (translation) ->
                        $scope.editGoalOptions.updateGoalFailureMessage = translation
                      , (translationId) ->
                        $scope.editGoalOptions.updateGoalFailureMessage = translationId
                else
                  $scope.editGoalModal.close()
                  $scope.refreshFundraisingProgress()
                response
            $scope.dashboardPromises.push updateGoalPromise

      $scope.companyGoalInfo = {}

      $scope.editCompanyGoal = ->
        delete $scope.companyGoalInfo.errorMessage
        companyGoal = $scope.companyProgress.goalFormatted.replace '$', ''
        if companyGoal is '' or companyGoal is '0'
          $scope.companyGoalInfo.goal = ''
        else
          $scope.companyGoalInfo.goal = companyGoal
        $scope.editCompanyGoalModal = $uibModal.open
          scope: $scope
          templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/modal/editCompanyGoal.html'

      $scope.cancelEditCompanyGoal = ->
        $scope.editCompanyGoalModal.close()

      $scope.updateCompanyGoal = ->
        delete $scope.companyGoalInfo.errorMessage
        newGoal = $scope.companyGoalInfo.goal
        if newGoal
          newGoal = newGoal.replace('$', '').replace /,/g, ''
        if not newGoal or newGoal is '' or newGoal is '0' or isNaN(newGoal)
          $scope.companyGoalInfo.errorMessage = 'Please specify a goal greater than $0.'
        else
          updateCompanyGoalPromise = TeamraiserCompanyService.updateCompanyGoal(newGoal, $scope)
            .then (response) ->
              $scope.editCompanyGoalModal.close()
              $scope.refreshFundraisingProgress()
              $scope.dashboardPromises.push updateCompanyGoalPromise

      $scope.toggleGiftNotification = (receiveGiftNotification) ->
        TeamraiserRegistrationService.updateRegistration 'receive_gift_notification=' + receiveGiftNotification
        $rootScope.participantRegistration.receiveGiftNotification = '' + receiveGiftNotification

      $scope.participantGifts =
        sortColumn: 'date_recorded'
        sortAscending: false
        page: 1
      $scope.getGifts = ->
        pageNumber = $scope.participantGifts.page - 1
        personalGiftsPromise = TeamraiserGiftService.getGifts 'list_sort_column=' + $scope.participantGifts.sortColumn + '&list_ascending=' + $scope.participantGifts.sortAscending + '&list_page_size=10&list_page_offset=' + pageNumber
          .then (response) ->
            if response.data.errorResponse
              $scope.participantGifts.gifts = []
              $scope.participantGifts.totalNumber = 0
            else
              gifts = response.data.getGiftsResponse.gift
              if not gifts
                $scope.participantGifts.gifts = []
                $scope.participantGifts.totalNumber = 0
              else
                gifts = [gifts] if not angular.isArray gifts
                participantGifts = []
                angular.forEach gifts, (gift) ->
                  gift.contact =
                    firstName: gift.name.first
                    lastName: gift.name.last
                    email: gift.email
                  gift.giftAmountFormatted = $filter('currency') gift.giftAmount / 100, '$', 2
                  participantGifts.push gift
                $scope.participantGifts.gifts = participantGifts
                $scope.participantGifts.totalNumber = Number response.data.getGiftsResponse?.totalNumberResults or 0
            response
        $scope.dashboardPromises.push personalGiftsPromise
      $scope.getGifts()

      $scope.sortGifts = (sortColumn) ->
        if $scope.participantGifts.sortColumn is sortColumn
          $scope.participantGifts.sortAscending = !$scope.participantGifts.sortAscending
        else
          $scope.participantGifts.sortAscending = true
        $scope.participantGifts.sortColumn = sortColumn
        $scope.participantGifts.page = 1
        $scope.getGifts()

      $scope.acknowledgeGift = (contactId) ->
        $scope.acknowledgeGiftContactId = contactId
        $scope.acknowledgeGiftModal = $uibModal.open
          scope: $scope
          templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/modal/acknowledgeGift.html'

      closeAcknowledgeGiftModal = ->
        delete $scope.acknowledgeGiftContactId
        $scope.acknowledgeGiftModal.close()

      $scope.cancelAcknowledgeGift = ->
        closeAcknowledgeGiftModal()

      $scope.confirmAcknowledgeGift = ->
        if not $scope.acknowledgeGiftContactId
          # TODO
        else
          acknowledgeGiftPromise = TeamraiserGiftService.acknowledgeGift 'contact_id=' + $scope.acknowledgeGiftContactId
            .then (response) ->
              # TODO: error-handling
              closeAcknowledgeGiftModal()
              $scope.getGifts()
              if $scope.participantRegistration.teamId and $scope.participantRegistration.teamId isnt '-1'
                $scope.teamGifts.page = 1
                $scope.getTeamGifts()
              response
          $scope.dashboardPromises.push acknowledgeGiftPromise

      $scope.deleteGift = (giftId) ->
        $scope.deleteGiftId = giftId
        $scope.deleteGiftModal = $uibModal.open
          scope: $scope
          templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/modal/deleteGift.html'

      closeDeleteGiftModal = ->
        delete $scope.deleteGiftId
        $scope.deleteGiftModal.close()

      $scope.cancelDeleteGift = ->
        closeDeleteGiftModal()

      $scope.confirmDeleteGift = ->
        if not $scope.deleteGiftId
          # TODO
        else
          deleteGiftPromise = TeamraiserGiftService.deleteGift 'gift_id=' + $scope.deleteGiftId
            .then (response) ->
              # TODO: error-handling
              closeDeleteGiftModal()
              $scope.getGifts()
              if $scope.participantRegistration.teamId and $scope.participantRegistration.teamId isnt '-1'
                $scope.teamGifts.page = 1
                $scope.getTeamGifts()
              response
          $scope.dashboardPromises.push deleteGiftPromise

      $scope.thankDonor = (contact) ->
        contactData = ''
        if contact.email
          if contact.firstName
            contactData += contact.firstName
          if contact.lastName
            if contactData isnt ''
              contactData += ' '
            contactData += contact.lastName
          if contactData isnt ''
            contactData += ' '
          contactData += '<' + contact.email + '>'
        if not $rootScope.selectedContacts
          $rootScope.selectedContacts = {}
        $rootScope.selectedContacts.contacts = [contactData]
        $location.path '/email/compose'

      if $scope.teamraiserConfig.adminNewsFeedsEnabled is 'true'
        $scope.newsFeed =
          page: 1
        $scope.getNewsFeeds = ->
          pageNumber = $scope.newsFeed.page - 1
          newsFeedsPromise = TeamraiserNewsFeedService.getNewsFeeds 'last_pc2_login=' + $scope.participantRegistration.lastPC2Login + '&feed_count=100'
            .then (response) ->
              newsFeedItems = response.data.getNewsFeedsResponse.newsFeed
              newsFeedItems = [newsFeedItems] if not angular.isArray newsFeedItems
              $scope.newsFeed.items = []
              angular.forEach newsFeedItems, (item, itemIndex) ->
                if itemIndex > (pageNumber * 2) - 1 and itemIndex < (pageNumber + 1) * 2
                  $scope.newsFeed.items.push item
              $scope.newsFeed.totalNumber = Number response.data.getNewsFeedsResponse?.numberOfFeeds or 0
              response
          $scope.dashboardPromises.push newsFeedsPromise
        $scope.getNewsFeeds()
      # undocumented update_last_pc2_login parameter required to make news feeds work, see bz #67720
      TeamraiserRegistrationService.updateRegistration 'update_last_pc2_login=true'

      if $scope.participantRegistration.teamId and $scope.participantRegistration.teamId isnt '-1'
        teamInfoPromise = TeamraiserTeamService.getTeam()
          .then (response) ->
            team = response.data.getTeamSearchByInfoResponse?.team
            if team
              $scope.teamInfo = team
        $scope.dashboardPromises.push teamInfoPromise

        $scope.emailAllTeamMembers = ->
          allTeamMemberContacts = []
          angular.forEach $scope.allTeamMemberContacts, (teamMemberContact) ->
            contactData = ''
            if teamMemberContact.email
              if teamMemberContact.firstName
                contactData += teamMemberContact.firstName
              if teamMemberContact.lastName
                if contactData isnt ''
                  contactData += ' '
                contactData += teamMemberContact.lastName
              if contactData isnt ''
                contactData += ' '
              contactData += '<' + teamMemberContact.email + '>'
              allTeamMemberContacts.push contactData
          if not $rootScope.selectedContacts
            $rootScope.selectedContacts = {}
          $rootScope.selectedContacts.contacts = allTeamMemberContacts
          $location.path '/email/compose'

        captainsMessagePromise = TeamraiserTeamService.getCaptainsMessage()
          .then (response) ->
            teamCaptainsMessage = response.data.getCaptainsMessageResponse
            if teamCaptainsMessage
              $scope.teamCaptainsMessage = teamCaptainsMessage
              if not angular.isString $scope.teamCaptainsMessage.message
                delete $scope.teamCaptainsMessage.message
              $scope.teamCaptainsMessage.inEditMode = false
            response
        $scope.dashboardPromises.push captainsMessagePromise

        $scope.editTeamCaptainsMessage = ->
          $scope.teamCaptainsMessage.inEditMode = true

        $scope.saveTeamCaptainsMessage = ->
          updateCaptainsMessagePromise = TeamraiserTeamService.updateCaptainsMessage 'captains_message=' + encodeURIComponent($scope.teamCaptainsMessage.message)
            .then (response) ->
              if response.data.errorResponse
                # TODO
              else
                $scope.teamCaptainsMessage.inEditMode = false
              response
          $scope.dashboardPromises.push updateCaptainsMessagePromise

        $scope.teamRank = {}
        $scope.topTeams = {}
        topTeamsPromise = TeamraiserTeamService.getTeams 'list_sort_column=total&list_ascending=false&list_page_size=500'
          .then (response) ->
            teams = response.data.getTeamSearchByInfoResponse?.team
            if not teams
              $scope.teamRank.rank = -1
              $scope.teamRank.totalNumber = 0
              $scope.topTeams.teams = []
            else
              teams = [teams] if not angular.isArray teams
              topTeams = []
              angular.forEach teams, (team) ->
                amountRaised = team.amountRaised or 0
                amountRaised = Number amountRaised
                if amountRaised isnt 0
                  team.amountRaisedFormatted = $filter('currency')(amountRaised / 100, '$', 0)
                  topTeams.push team
              angular.forEach topTeams, (topTeam, topTeamIndex) ->
                if topTeam.id is $scope.participantRegistration.teamId
                  $scope.teamRank.rank = topTeamIndex + 1
              if not $scope.teamRank.rank
                $scope.teamRank.rank = -1
              $scope.teamRank.totalNumber = Number response.data.getTeamSearchByInfoResponse?.totalNumberResults or 0
              $scope.topTeams.teams = topTeams
            response
        $scope.dashboardPromises.push topTeamsPromise

        $scope.teamMembers =
          sortColumn: 'totals.cons_first_name'
          sortAscending: true
          page: 1
        $scope.getTeamMembers = ->
          teamMemberContactsPromise = ContactService.getTeamraiserAddressBookContacts 'tr_ab_filter=email_rpt_show_teammates&skip_groups=true'
            .then (response) ->
              addressBookContacts = []
              if response.data.errorResponse
                # TODO
              else
                addressBookContacts = response.data.getTeamraiserAddressBookContactsResponse?.addressBookContact
                if addressBookContacts
                  addressBookContacts = [addressBookContacts] if not angular.isArray addressBookContacts
              $scope.allTeamMemberContacts = []
              $scope.allTeamMemberContacts.push
                firstName: $scope.constituent?.name?.first or ''
                lastName: $scope.constituent?.name?.last or ''
                email: $scope.constituent?.email?.primary_address or ''
              angular.forEach addressBookContacts, (addressBookContact) ->
                $scope.allTeamMemberContacts.push
                  firstName: addressBookContact.firstName
                  lastName: addressBookContact.lastName
                  email: addressBookContact.email
              pageNumber = $scope.teamMembers.page - 1
              teamMembersPromise = TeamraiserParticipantService.getParticipants 'first_name=' + encodeURIComponent('%%%') + '&list_filter_column=reg.team_id&list_filter_text=' + $scope.participantRegistration.teamId + '&list_sort_column=' + $scope.teamMembers.sortColumn + '&list_ascending=' + $scope.teamMembers.sortAscending + '&list_page_size=10&list_page_offset=' + pageNumber
                .then (response) ->
                  teamParticipants = response.data.getParticipantsResponse?.participant
                  if not teamParticipants
                    $scope.teamMembers.members = []
                  else
                    teamParticipants = [teamParticipants] if not angular.isArray teamParticipants
                    teamMembers = []
                    angular.forEach teamParticipants, (teamParticipant) ->
                      if teamParticipant.name?.first
                        teamParticipant.contact =
                          firstName: teamParticipant.name.first
                          lastName: teamParticipant.name.last
                        if Number(teamParticipant.consId) is Number($scope.consId)
                          teamParticipant.contact.email = $scope.constituent?.email?.primary_address or ''
                        else
                          angular.forEach addressBookContacts, (addressBookContact) ->
                            if addressBookContact.firstName is teamParticipant.name.first and addressBookContact.lastName is teamParticipant.name.last
                              teamParticipant.contact.email = addressBookContact.email
                        teamParticipant.amountRaised = Number teamParticipant.amountRaised
                        teamParticipant.amountRaisedFormatted = $filter('currency')(teamParticipant.amountRaised / 100, '$', 2)
                        teamMembers.push teamParticipant
                    $scope.teamMembers.members = teamMembers
                  $scope.teamMembers.totalNumber = Number response.data.getParticipantsResponse?.totalNumberResults or 0
                  response
              $scope.dashboardPromises.push teamMembersPromise
              response
          $scope.dashboardPromises.push teamMemberContactsPromise
        $scope.getTeamMembers()

        $scope.sortTeamMembers = (sortColumn) ->
          if $scope.teamMembers.sortColumn is sortColumn
            $scope.teamMembers.sortAscending = !$scope.teamMembers.sortAscending
          else
            $scope.teamMembers.sortAscending = true
          $scope.teamMembers.sortColumn = sortColumn
          $scope.teamMembers.page = 1
          $scope.getTeamMembers()

        $scope.emailTeamMember = (contact) ->
          contactData = ''
          if contact.email
            if contact.firstName
              contactData += contact.firstName
            if contact.lastName
              if contactData isnt ''
                contactData += ' '
              contactData += contact.lastName
            if contactData isnt ''
              contactData += ' '
            contactData += '<' + contact.email + '>'
          if not $rootScope.selectedContacts
            $rootScope.selectedContacts = {}
          $rootScope.selectedContacts.contacts = [contactData]
          $location.path '/email/compose'

        $scope.teamGifts =
          sortColumn: 'date_recorded'
          sortAscending: false
          page: 1
        $scope.getTeamGifts = ->
          pageNumber = $scope.teamGifts.page - 1
          teamGiftsPromise = TeamraiserGiftService.getTeamGifts 'list_sort_column=' + $scope.teamGifts.sortColumn + '&list_ascending=' + $scope.teamGifts.sortAscending + '&list_page_size=10&list_page_offset=' + pageNumber
            .then (response) ->
              if response.data.errorResponse
                $scope.teamGifts.gifts = []
                $scope.teamGifts.totalNumber = 0
              teamGifts = response.data.getGiftsResponse.gift
              if not teamGifts
                $scope.teamGifts.gifts = []
                $scope.teamGifts.totalNumber = 0
              else
                teamGifts = [teamGifts] if not angular.isArray teamGifts
                angular.forEach teamGifts, (teamGift) ->
                  teamGift.contact =
                    firstName: teamGift.name.first
                    lastName: teamGift.name.last
                    email: teamGift.email
                  teamGift.giftAmountFormatted = $filter('currency') teamGift.giftAmount / 100, '$', 2
                $scope.teamGifts.gifts = teamGifts
                $scope.teamGifts.totalNumber = Number response.data.getGiftsResponse?.totalNumberResults or 0
              response
          $scope.dashboardPromises.push teamGiftsPromise
        $scope.getTeamGifts()

        $scope.sortTeamGifts = (sortColumn) ->
          if $scope.teamGifts.sortColumn is sortColumn
            $scope.teamGifts.sortAscending = !$scope.teamGifts.sortAscending
          else
            $scope.teamGifts.sortAscending = true
          $scope.teamGifts.sortColumn = sortColumn
          $scope.teamGifts.page = 1
          $scope.getTeamGifts()

        # TODO: deleteTeamGift

      if $scope.participantRegistration.companyInformation and $scope.participantRegistration.companyInformation.companyId and $scope.participantRegistration.companyInformation.companyId isnt -1
        companyInfoPromise = TeamraiserCompanyService.getCompany()
          .then (response) ->
            company = response.data.getCompaniesResponse?.company
            if company
              $scope.companyInfo = company
        $scope.dashboardPromises.push companyInfoPromise

        $scope.emailAllCompanyParticipants = ->
          allCompanyParticipantContacts = []
          angular.forEach $scope.allCompanyParticipantContacts, (companyParticipantContact) ->
            contactData = ''
            if companyParticipantContact.email
              if companyParticipantContact.firstName
                contactData += companyParticipantContact.firstName
              if companyParticipantContact.lastName
                if contactData isnt ''
                  contactData += ' '
                contactData += companyParticipantContact.lastName
              if contactData isnt ''
                contactData += ' '
              contactData += '<' + companyParticipantContact.email + '>'
              allCompanyParticipantContacts.push contactData
          if not $rootScope.selectedContacts
            $rootScope.selectedContacts = {}
          $rootScope.selectedContacts.contacts = allCompanyParticipantContacts
          $location.path '/email/compose'

        $scope.companyRank = {}
        $scope.topCompanies = {}
        topCompanyListPromise = TeamraiserCompanyService.getCompanyList 'include_all_companies=true'
          .then (response) ->
            companyItems = response.data.getCompanyListResponse?.companyItem
            if not companyItems
              $scope.companyRank.rank = -1
              $scope.companyRank.totalNumber = 0
              $scope.topCompanies.companies = []
            else
              companyItems = [companyItems] if not angular.isArray companyItems
              rootAncestorCompanyIds = []
              angular.forEach companyItems, (companyItem) ->
                if companyItem.parentOrgEventId is '0'
                  rootAncestorCompanyIds.push companyItem.companyId
              if rootAncestorCompanyIds.length is 0
                $scope.topCompanies.companies = []
              else
                topCompaniesPromise = TeamraiserCompanyService.getCompanies 'list_sort_column=total&list_ascending=false&list_page_size=500'
                  .then (response) ->
                    companies = response.data.getCompaniesResponse?.company
                    if not companies
                      $scope.companyRank.rank = -1
                      $scope.companyRank.totalNumber = 0
                      $scope.topCompanies.companies = []
                    else
                      companies = [companies] if not angular.isArray companies
                      topCompanies = []
                      angular.forEach companies, (company) ->
                        if rootAncestorCompanyIds.indexOf(company.companyId) > -1
                          amountRaised = company.amountRaised or 0
                          amountRaised = Number amountRaised
                          if amountRaised isnt 0
                            company.amountRaisedFormatted = $filter('currency')(amountRaised / 100, '$', 0)
                            topCompanies.push company
                      topCompanies.sort (a, b) ->
                        Number(b.amountRaised) - Number(a.amountRaised)
                      angular.forEach topCompanies, (topCompany, topCompanyIndex) ->
                        if topCompany.companyId is $scope.participantRegistration.companyInformation.companyId
                          $scope.companyRank.rank = topCompanyIndex + 1
                      if not $scope.companyRank.rank
                        $scope.companyRank.rank = -1
                      $scope.companyRank.totalNumber = Number rootAncestorCompanyIds.length
                      $scope.topCompanies.companies = topCompanies
                    response
                $scope.dashboardPromises.push topCompaniesPromise
            response
        $scope.dashboardPromises.push topCompanyListPromise

        $scope.companyTeams =
          sortColumn: 't.name'
          sortAscending: true
          page: 1
        $scope.getCompanyTeams = ->
          pageNumber = $scope.companyTeams.page - 1
          companyTeamsPromise = TeamraiserTeamService.getTeams 'team_company_id=' + $scope.participantRegistration.companyInformation.companyId + '&list_sort_column=' + $scope.companyTeams.sortColumn + '&list_ascending=' + $scope.companyTeams.sortAscending + '&list_page_size=10&list_page_offset=' + pageNumber
            .then (response) ->
              teams = response.data.getTeamSearchByInfoResponse?.team
              if not teams
                $scope.companyTeams.teams = []
              else
                teams = [teams] if not angular.isArray teams
                companyTeams = []
                angular.forEach teams, (team) ->
                  team.amountRaised = Number team.amountRaised
                  team.amountRaisedFormatted = $filter('currency')(team.amountRaised / 100, '$', 0)
                  companyTeams.push team
                $scope.companyTeams.teams = companyTeams
              $scope.companyTeams.totalNumber = Number response.data.getTeamSearchByInfoResponse?.totalNumberResults or 0
              response
          $scope.dashboardPromises.push companyTeamsPromise
        $scope.getCompanyTeams()

        # TODO: get child company teams

        $scope.sortCompanyTeams = (sortColumn) ->
          if $scope.companyTeams.sortColumn is sortColumn
            $scope.companyTeams.sortAscending = !$scope.companyTeams.sortAscending
          else
            $scope.companyTeams.sortAscending = true
          $scope.companyTeams.sortColumn = sortColumn
          $scope.companyTeams.page = 1
          $scope.getCompanyTeams()

        $scope.companyParticipants =
          sortColumn: 'totals.cons_first_name'
          sortAscending: true
          page: 1
        $scope.getCompanyParticipants = ->
          companyParticipantContactsPromise = ContactService.getTeamraiserAddressBookContacts 'tr_ab_filter=email_rpt_show_company_coordinator_participants&skip_groups=true'
            .then (response) ->
              addressBookContacts = []
              if response.data.errorResponse
                # TODO
              else
                addressBookContacts = response.data.getTeamraiserAddressBookContactsResponse?.addressBookContact
                if addressBookContacts
                  addressBookContacts = [addressBookContacts] if not angular.isArray addressBookContacts
              $scope.allCompanyParticipantContacts = []
              $scope.allCompanyParticipantContacts.push
                firstName: $scope.constituent?.name?.first or ''
                lastName: $scope.constituent?.name?.last or ''
                email: $scope.constituent?.email?.primary_address or ''
              angular.forEach addressBookContacts, (addressBookContact) ->
                $scope.allCompanyParticipantContacts.push
                  firstName: addressBookContact.firstName
                  lastName: addressBookContact.lastName
                  email: addressBookContact.email
              pageNumber = $scope.companyParticipants.page - 1
              companyParticipantsPromise = TeamraiserParticipantService.getParticipants 'team_name=' + encodeURIComponent('%%%') + '&list_filter_column=reg.team_id&list_filter_text=' + $scope.participantRegistration.teamId + '&list_sort_column=' + $scope.companyParticipants.sortColumn + '&list_ascending=' + $scope.companyParticipants.sortAscending + '&list_page_size=10&list_page_offset=' + pageNumber
                .then (response) ->
                  participants = response.data.getParticipantsResponse?.participant
                  if not participants
                    $scope.companyParticipants.participants = []
                  else
                    participants = [participants] if not angular.isArray participants
                    companyParticipants = []
                    angular.forEach participants, (participant) ->
                      if participant.name?.first
                        participant.contact =
                          firstName: participant.name.first
                          lastName: participant.name.last
                        if Number(participant.consId) is Number($scope.consId)
                          participant.contact.email = $scope.constituent?.email?.primary_address or ''
                        else
                          angular.forEach addressBookContacts, (addressBookContact) ->
                            if addressBookContact.firstName is participant.name.first and addressBookContact.lastName is participant.name.last
                              participant.contact.email = addressBookContact.email
                        participant.amountRaised = Number participant.amountRaised
                        participant.amountRaisedFormatted = $filter('currency')(participant.amountRaised / 100, '$', 0)
                        companyParticipants.push participant
                    $scope.companyParticipants.participants = companyParticipants
                  $scope.companyParticipants.totalNumber = Number response.data.getParticipantsResponse?.totalNumberResults or 0
                  response
              $scope.dashboardPromises.push companyParticipantsPromise
              response
          $scope.dashboardPromises.push companyParticipantContactsPromise
        $scope.getCompanyParticipants()

        # TODO: get child company participants

        $scope.sortCompanyParticipants = (sortColumn) ->
          if $scope.companyParticipants.sortColumn is sortColumn
            $scope.companyParticipants.sortAscending = !$scope.companyParticipants.sortAscending
          else
            $scope.companyParticipants.sortAscending = true
          $scope.companyParticipants.sortColumn = sortColumn
          $scope.companyParticipants.page = 1
          $scope.getCompanyParticipants()

        $scope.emailCompanyParticipant = (contact) ->
          contactData = ''
          if contact.email
            if contact.firstName
              contactData += contact.firstName
            if contact.lastName
              if contactData isnt ''
                contactData += ' '
              contactData += contact.lastName
            if contactData isnt ''
              contactData += ' '
            contactData += '<' + contact.email + '>'
          if not $rootScope.selectedContacts
            $rootScope.selectedContacts = {}
          $rootScope.selectedContacts.contacts = [contactData]
          $location.path '/email/compose'

      $scope.getParticipantShortcut = ->
        getParticipantShortcutPromise = TeamraiserShortcutURLService.getShortcut()
          .then (response) ->
            shortcutItem = response.data.getShortcutResponse?.shortcutItem
            if shortcutItem
              if shortcutItem.prefix
                shortcutItem.prefix = shortcutItem.prefix.replace 'www.', ''
              $scope.participantShortcut = shortcutItem
              if shortcutItem.url
                $scope.personalPageUrl = shortcutItem.url.replace 'www.', ''
              else
                $scope.personalPageUrl = shortcutItem.defaultUrl.replace('www.', '').split('/site/')[0] + '/site/TR?fr_id=' + $scope.frId + '&pg=personal&px=' + $scope.consId
              $timeout ->
                addthis.toolbox '.addthis_toolbox'
              , 500
        $scope.dashboardPromises.push getParticipantShortcutPromise
      $scope.getParticipantShortcut()

      $scope.getPrevShortcut = ()->
        getPrevShortcutPromise = TeamraiserShortcutURLService.getShortcut($rootScope.prevFrIdForShortcut)
          .then (response) ->
            if response.data.errorResponse
              # TODO
            else
              shortcutItem = response.data.getShortcutResponse.shortcutItem
              if shortcutItem
                $scope.prevShortcut = shortcutItem
        $scope.dashboardPromises.push getPrevShortcutPromise
      $scope.getPrevShortcut()

      $scope.personalPageUrlSecure = $scope.baseDomain + '/site/TR?fr_id=' + $scope.frId + '&pg=personal&px=' + $scope.consId

      $scope.editPageUrlOptions =
        updateUrlFailure: false
        updateUrlFailureMessage: ''
        updateUrlInput: ''

      $scope.closeUrlAlerts = (closeModal) ->
        $scope.editPageUrlOptions.updateUrlFailure = false
        $scope.editPageUrlOptions.updateUrlFailureMessage = ''
        if closeModal
          $scope.editPageUrlModal.close()

      $scope.editPageUrl = (urlType) ->
        $scope.closeUrlAlerts false
        switch urlType
          when 'Participant' then $scope.editPageUrlOptions.updateUrlInput = $scope.participantShortcut?.text or ''
          when 'Team' then $scope.editPageUrlOptions.updateUrlInput = $scope.teamShortcut?.text or ''
        $scope.editPageUrlModal = $uibModal.open
          scope: $scope
          templateUrl: APP_INFO.rootPath + 'dist/heart-walk/html/participant-center/modal/edit' + urlType + 'PageUrl.html'

      $scope.cancelEditPageUrl = ->
        $scope.editPageUrlModal.close()

      $scope.updatePageUrl = (urlType) ->
        $scope.closeUrlAlerts false
        dataStr = 'text=' + $scope.editPageUrlOptions.updateUrlInput
        switch urlType
          when 'Participant'
            updateUrlPromise = TeamraiserShortcutURLService.updateShortcut dataStr
              .then (response) ->
                if response.data.errorResponse
                  if $scope.editPageUrlOptions.updateUrlInput isnt $scope.prevShortcut.text
                    $scope.editPageUrlOptions.updateUrlFailure = true;
                    return $scope.editPageUrlOptions.updateUrlFailureMessage = response.data.errorResponse.message or 'An unexpected error occurred while updating your personal page URL.';
                  else
                    updateUrlPromise = TeamraiserShortcutURLService.updateShortcut("text=",$rootScope.prevFrIdForShortcut)
                      .then (response) ->
                        if (response.data.errorResponse)
                          $scope.editPageUrlOptions.updateUrlFailure = true
                          return $scope.editPageUrlOptions.updateUrlFailureMessage = response.data.errorResponse.message or 'An unexpected error occurred while updating your personal page URL.';
                        else
                          $scope.updatePageUrl("Participant")
                else
                  $scope.editPageUrlModal.close()
                  $scope.getParticipantShortcut()
            $scope.dashboardPromises.push updateUrlPromise
          when 'Team'
            updateUrlPromise = TeamraiserShortcutURLService.updateTeamShortcut dataStr
              .then (response) ->
                if response.data.errorResponse
                  $scope.editPageUrlOptions.updateUrlFailure = true
                  $scope.editPageUrlOptions.updateUrlFailureMessage = response.data.errorResponse.message or 'An unexpected error occurred while updating your team page URL.'
                else
                  $scope.editPageUrlModal.close()
                  $scope.getTeamShortcut()
            $scope.dashboardPromises.push updateUrlPromise

      if $scope.participantRegistration.teamId and $scope.participantRegistration.teamId isnt '-1'
        if $scope.participantRegistration.aTeamCaptain isnt 'true'
          $scope.teamPageUrl = luminateExtend.global.path.nonsecure + 'TR?fr_id=' + $scope.frId + '&pg=team&team_id=' + $scope.participantRegistration.teamId
        else
          $scope.getTeamShortcut = ->
            getTeamShortcutPromise = TeamraiserShortcutURLService.getTeamShortcut()
              .then (response) ->
                shortcutItem = response.data.getTeamShortcutResponse?.shortcutItem
                if shortcutItem
                  if shortcutItem.prefix
                    shortcutItem.prefix = shortcutItem.prefix.replace 'www.', ''
                  $scope.teamShortcut = shortcutItem
                  if shortcutItem.url
                    $scope.teamPageUrl = shortcutItem.url.replace 'www.', ''
                  else
                    $scope.teamPageUrl = shortcutItem.defaultUrl.replace('www.', '').split('/site/')[0] + '/site/TR?fr_id=' + $scope.frId + '&pg=team&team_id=' + $scope.participantRegistration.teamId
                  $timeout ->
                    addthis.toolbox '.addthis_toolbox'
                  , 500
            $scope.dashboardPromises.push getTeamShortcutPromise
          $scope.getTeamShortcut()

      if $scope.participantRegistration.companyInformation and $scope.participantRegistration.companyInformation.companyId and $scope.participantRegistration.companyInformation.companyId isnt -1
        if $scope.participantRegistration.companyInformation?.isCompanyCoordinator isnt 'true'
          $scope.companyPageUrl = luminateExtend.global.path.nonsecure + 'TR?fr_id=' + $scope.frId + '&pg=company&company_id=' + $scope.participantRegistration.companyInformation.companyId
        else
          $scope.getCompanyShortcut = ->
            getCompanyShortcutPromise = TeamraiserShortcutURLService.getCompanyShortcut()
              .then (response) ->
                shortcutItem = response.data.getCompanyShortcutResponse?.shortcutItem
                if shortcutItem
                  if shortcutItem.prefix
                    shortcutItem.prefix = shortcutItem.prefix.replace 'www.', ''
                  $scope.companyShortcut = shortcutItem
                  if shortcutItem.url
                    $scope.companyPageUrl = shortcutItem.url.replace 'www.', ''
                  else
                    $scope.companyPageUrl = shortcutItem.defaultUrl.replace('www.', '').split('/site/')[0] + '/site/TR?fr_id=' + $scope.frId + '&pg=company&company_id=' + $scope.participantRegistration.companyInformation.companyId
                  $timeout ->
                    addthis.toolbox '.addthis_toolbox'
                  , 500
            $scope.dashboardPromises.push getCompanyShortcutPromise
          $scope.getCompanyShortcut()
  ]
