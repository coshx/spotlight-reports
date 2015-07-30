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

spotlightReports.factory('Teacher', ['$http', ($http) ->
  teacherDetails = {}
  teacherDetails.getTeacherDetails = (teacher_id) ->
    $http.get('/teacher_details/' + teacher_id)
  return teacherDetails
])

spotlightReports.factory('CourseGraphs', ['$http', ($http) ->
  courseGraphs = {}
  courseGraphs.getGraphData = (teacher_id) ->
    $http.get('/course_graph_data/' + teacher_id)
  return courseGraphs
])

spotlightReports.factory('GridData', ['$http', ($http) ->
  statGrid = {}
  statGrid.getStatGridData = (teacher_id) ->
    $http.get('/course_grid_data/' + teacher_id)
  return statGrid
])

spotlightReports.factory('GridStudentData', ['$http', ($http) ->
  studentData = {}
  studentData.getStudentData = (teacher_id) ->
    $http.get('/course_student_data/' + teacher_id)
  return studentData
])

spotlightReports.factory('GradeData', ['$http', ($http) ->
  gradeData = {}
  gradeData.getGradeData = (teacher_id) ->
    $http.get('/course_grade_data/' + teacher_id)
  return  gradeData
])

spotlightReports.factory('SchoolComparison', ['$http', ($http) ->
  schoolComparisonData = {}
  schoolComparisonData.getSchoolComparisonData = (school_id, start_date, end_date) ->
    $http.post('/school_averages/', {school_id: school_id, start_date: start_date, end_date: end_date})
  return schoolComparisonData
])

