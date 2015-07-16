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

end
