class Course < ActiveRecord::Base

  def canvas_api
    Pandarus::Client.new(prefix: ENV['API_URL'], token: ENV['API_TOKEN'])
  end

  def compile_statgrid_data_single_course
    discussions = get_discussions_posted_by_date
    files = get_files_uploaded_by_date
    assignments = get_assignments_created_by_date

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

  def get_discussions_posted_by_date
    discussions_list = canvas_api.list_discussion_topics_courses(canvas_id)
    dates = []
    discussions_list.each { |discussion| dates << discussion.posted_at.to_s[0..9] }
    discussions_by_date = Hash.new(0)
    dates.each do |date|
      discussions_by_date[date] += 1
    end
    {"discussions" => discussions_by_date}
  end

  def get_files_uploaded_by_date
    file_list = canvas_api.list_files_courses(canvas_id)
    dates = []
    file_list.each { |file| dates << file.created_at.to_s[0..9] }
    files_by_date = Hash.new(0)
    dates.each do |date|
      files_by_date[date] += 1
    end
    {"files" => files_by_date}
  end

  def get_assignments_created_by_date
    assignment_list = canvas_api.list_assignments(canvas_id)
    dates = []
    assignment_list.each { |assignment| dates << assignment.created_at.to_s[0..9] }
    assignments_by_date = Hash.new(0)
    dates.each do |date|
      assignments_by_date[date] += 1
    end
    {"assignments" => assignments_by_date}
  end

end
