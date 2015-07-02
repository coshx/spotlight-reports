class Teacher < ActiveRecord::Base

  def canvas_api
    Pandarus::Client.new(prefix: ENV['API_URL'], token: ENV['API_TOKEN'])
  end

  def get_courses
    enrollments = canvas_api.list_enrollments_users(canvas_id, type:"TeacherEnrollment")
    course_ids = enrollments.map {|enrollment| enrollment.course_id}
    course_ids.map { |course_id| Course.where(canvas_id: course_id) }.flatten.uniq
  end

  def get_course_data(courses)
    Hash[ courses.map { |course| [ course.canvas_id, HTTParty.get(ENV['API_URL'] + "/v1/courses/" + course.canvas_id.to_s + "/analytics/activity?access_token=" + ENV['API_TOKEN'])] } ]
  end

  def compile_statgrid_data(courses)
    Hash[ courses.map { |course| [ course.canvas_id, course.compile_statgrid_data_single_course ] } ]
  end

  def get_student_data(courses)
    student_data_by_course = Hash.new(0)
    courses.each do |course|
      student_data_by_course[course.canvas_id] = Hash.new(0)
      student_ids = canvas_api.list_students(course.canvas_id).entries.map {|s| s.id}
      student_ids.each do |student_id|
        student_hash = Hash.new(0)
        student_data = HTTParty.get(ENV['API_URL'] + "/v1/courses/#{course.canvas_id.to_s}/analytics/users/#{student_id}/activity?access_token=" + ENV['API_TOKEN']).to_hash
        next if student_data.keys.include?("errors")
        student_data["page_views"].nil? ? student_hash["page_views"] = [] : student_hash["page_views"] = student_data["page_views"].keys
        student_data["participations"].nil? ? student_hash["participations"] = [] : student_hash["participations"] = student_data["participations"].map {|p| p["created_at"]}
        student_data_by_course[course.canvas_id][student_id] = student_hash
      end
    end
    student_data_by_course
  end

  def days_since_last_access
    return "No data" if canvas_api.list_user_page_views(canvas_id).first.nil?
    last_access = canvas_api.list_user_page_views(canvas_id).first.created_at
    (Date.today - last_access).to_i
  end

end
