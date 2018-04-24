task populate_database: :environment do

  # Authenticate API access
  @client = Pandarus::Client.new(
    prefix: ENV['API_URL'],
    token: ENV['API_TOKEN'])
  
  if ENV['TERM_FILTER']
    @term_filter_ids = ENV['TERM_FILTER'].split(',').map { |id| id.strip().to_i }
  else
    @term_filter_ids = []
  end
  
  if ENV['COURSE_FILTER']
    @course_filter_ids = ENV['COURSE_FILTER'].split(',').map { |id| id.strip().to_i }
  else
    @course_filter_ids = []
  end

  def get_discussions_posted_by_date(canvas_course_object)
    discussions_list = @client.list_discussion_topics_courses(canvas_course_object.id)
    dates = []
    if discussions_list
      discussions_list.each { |discussion| dates << discussion.posted_at.to_s[0..9] }
    end
    discussions_by_date = Hash.new(0)
    dates.each do |date|
      discussions_by_date[date] += 1
    end
    discussions_by_date
  end

  def get_files_uploaded_by_date(canvas_course_object)
    file_list = @client.list_files_courses(canvas_course_object.id)
    dates = []
    if file_list
      file_list.each { |file| dates << file.created_at.to_s[0..9] }
    end
    files_by_date = Hash.new(0)
    dates.each do |date|
      files_by_date[date] += 1
    end
    files_by_date
  end

  def get_assignments_created_by_date(canvas_course_object)
    assignment_list = @client.list_assignments(canvas_course_object.id)
    dates = []

    if assignment_list
      assignment_list.each { |assignment| dates << assignment.created_at.to_s[0..9] }
    end
    assignments_by_date = Hash.new(0)
    dates.each do |date|
      assignments_by_date[date] += 1
    end
    assignments_by_date
  end

  def get_grade_changes_by_date(canvas_course_object)
    grade_change_list = HTTParty.get(ENV['API_URL'] + "/v1/audit/grade_change/courses/" + canvas_course_object.id.to_s + "?access_token=" + ENV['API_TOKEN'])["events"]
    dates = []
    if grade_change_list
      grade_change_list.each { |grade_change| dates << grade_change["created_at"].to_s[0..9] }
    end
    grade_changes_by_date = Hash.new(0)
    dates.each do |date|
      grade_changes_by_date[date] += 1
    end
    grade_changes_by_date
  end

  def get_grades(canvas_course_object)
    grades = Hash.new(0)
    course_grades = HTTParty.get(ENV['API_URL'] + "/v1/audit/grade_change/courses/" + canvas_course_object.id.to_s + "?access_token=" + ENV['API_TOKEN'])
    if course_grades
      if course_grades["linked"] && course_grades["linked"]["assignments"]
        course_grades["linked"]["assignments"].each do |assignment|
          id = assignment["id"]
          grades[id] = {"points_possible"=> 0, "grades"=> []}
          grades[id]["points_possible"] = assignment["points_possible"]
        end
      end
      if course_grades["events"]
        course_grades["events"].each do |grade_event|
          assignment_id = grade_event["links"]["assignment"]
          grades[assignment_id]["grades"] << grade_event["grade_after"] unless grade_event["grade_after"].nil?
        end
      end
    end
    grades
  end

  def get_student_participation_and_access(canvas_course_object)
    student_data = Hash.new(0)
    student_ids = @client.list_students(canvas_course_object.id).entries.map {|s| s.id}
    student_ids.each do |student_id|
      student_hash = {"page_views"=>[], "participations"=>[]}
      student_participation_data = HTTParty.get(ENV['API_URL'] + "/v1/courses/#{canvas_course_object.id.to_s}/analytics/users/#{student_id}/activity?access_token=" + ENV['API_TOKEN']).to_hash
      next if student_participation_data.keys.include?("errors")
      student_hash["page_views"] = student_participation_data["page_views"].keys.map{|d| d.to_s[0..9]} unless student_participation_data["page_views"].nil?
      student_hash["participations"] = student_participation_data["participations"].map{|p| p["created_at"]}.map{|d| d.to_s[0..9]} unless student_participation_data["participations"].nil?
      student_data[student_id] = student_hash
    end
    student_data
  end

  Account.destroy_all
  Course.destroy_all
  Teacher.destroy_all


  # Get accounts from Canvas
  sub_accounts = @client.get_sub_accounts_of_account(1)
  sub_accounts.each do |sub_account|

    puts "\nGetting Account: " + sub_account.name

    puts 'Getting Courses'

    begin
      all_courses = @client.list_active_courses_in_account(sub_account.id, with_enrollments:"true", published:"true")
      filtered_courses = all_courses.select { |course| !@course_filter_ids.include? course.id }.select { |course| !@term_filter_ids.include? course.enrollment_term_id }
      courses = filtered_courses
    rescue
    end

    teachers = []
    
    throw courses.inspect

    courses.each do |course|
      Course.create(
        canvas_id: course.id,
        account_id: course.account_id,
        name: course.name,
        discussions: get_discussions_posted_by_date(course),
        files: get_files_uploaded_by_date(course),
        assignments: get_assignments_created_by_date(course),
        grades: get_grade_changes_by_date(course),
        grades_by_assignment: get_grades(course),
        participation_and_access: get_student_participation_and_access(course)
        )
      print '.'

      teacher_enrollments = @client.list_enrollments_courses(course.id, type:"TeacherEnrollment")
      teachers << teacher_enrollments.map do |teacher|
        teacher.user
      end
    end

    puts ''

    teachers.flatten.uniq!{|t| t.id}

    puts 'Getting Teachers'
    teachers.each do |teacher|
      begin
        teacher_avatar_url = @client.show_user_details(teacher.id).avatar_url
        teacher_email = @client.get_user_profile(teacher.id).primary_email

        Teacher.create(
          canvas_id: teacher.id,
          name: teacher.name,
          sortable_name: teacher.sortable_name,
          avatar_url: teacher_avatar_url,
          email: teacher_email,
          school_account: sub_account.id
          )
        print '.'
      rescue
      end
    end
    puts ''
  end
end
