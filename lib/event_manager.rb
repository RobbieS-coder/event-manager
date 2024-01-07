require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(number)
  number = number.scan(/\d+/).join
  if number.length == 10
    return number
  elsif number.length == 11 && number[0] == 1
    number.shift
    return number
  end
  'Invalid phone number'
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def most_frequent_sign_up_time(times)
  times.group_by { |element| element }.max_by { |key, value| value.length }[0]
end

hours = []
days = []

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

CAL = { 0 => "Sunday", 1 => "Monday", 2 => "Tuesday", 3 => "Wednesday", 4 => "Thursday", 5 => "Friday", 6 => "Saturday" }

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  date_info = row[:regdate]
  date = date_info.split(' ')[0]
  month, day, year = date.split('/')
  year = '20' + year
  day_of_week = Date.new(year.to_i, month.to_i, day.to_i).wday
  days << day_of_week

  time = date_info.split(' ')[1]
  hour = time.split(':')[0]
  hours << hour

  id = row[0]
  name = row[:first_name]
  number = clean_phone_number(row[:homephone])
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

puts "The hour that most people signed up was #{most_frequent_sign_up_time(hours)}."
puts "The day that most people signed up was #{CAL[most_frequent_sign_up_time(days)]}."