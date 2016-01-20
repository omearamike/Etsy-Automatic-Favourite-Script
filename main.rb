require 'rubygems'
# require 'crack'
require 'open-uri'
require 'rest-client'
require 'nokogiri' 
require 'mechanize'
require 'logger'
require 'json'
require 'sqlite3'

# Sets up Appliction to run for the first time
class Initialize
# Creates the neccessary Directorys for the application to run
	def prepareEnv
		Dir.mkdir("WorkingFiles") unless File.exists?("WorkingFiles")
		Dir.mkdir("Log") unless File.exists?("Log")
		Dir.mkdir("Database") unless File.exists?("Database")
	end 

# Allows listings Ids to be dynamically added to the settings file
	YourStruct = Struct.new(:id, :listing)
	class YourStruct
		  def to_json(*a)
		    {:id => self.id, :listing => self.listing}.to_json(*a)
		  end

		  def self.json_create(o)
		    new(o['id'], o['car'])
		  end
	end

# Takes the revelent Application Settings from User
	def createSettings
		print "Enter your API Key: "
		apikey = gets.chomp
		print "Enter your Username: "
		username = gets.chomp
		print "Enter your Password: "
		password = gets.chomp

		listing = "x", x = 1, b = [ YourStruct.new("Nil", "Nil")] # Varibles needed for the next bit of code
		while listing != "done" do
		print "Enter the Listing ID Numbers you would like to add (When your finished type done): "
		listing = gets.chomp
		a = [ YourStruct.new(x, listing)]
		allListings = b + a
		x = x + 1
		end
		allListings.pop
		allListings.shift

	  	print "Enter your Subject Line: "
	  	subject = gets.chomp
	  	print "Enter your Desired Message: "
	  	message = gets.chomp
	  	print "Good Job, Settings are Ready.\n (Edit your settings.json file if needed.)\n"

	  	tempHash = {
	  	"LoginCredentials" => {
	  		"ApiKey" => apikey,
   			"Username" => username,
   			"Password" => password
	  	},
	  	"Listings" => allListings,
	  	"Message" => {
	  		"Subject" => subject,
	  		"Message" => message
	  	}	
	}
		tempHash = tempHash.to_json
        tempHash = JSON.parse(tempHash)
    	tempHash = JSON.pretty_generate(tempHash)
		File.open("settings.json","w") do |f|
		f.write(tempHash)
		end
	end # createSettings
end #End of Initialize Class

class Session
	# Takes the username and password creates
	def auth(username, password)
		agent = Mechanize.new
		agent.get("https://www.etsy.com/ie/signin")
		agent.log = Logger.new "Log/mechanize.log"
		agent.page.forms[2]
		agent.page.forms[2]["username"] = username
		agent.page.forms[2]["password"] = password
		loginin = agent.page.forms[2].submit
		@agent = agent
	end

	# Puts userid into link and takes the subject and the message
	def submitComment(userid, subject = "Subject", message = "Message")
                agent = @agent
                page = agent.page.body
                favourites = agent.get("https://www.etsy.com/ie/conversations/new?with_id=#{userid}&ref=pr_contact")
                body = favourites.body
                page = Nokogiri::HTML(body)
                name = page.css('span.default-recipient')[0].text
                name = name.split(" ")[0]
                @name = name.capitalize
                agent.page.forms[2]["subject"] =  "Hey #{@name}, thanks for the ❤️"
                agent.page.forms[2]["message"] = "Hey #{@name},\n
        Thank you for giving our shop some ❤️. If anything in particular catches your eye you can use this coupon code SHARETHELOVE to get 20% Off any item on our store.\n
        http://bit.ly/favTMC \n
        Hope to see you soon, \n
        Mike | The Moose Creative |"
                send = agent.page.forms[2].submit
        end



end



class Listing

	# Takes the listing ID as an argument
	def getjson(listingid, apikey)
        response = open("https://openapi.etsy.com/v2/listings/#{listingid}/favored-by?api_key=#{apikey}").read
        response = JSON.parse(response)
    	response = JSON.pretty_generate(response)
    	auth_file = File.open("WorkingFiles/data.json", "w")
    	auth_file.print response
    	auth_file.close 
	end
end #End of Listing Class


class Database

	#Creates the Database if it does not exist
	def createDB
		@root = File.dirname(__FILE__)
		begin
		    # SQLite3::Database.new "SANDBOX_DB.db"
		    db = SQLite3::Database.new "Database/FavList.db"
		    db.execute "CREATE TABLE IF NOT EXISTS FavList(Id INTEGER PRIMARY KEY, DATE TEXT, ListingId INT, UserId INT, MessageSent INT)"

		rescue SQLite3::Exception => e 
		    
		    puts "Exception occurred"
		    puts e  
		ensure
		    db.close if db
		end
	end #End of createDB Method

	#Add user to Database
	def addUser
		file = open("WorkingFiles/data.json")
        json = file.read
        parsed = JSON.parse(json)
        parsed['results'].each do |child|
        @listing_id = child['listing_id']
        @user_id = child['user_id']
        if @user_id == nil
        	@user_id = 0000000
        else
        	@user_id = @user_id
        end


        db = SQLite3::Database.open "Database/FavList.db"
        id = db.get_first_row "SELECT UserId FROM FavList WHERE UserId='#{@user_id}'" 

        # Ensures no duplicates and then adds the record
        def existsCheck( db, id )
            testing = db.execute( "select 1 from FavList where UserId = ?", [id] ).length > 0
            
            if testing == true   
            else 
            db.execute( "INSERT INTO FavList ( DATE, ListingId, UserId, MessageSent ) VALUES ( CURRENT_TIMESTAMP, '#{@listing_id}', '#{@user_id}', 'FALSE' )" )
            end

        end #End of existsCheck Method
            
        existsCheck(db, id)

    	end #End of do loop
	end #End of addUser Method

end #end of Database Class

