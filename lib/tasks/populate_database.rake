task populate_database: :environment do

  # Authenticate API access
  @client = Pandarus::Client.new(
    prefix: ENV['API_URL'],
    token: ENV['API_TOKEN'])

  def get_discussions_posted_by_date(canvas_course_object)
    discussions_list = @client.list_discussion_topics_courses(canvas_course_object.id)
    dates = []
    discussions_list.each { |discussion| dates << discussion.posted_at.to_s[0..9] }
    discussions_by_date = Hash.new(0)
    dates.each do |date|
      discussions_by_date[date] += 1
    end
    discussions_by_date
  end

  def get_files_uploaded_by_date(canvas_course_object)
    file_list = @client.list_files_courses(canvas_course_object.id)
    dates = []
    file_list.each { |file| dates << file.created_at.to_s[0..9] }
    files_by_date = Hash.new(0)
    dates.each do |date|
      files_by_date[date] += 1
    end
    files_by_date
  end

  def get_assignments_created_by_date(canvas_course_object)
    assignment_list = @client.list_assignments(canvas_course_object.id)
    dates = []
    assignment_list.each { |assignment| dates << assignment.created_at.to_s[0..9] }
    assignments_by_date = Hash.new(0)
    dates.each do |date|
      assignments_by_date[date] += 1
    end
    assignments_by_date
  end

  def get_grade_changes_by_date(canvas_course_object)
    grade_change_list = HTTParty.get(ENV['API_URL'] + "/v1/audit/grade_change/courses/" + canvas_course_object.id.to_s + "?access_token=" + ENV['API_TOKEN'])["events"]
    dates = []
    grade_change_list.each { |grade_change| dates << grade_change["created_at"].to_s[0..9] }
    grade_changes_by_date = Hash.new(0)
    dates.each do |date|
      grade_changes_by_date[date] += 1
    end
    grade_changes_by_date
  end

  def get_grades(canvas_course_object)
    grades = Hash.new(0)
    course_grades = HTTParty.get(ENV['API_URL'] + "/v1/audit/grade_change/courses/" + canvas_course_object.id.to_s + "?access_token=" + ENV['API_TOKEN'])
    course_grades["linked"]["assignments"].each do |assignment|
      id = assignment["id"]
      grades[id] = {"points_possible"=> 0, "grades"=> []}
      grades[id]["points_possible"] = assignment["points_possible"]
    end
    course_grades["events"].each do |grade_event|
      assignment_id = grade_event["links"]["assignment"]
      grades[assignment_id]["grades"] << grade_event["grade_after"]
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
      student_participation_data["page_views"].empty? ? student_hash["page_views"] = [] : student_hash["page_views"] = student_participation_data["page_views"].keys.map{|d| d.to_s[0..9]}
      student_participation_data["participations"].empty? ? student_hash["participations"] = [] : student_hash["participations"] = student_participation_data["participations"].map{|p| p["created_at"]}.map{|d| d.to_s[0..9]}
      student_data[student_id] = student_hash
    end
    student_data
  end

  Account.destroy_all
  Course.destroy_all
  Teacher.destroy_all



  # Get accounts from Canvas
  puts 'Getting Accounts'
  main_account = @client.list_accounts
  Account.create(
    canvas_id: main_account.first.id,
    name: main_account.first.name
    )

  sub_accounts = @client.get_sub_accounts_of_account(1)
  sub_accounts.each do |sub_account|

    Account.create(
      canvas_id: sub_account.id,
      name: sub_account.name
      )

    puts 'Getting Courses'
    begin
      courses = @client.list_active_courses_in_account(sub_account.id, with_enrollments:"true", published:"true")
    rescue
    end
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
    end

    puts 'Getting Teachers'
    enrollments_by_course = courses.map do |course|
      @client.list_enrollments_courses(course.id, type:"TeacherEnrollment")
    end

    teachers = enrollments_by_course.map do |course|
      course.entries.map do |enrollment|
        enrollment.user
      end
    end

    teachers.flatten!.uniq!{|t| t.id}

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
      rescue
      end
    end
  end
end
