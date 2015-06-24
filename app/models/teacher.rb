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

end
