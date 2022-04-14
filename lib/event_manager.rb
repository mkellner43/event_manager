require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end 

def clean_phone(phone)
  workable_phone = phone.to_s.delete("^0-9").split('')
  return workable_phone.join if workable_phone.length == 10
  if workable_phone.length == 11 and workable_phone[0] == '1' 
    workable_phone.shift
    workable_phone.join
  else
    '0000000000'
  end 
end  

hour = nil
day = nil
hour_registered = []
day_registered = []
days_of_the_week = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

def day_and_time_registered(day_and_time, hour_registered, day_registered)
  day_time = DateTime.strptime(day_and_time, "%m/%d/%y %H:%M")
  hour = day_time.hour
  day = day_time.wday
  puts "registered on day ##{day} of the week on hour ##{hour} of the day"
  hour_registered.push(hour)
  day_registered.push(day)
end

def best_time_to_run_ads(hour_registered, day_registered, days_of_the_week)
  hour_most_common = hour_registered.max_by { |h| hour_registered.count(h)}
  day_most_common = day_registered.max_by { |d| day_registered.count(d)}
  puts "The most common day for registration was #{days_of_the_week[day_most_common]} at hour ##{hour_most_common}"
end 

def legislator_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin 
    legislators = civic_info.representative_info_by_address(
      address: 80202,
      levels: 'country', 
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officals
    rescue
      'You can find your representative by visiting www.commoncause.org/take-action/find-elected-officals' 
    end 
end 

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end 
end 

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  registered = day_and_time_registered(row[:regdate], hour_registered, day_registered)
  phone_number = clean_phone(row[:homephone]) 
  zipcode = clean_zipcode(row[:zipcode])
  

  legislators = legislator_by_zipcode(zipcode)
  #form_letter = erb_template.result(binding)
  #save_thank_you_letter(id, form_letter)
end 

best_time_to_run_ads(hour_registered, day_registered, days_of_the_week)
