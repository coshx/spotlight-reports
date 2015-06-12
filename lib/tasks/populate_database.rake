task populate_database: :environment do

  Account.destroy_all
  Course.destroy_all
  Teacher.destroy_all

  # Authenticate API access
  client = Pandarus::Client.new(
    prefix: ENV['API_URL'],
    token: ENV['API_TOKEN'])

  # Get accounts from Canvas
  puts 'Getting Accounts'
  main_account = client.list_accounts
  Account.create(
    canvas_id: main_account.first.id,
    name: main_account.first.name
    )

  sub_accounts = client.get_sub_accounts_of_account(1)
  sub_accounts.each do |sub_account|

    Account.create(
      canvas_id: sub_account.id,
      name: sub_account.name
      )

    puts 'Getting Courses'
    courses = client.list_active_courses_in_account(sub_account.id, with_enrollments:"true", published:"true")
    courses.each do |course|
      Course.create(
        canvas_id: course.id,
        account_id: course.account_id,
        name: course.name
        )
      print '.'
    end

    puts 'Getting Teachers'
    enrollments_by_course = courses.map do |course|
      client.list_enrollments_courses(course.id, type:"TeacherEnrollment")
    end

    teachers = enrollments_by_course.map do |course|
      course.entries.map do |enrollment|
        enrollment.user
      end
    end

    teachers.flatten!.uniq!{|t| t.id}

    teachers.each do |teacher|
      Teacher.create(
        canvas_id: teacher.id,
        name: teacher.name,
        sortable_name: teacher.sortable_name,
        avatar_url: teacher.avatar_url,
        school_account: sub_account.id
        )
    end
  end
end
