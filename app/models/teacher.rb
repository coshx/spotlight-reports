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
    Hash[ courses.map { |course| [ course.canvas_id, compile_statgrid_data_single_course(course) ] } ]
  end

  def compile_statgrid_data_single_course(course)
    discussions = get_discussions_posted_by_date(course)
    files = get_files_uploaded_by_date(course)
    assignments = get_assignments_created_by_date(course)

    stats = [discussions, files, assignments]
    dates = []
    stats.each do |stat|
      dates << stat.values.first.keys
    end
    dates.flatten!.uniq!
    dates

    stats_by_date = Hash.new(0)
    dates.each do |date|
      stats_by_date[date] = Hash.new(0)
      stats.each do |stat|
        stats_by_date[date][stat.keys.first] = stat.values.first[date]
      end
    end
    stats_by_date
  end

  def get_discussions_posted_by_date(course)
    discussions_list = canvas_api.list_discussion_topics_courses(course.canvas_id)
    dates = []
    discussions_list.each { |discussion| dates << discussion.posted_at.to_s[0..9] }
    discussions_by_date = Hash.new(0)
    dates.each do |date|
      discussions_by_date[date] += 1
    end
    {"discussions" => discussions_by_date}
  end

  def get_files_uploaded_by_date(course)
    file_list = canvas_api.list_files_courses(course.canvas_id)
    dates = []
    file_list.each { |file| dates << file.created_at.to_s[0..9] }
    files_by_date = Hash.new(0)
    dates.each do |date|
      files_by_date[date] += 1
    end
    {"files" => files_by_date}
  end

  def get_assignments_created_by_date(course)
    assignment_list = canvas_api.list_assignments(course.canvas_id)
    dates = []
    assignment_list.each { |assignment| dates << assignment.created_at.to_s[0..9] }
    assignments_by_date = Hash.new(0)
    dates.each do |date|
      assignments_by_date[date] += 1
    end
    {"assignments" => assignments_by_date}
  end

end
