require 'rubygems'
# require 'crack'
require 'open-uri'
require 'rest-client'
require 'nokogiri' 
require 'mechanize'
require 'logger'
require 'JSON'
require 'sqlite3'

def readCredentials
  random_line = nil
  File.open("login.txt") do |file|
  file_lines = file.readlines()
  @APIKEY = file_lines[0]
  @USERNAME = file_lines[1]
  @PASSWORD = file_lines[2]
  end
end
readCredentials



class Session
	# Takes the username and password creates
	def auth(username, password)
		agent = Mechanize.new
		agent.get("https://www.etsy.com/ie/signin")
		agent.log = Logger.new "mechanize.log"
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
       Thank you for giving our shop some ❤️. If anything in particular catches your eye you can use this coupon code 'SHARETHELOVE' to get 20% Off any item on our store.\n
       Hope to see you soon, \n
       Mike | The Moose Creative |"
		send = agent.page.forms[2].submit
	end


end

# Test the session Class
	def sessionTest
		mytestAccount = 80353922
		# mytestAccount = 80353922
		session = Session.new
		session.auth(@USERNAME, @PASSWORD)
		session.submitComment(mytestAccount)
	end
# sessionTest #Run the sessionTest Method


@listingid = 192451863

class Listing

	# Takes the listing ID as an argument
	def getjson(listingid)
        response = open("https://openapi.etsy.com/v2/listings/#{listingid}/favored-by?api_key=#{@APIKEY}").read
        response = JSON.parse(response)
    	response = JSON.pretty_generate(response)
    	auth_file = File.open("data.json", "w")
    	auth_file.print response
    	auth_file.close 
	end
end #End of Listing Class

# Test the User Class
	def testListing
		listing = Listing.new
		listing.getjson(127179505)
	end
# testListing #Run the testUser Method



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
		file = open("data.json")
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

	def testDatabase
		database = Database.new
		database.createDB
		database.addUser
	end

# testDatabase

def run(listingId)

	listing = Listing.new
	@session = Session.new
	database = Database.new

	@mytestAccount = 80353922
	
	#Getting JSON Data based on the Listing ID
	listing.getjson(listingId)

	#Creating Database if it doesnt exist 
	database.createDB
	#Also adding JSON Data to the Database
	database.addUser

	@db = SQLite3::Database.open "Database/FavList.db"

		def upload #counts how many records in the database
		    results = @db.get_first_row "select Id from FavList order by Id desc limit 1"
		    results = results.join.to_i
		    @max_id = results + 1
		end #End of upload
		upload

	#Add user to the database
	def addUser
		#Creating Auth Session
		@session.auth(@USERNAME, @PASSWORD)

		@total_id = @max_id
		@max_id.times do
		    if @max_id >= 2
		            @max_id = @max_id - 1
		            @updated = @db.get_first_value "SELECT MessageSent FROM FavList WHERE Id='#{@max_id}'"
		            puts @updated 
		            puts @max_id

		        if @updated == "FALSE"
		            @user_id = @db.get_first_value "SELECT UserId FROM FavList WHERE Id='#{@max_id}'"
		            # puts @user_id
		            @db.execute "UPDATE FavList SET MessageSent='TRUE' WHERE Id='#{@max_id}'"
		            @session.submitComment(@user_id)
					# puts @user_id
		        else 

		        end
		    else 
		    	puts "Everything upto date"
		    end

		end
				#Submitting Comment to everyone in the Database
	end #End of addUser
	addUser
end #End of run

run(187018850)
run(127179505)
run(208315501)
run(260860360)
