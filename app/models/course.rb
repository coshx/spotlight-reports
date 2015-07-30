class Course < ActiveRecord::Base

  validates_uniqueness_of :canvas_id

  def compile_statgrid_data_single_course
    stats = { "discussions" => self.discussions, "files" => self.files, "assignments" => self.assignments, "gradesEntered" => self.grades }

    dates = stats.map do |stat_name, stat_dates|
      stat_dates.keys
    end
    dates.flatten!.uniq!

    stats_by_date = Hash.new(0)
    dates.each do |date|
      stats_by_date[date] = Hash.new(0)
      stats.each do |stat_name, stat_dates|
        stats_by_date[date][stat_name] = stat_dates[date]
      end
    end
    stats_by_date
  end

  def self.average_stats(school_id, start_date, end_date)
    school_id == 1 ? courses = Course.all : courses = Course.where(account_id: school_id)

    date_range = Date.parse(start_date)..Date.parse(end_date)

    course_count = courses.count
    stats = {
      "discussions_count" => 0,
      "files_count" => 0,
      "assignments_count" => 0,
      "grades_entered_count" => 0
    }
    percent_stats = {
      "participation" => 0.0,
      "access" => 0.0
    }
    grades_below_seventy = {
      "grades_below_seventy" => 0.0
    }

    students_count = 0
    grades_count = 0

    courses.each do |course|
      course.discussions.each do |date, discussions|
        next if date.empty?
        if date_range.include?(Date.parse(date))
          stats["discussions_count"] += discussions.to_i
        end
      end
      course.files.each do |date, files|
        if date_range.include?(Date.parse(date))
          stats["files_count"] += files.to_i
        end
      end
      course.assignments.each do |date, assignments|
        if date_range.include?(Date.parse(date))
          stats["assignments_count"] += assignments.to_i
        end
      end
      course.grades.each do |date, grades|
        if date_range.include?(Date.parse(date))
          stats["grades_entered_count"] += grades.to_i
        end
      end

      course.participation_and_access.each do |student, data|
        parsed_data = JSON.parse(data.gsub('=>',':'))
        students_count += 1
        parsed_data["participations"]
        percent_stats["participation"] += 1 if (date_range.to_a - parsed_data["participations"].map{|date| Date.parse(date)}).count < date_range.count
        parsed_data["page_views"]
        percent_stats["access"] += 1 if (date_range.to_a - parsed_data["page_views"].map{|date| Date.parse(date)}).count < date_range.count
      end

      course.grades_by_assignment.each do |assignment, data|
        next if data.include? "nil"
        parsed_data = JSON.parse(data.gsub('=>',':'))
        parsed_data["grades"].each do |grade|
          grades_count += 1
          if grade == "incomplete"
            grade = 0
          elsif grade == "complete"
            grade = parsed_data["points_possible"]
          elsif grade.include? "%"
            grade = grade.to_f/100
          end
          grades_below_seventy["grades_below_seventy"] += 1 if grade.to_f/parsed_data["points_possible"].to_f < 0.7
        end
      end
    end
    stats_averages = stats.map { |stat, value| [stat, value/course_count] }.to_h
    percent_stats_averages = percent_stats.map { |stat, value| [stat, ((value/students_count)*100).to_i] }.to_h
    grades_count == 0 ? grades_below_seventy_average = {"grades_below_seventy" => 0.0} : grades_below_seventy_average = grades_below_seventy.map { |stat, value| [stat, ((value/grades_count)*100).to_i ] }.to_h

    return stats_averages.merge percent_stats_averages.merge grades_below_seventy_average
  end

end
