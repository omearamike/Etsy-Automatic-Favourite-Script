require_relative 'main'
require 'json'

initilize = Initialize.new

initilize.prepareEnv

if File.exist?('settings.json') == false
	print "Would you like to create settings for this app? Y/n? "
	settings = gets.chomp
	if settings == "Y"
		initilize.createSettings
	else
		print "\nYou will need to create settings to use this app! \n\n"
	end
else 
	print "Super, All settings are already set.\n(Edit your settings.json file if needed.)\n"
end

# Test the session Class
	def sessionTest
		mytestAccount = 80353922
		session = Session.new
		session.auth(@USERNAME, @PASSWORD)
		session.submitComment(mytestAccount)
	end
# sessionTest #Run the sessionTest Method
# prepenv

# Test the User Class
	def testListing
		listing = Listing.new
		listing.getjson(127179505, @APIKEY)
	end
# testListing #Run the testUser Method

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
	listing.getjson(listingId, @APIKEY)

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

# run(187018850)
# run(127179505)
# run(208315501)
# run(260860360)