controllers.controller('TeacherController', [ '$scope', '$routeParams', 'Teacher', 'CourseGraphs', 'GridData', 'GridStudentData', 'GradeData', 'SchoolComparison', ($scope, $routeParams, Teacher, CourseGraphs, GridData, GridStudentData, GradeData, SchoolComparison) ->
  $scope.status = {}
  $scope.comparison = -1
  $scope.status.dataLoading = true
  Teacher.getTeacherDetails($routeParams.id).success (teacherData) ->
    $scope.teacherDetails = (teacherData)
    $scope.teacherDetails.coursesCount = 0
    for course_id, course_object of $scope.teacherDetails.courses
      $scope.teacherDetails.coursesCount += 1
      course_object.selected = true
  .then ->
    CourseGraphs.getGraphData($routeParams.id).success (graphData) ->
      $scope.teacherDetails.course_analytics = graphData
    GridData.getStatGridData($routeParams.id).success (gridData) ->
      $scope.teacherDetails.statgrid = gridData
  .then ->
    GridStudentData.getStudentData($routeParams.id).success (studentData) ->
      $scope.teacherDetails.studentData = studentData
  .then ->
    GradeData.getGradeData($routeParams.id).success (gradeData) ->
      $scope.teacherDetails.gradeData = gradeData
  .finally ->
    $scope.allDates = dates()
    $scope.selectedDates = $scope.allDates
    $scope.start_date = $scope.allDates[0]
    $scope.end_date = $scope.allDates[$scope.allDates.length - 1]
    $scope.pageViews = addPageViews()
    $scope.participations = addParticipations()
    $scope.stats = addStats()
    $scope.status.dataLoading = false
    $scope.$watchGroup ['start_date', 'end_date'], ->
      $scope.getSchoolAverages(parseInt($scope.comparison))
      updateGraphs()
    $scope.$watch 'teacherDetails.courses', ->
      $scope.getSchoolAverages(parseInt($scope.comparison))
      updateGraphs()
      $scope.teacherDetails.selectedCourseCount = countSelectedCourses()
    , true

  setColors = ->
    $scope.statColor = {}
    courseCount = countSelectedCourses()

    $scope.statColor['Discussion Posts'] = compareStats($scope.stats['Discussion Posts'], $scope.schoolComparison.discussions_count, courseCount)

    $scope.statColor['Files Uploaded'] = compareStats($scope.stats['Files Uploaded'], $scope.schoolComparison.files_count, courseCount)

    $scope.statColor['Assignments'] = compareStats($scope.stats['Assignments'], $scope.schoolComparison.assignments_count, courseCount)

    $scope.statColor['Grades Entered'] = compareStats($scope.stats['Grades Entered'], $scope.schoolComparison.grades_entered_count, courseCount)

    $scope.statColor['Student Participation'] = compareStats($scope.stats['Student Participation'], $scope.schoolComparison.participation, 1)

    $scope.statColor['Student Access Average'] = compareStats($scope.stats['Student Access Average'], $scope.schoolComparison.access, 1)

    $scope.statColor['Student Grades Below 70%'] = compareGrades($scope.stats['Student Grades Below 70%'], $scope.schoolComparison.grades_below_seventy)

  compareGrades = (grades, schoolAverage) ->
    colors = {
      belowTen: {'border': '2px solid #f04124', 'border-radius': '3px'},
      belowTwentyFive: {'border': '2px solid #f08a24', 'border-radius': '3px'},
      none: {}
    }
    if parseInt(grades) > schoolAverage + (schoolAverage * 0.9)
      return colors.belowTen
    else if parseInt(grades) > schoolAverage + (schoolAverage * 0.75)
      return colors.belowTwentyFive
    else
      return colors.none


  compareStats = (teacherStat, schoolAverage, courseCount) ->
    colors = {
      belowTen: {'border': '2px solid #f04124', 'border-radius': '3px'},
      belowTwentyFive: {'border': '2px solid #f08a24', 'border-radius': '3px'},
      none: {}
    }
    if parseInt(teacherStat) < (schoolAverage * courseCount) / 10
      return colors.belowTen
    else if parseInt(teacherStat) < (schoolAverage * courseCount) / 4
      return colors.belowTwentyFive
    else
      return colors.none


  $scope.getSchoolAverages = (school_account) ->
    return if school_account == -1
    $scope.status.comparisonLoading = true
    SchoolComparison.getSchoolComparisonData(school_account, $scope.start_date, $scope.end_date).success (comparisonData) ->
      $scope.schoolComparison = comparisonData
    .then ->
      setColors()
      $scope.status.comparisonLoading = false

  countSelectedCourses = ->
    count = 0
    for course_id, course of $scope.teacherDetails.courses
      count += 1 if course.selected == true
    return count

  $scope.deselectAllCourses = ->
    for course_id, course_object of $scope.teacherDetails.courses
      course_object.selected = false

  $scope.selectAllCourses = ->
    for course_id, course_object of $scope.teacherDetails.courses
      course_object.selected = true

  updateGraphs = ->
    updateDateRange()
    $scope.pageViews = addPageViews()
    $scope.participations = addParticipations()
    $scope.stats = addStats()

  updateDateRange = ->
    $scope.selectedDates = (date for date in $scope.allDates when (moment(date).isBetween(moment($scope.start_date).subtract(1, "day"), moment($scope.end_date).add(1, "day"))))

  addStats = ->
    stats = {"Discussion Posts":0, "Files Uploaded":0, "Assignments":0, "Grades Entered":0, "Student Participation":"0%", "Student Access Average":"0%", "Student Grades Below 70%":"0%"}
    for course_id, course_object of $scope.teacherDetails.statgrid when $scope.teacherDetails.courses[course_id].selected == true
      for date_id, date_object of course_object when (moment(date_id).isBetween(moment($scope.start_date).subtract(1, "day"), moment($scope.end_date).add(1, "day")))
        stats["Discussion Posts"] += parseInt(date_object.discussions) unless date_object.discussions == null
        stats["Files Uploaded"] += parseInt(date_object.files) unless date_object.files == null
        stats["Assignments"] += parseInt(date_object.assignments) unless date_object.assignments == null
        stats["Grades Entered"] += parseInt(date_object.gradesEntered) unless date_object.gradesEntered == null

    students = 0
    students_participated = 0
    students_accessed = 0

    for course_id, course_object of $scope.teacherDetails.studentData when $scope.teacherDetails.courses[course_id].selected == true
      for student_id, student_object of course_object
        students += 1
        student_data = JSON.parse(student_object.replace(/=>/g, ':'))
        students_participated += 1 if intersection(student_data.participations, $scope.selectedDates)
        students_accessed += 1 if intersection(student_data.page_views, $scope.selectedDates)

    participation_average = Math.round(students_participated/students * 100)
    access_average = Math.round(students_accessed/students * 100)
    stats["Student Participation"] = participation_average + "%" unless isNaN(participation_average)
    stats["Student Access Average"] = access_average + "%" unless isNaN(access_average)

    total_grades = 0
    total_grades_below_seventy = 0

    for course_id, course_object of $scope.teacherDetails.gradeData when $scope.teacherDetails.courses[course_id].selected == true
      for assignment_id, assignment_object of course_object
        assignment_data = JSON.parse(assignment_object.replace(/=>/g, ':'))
        for grade in assignment_data.grades
          if grade.nil?
            continue
          else
            total_grades += 1
            total_grades_below_seventy += 1 if parseInt(grade) / assignment_data.points_possible < .7

    grades_below_seventy_average = Math.round(total_grades_below_seventy/total_grades * 100)
    stats["Student Grades Below 70%"] = grades_below_seventy_average + "%" unless isNaN(grades_below_seventy_average)

    stats

  intersection = (a, b) ->
    [a, b] = [b, a] if a.length > b.length
    return true for value in a when value in b

  addParticipations = ->
    participations = []
    index = 0
    for date in $scope.selectedDates
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
    for date in $scope.selectedDates
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
          categories: scope.selectedDates
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
          categories: scope.selectedDates
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
