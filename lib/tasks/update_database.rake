task update_database: :environment do

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
      student_hash["page_views"] = student_participation_data["page_views"].keys.map{|d| d.to_s[0..9]} unless student_participation_data["page_views"].nil?
      student_hash["participations"] = student_participation_data["participations"].map{|p| p["created_at"]}.map{|d| d.to_s[0..9]} unless student_participation_data["participations"].nil?
      student_data[student_id] = student_hash
    end
    student_data
  end


  # Get accounts from Canvas
  sub_accounts = @client.get_sub_accounts_of_account(1)
  sub_accounts.each do |sub_account|

    puts "\nGetting Account: " + sub_account.name

    puts 'Getting Courses'

    begin
      courses = @client.list_active_courses_in_account(sub_account.id, with_enrollments:"true", published:"true")
    rescue
    end

    teachers = []

    courses.each do |course|
      new_course = Course.new(
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

      old_course = Course.find_by(canvas_id: course.id)

      if old_course.nil?
        new_course.save
        puts "Created: " + course.name
      elsif old_course.attributes.except("id", "updated_at", "created_at") != new_course.attributes.except("id", "updated_at", "created_at")
        old_course.update_attributes(new_course.attributes.except("id", "created_at", "updated_at"))
        old_course.save
        puts "Updated: " + course.name
      else
        puts "Unchanged: " + course.name
      end

      teacher_enrollments = @client.list_enrollments_courses(course.id, type:"TeacherEnrollment")
      teachers << teacher_enrollments.map do |teacher|
        teacher.user
      end
    end

    puts ''

    teachers.flatten!.uniq!{|t| t.id}

    puts 'Getting Teachers'
    teachers.each do |teacher|
      begin
        teacher_avatar_url = @client.show_user_details(teacher.id).avatar_url
        teacher_email = @client.get_user_profile(teacher.id).primary_email

        new_teacher = Teacher.new(
          canvas_id: teacher.id,
          name: teacher.name,
          sortable_name: teacher.sortable_name,
          avatar_url: teacher_avatar_url,
          email: teacher_email,
          school_account: sub_account.id
          )

        old_teacher = Teacher.find_by(canvas_id: teacher.id, school_account: sub_account.id)

        if old_teacher.nil?
          new_teacher.save
          puts "Created " + teacher.name
        elsif old_teacher.attributes.except("id", "updated_at", "created_at") != new_teacher.attributes.except("id", "updated_at", "created_at")
          old_teacher.update_attributes(new_teacher.attributes.except("id"))
          old_teacher.save
          puts "Updated " + teacher.name
        else
          puts "Unchanged: " + teacher.name
        end
      rescue
      end
    end
    puts ''
  end
end
