spotlightReports = angular.module('spotlightReports',['templates', 'ngRoute', 'controllers', 'angularUtils.directives.dirPagination'])

spotlightReports.config(['$routeProvider', '$locationProvider', ($routeProvider, $locationProvider) ->
  $routeProvider
    .when('/',
      templateUrl: "index.html"
      controller: 'SchoolController'
      )
    .when('/teacher/:id',
      templateUrl: 'show.html'
      controller: 'TeacherController'
      )
  $locationProvider.html5Mode(true)
])

controllers = angular.module('controllers', [])

controllers.controller('SchoolController', [ '$scope', '$routeParams', 'School', ($scope, $routeParams, School) ->
  $scope.school_name = $routeParams.school_name
  $scope.status = {}
  $scope.status.dataLoading = true
  School.getTeachers($routeParams.school_id).success (data) ->
    $scope.teachers = (data)
  .finally ->
      $scope.status.dataLoading = false
])

spotlightReports.factory('School', ['$http', ($http) ->
  teachers = {}
  teachers.getTeachers = (school_id) ->
    $http.get('/school/'+ school_id)
  return teachers
])

controllers.controller('TeacherController', [ '$scope', '$routeParams', 'Teacher', ($scope, $routeParams, Teacher) ->
  $scope.status = {}
  $scope.status.dataLoading = true
  Teacher.getTeacherDetails($routeParams.id).success (teacherData) ->
    $scope.teacherDetails = (teacherData)
    for course_id, course_object of $scope.teacherDetails.courses
      course_object.selected = true
    console.log $scope.teacherDetails
  .finally ->
    $scope.dates = dates()
    $scope.start_date = $scope.dates[0]
    $scope.end_date = $scope.dates[$scope.dates.length - 1]
    $scope.pageViews = addPageViews()
    $scope.participations = addParticipations()
    $scope.stats = addStats()
    console.log $scope.stats
    $scope.status.dataLoading = false
    $scope.$watchGroup ['start_date', 'end_date'], ->
      updateGraphs()
    $scope.$watch 'teacherDetails.courses', ->
      updateGraphs()
    , true

  updateGraphs = ->
    updateDateRange()
    $scope.pageViews = addPageViews()
    $scope.participations = addParticipations()
    $scope.stats = addStats()

  updateDateRange = ->
    $scope.dates = (date for date in $scope.dates when (moment(date).isBetween(moment($scope.start_date).subtract(1, "day"), moment($scope.end_date).add(1, "day"))))

  addStats = ->
    stats = {discussions:0, files:0, assignments:0}
    for course_id, course_object of $scope.teacherDetails.statgrid when $scope.teacherDetails.courses[course_id].selected == true
      for date_id, date_object of course_object when (moment(date_id).isBetween(moment($scope.start_date).subtract(1, "day"), moment($scope.end_date).add(1, "day")))
        stats.discussions += date_object.discussions
        stats.files += date_object.files
        stats.assignments += date_object.assignments
    stats


  addParticipations = ->
    participations = []
    index = 0
    for date in $scope.dates
      participations[index] = 0
      for course_id, course_object of $scope.teacherDetails.course_analytics when $scope.teacherDetails.courses[course_id].selected == true
        for stat in course_object
          if stat.date == date
            participations[index] += stat.participations
      index += 1
    participations

  addPageViews = ->
    pageViews = []
    index = 0
    for date in $scope.dates
      pageViews[index] = 0
      for course_id, course_object of $scope.teacherDetails.course_analytics when $scope.teacherDetails.courses[course_id].selected == true
        for stat in course_object
          if stat.date == date
            pageViews[index] += stat.views
      index += 1
    pageViews

  dates = ->
    dates = []
    for course_id, course_object of $scope.teacherDetails.course_analytics
      for stat in course_object
        date = moment(stat.date).format("YYYY-MM-DD")
        unless date in dates
          dates.push date
    dates.sort( (a,b) ->
        moment(a) - moment(b)
      )
])

spotlightReports.factory('Teacher', ['$http', ($http) ->
  teacherDetails = {}
  teacherDetails.getTeacherDetails = (teacher_id) ->
    $http.get('/teacher_details/' + teacher_id)
  return teacherDetails
])

spotlightReports.directive 'pageviewsChart', [ ->
  restrict: "A"
  link: (scope, element, attrs) ->
    renderChart = ->
      element.highcharts
        chart:
          type: 'column'
        title:
          text: 'Pageviews'
        xAxis:
          categories: scope.dates
        yAxis:
          title:
            text: 'Number'
        series: [
          {
            name: 'Pageviews'
            data: scope.pageViews
          }
        ]

    renderChart()
    scope.$watch "pageViews", ->
      renderChart()
]

spotlightReports.directive 'participationsChart', [ ->
  restrict: "A"
  link: (scope, element, attrs) ->
    renderChart = ->
      element.highcharts
        chart:
          type: 'column'
        title:
          text: 'Participations'
        xAxis:
          categories: scope.dates
        yAxis:
          title:
            text: 'Number'
        series: [
          {
            name: 'Participations'
            data: scope.participations
          }
        ]

    renderChart()
    scope.$watch "participations", ->
      renderChart()
]

spotlightReports.directive 'datePicker', ->
  restrict: "A"
  link: (scope, element, attrs) ->
    element.fdatepicker(format: 'yyyy-mm-dd')
