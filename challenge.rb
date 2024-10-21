require 'json'

USER_FILE = "users.json"
COMAPNIES_FILE = "companies.json"

# Load JSON files and parse them
def load_json(file_name)
	begin
		file = File.read(file_name)
		JSON.parse(file, symbolize_names: true)
	rescue StandardError => e
		raise "Error reading file #{file_name}: #{e.message}"
	end
end

def is_valid_user_and_company?(user, company)
  required_user_fields = %i[company_id active_status tokens email_status first_name last_name email]
  required_company_fields = %i[id top_up email_status]

  (required_user_fields - user.keys).empty? && (required_company_fields - company.keys).empty?
end

def write_user_info(file, user)
  file.puts "		#{user[:last_name]}, #{user[:first_name]}, #{user[:email]}"
	file.puts "		  Previous Token Balance, #{user[:previous_tokens]}"
	file.puts "		  New Token Balance #{user[:new_tokens]}"
end

def write_company_info(file, company, users_emailed, users_not_emailed, total_top_up)
	# Write company info
	file.puts "	Company Id: #{company[:id]}"
	file.puts "	Company Name: #{company[:name]}"

	# Write users emailed section
	file.puts "	Users Emailed:"
	unless users_emailed.empty?
		users_emailed.each { |user| write_user_info(file, user) }
	end

	# Write users not emailed section
	file.puts "	Users Not Emailed:"
	unless users_not_emailed.empty?
		users_not_emailed.each { |user| write_user_info(file, user) }
	end

	# Write total top up for the company
	file.puts "		Total amount of top ups for #{company[:name]}: #{total_top_up}"
	file.puts "\n"
end

def generate_output(users, companies)
  File.open('output.txt', 'w') do |file|
		companies.each do |company|
			# Select active users who belong to this company
			company_users = users.select { |user| user[:company_id] == company[:id] && user[:active_status] }
			
			next if company_users.empty?

			users_emailed = []
			users_not_emailed = []
	
			total_top_up = 0
			company_users.sort_by! { |user| user[:last_name] }
			
			# Process each user in the company
			company_users.each do |user|
				next unless is_valid_user_and_company?(user, company)

				previous_tokens = user[:tokens]
				user[:tokens] += company[:top_up]
				total_top_up += company[:top_up]
				
				user_info = {
          last_name: user[:last_name],
          first_name: user[:first_name],
          email: user[:email],
          previous_tokens: previous_tokens,
          new_tokens: user[:tokens]
        }

				if company[:email_status] && user[:email_status]
					users_emailed << user_info
				else
					users_not_emailed << user_info
				end
			end

			write_company_info(file, company, users_emailed, users_not_emailed, total_top_up)
		end
	end
  puts 'output.txt file generated successfully.'
end

# Main method to drive the process
def process_files()
  users = load_json(USER_FILE)
  companies = load_json(COMAPNIES_FILE)
  # Check for missing or invalid data
  unless users.is_a?(Array) && companies.is_a?(Array)
    puts "Invalid input data. Expected arrays for users and companies."
    return
  end

  generate_output(users, companies)
end

process_files