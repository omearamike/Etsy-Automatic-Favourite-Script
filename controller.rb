require_relative 'main'
require 'benchmark'
require 'json'

# Creates the settings and folders for the app to run
def createSettings
	initilize = SetupApplication.new
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
		# print "Super, All settings are already set.\n(Edit your settings.json file if needed.)\n"
	end
end #End of createSettings Method

# Settings saved in run time memory for use in the application
def tempSettings
	getsettings = SetupApplication.new
	@APIKEY = getsettings._getApikey
	@USERID = getsettings._getUserid
	@USERNAME = getsettings._getUsername
	@PASSWORD = getsettings._getPassword
	@LISTINGARRAY = getsettings._getListingArray
	@LISTINGCOUNT = getsettings._getTotalListings
	@SUBJECT = getsettings._getSubject
	@MESSAGE = getsettings._getMessage
end

# Print all the current settings
def printSettings
	puts "API Key = " + @APIKEY
	puts "User ID = " + @USERID
	puts "Username = " + @USERNAME
	puts "Password = " + @PASSWORD	

	z = 0 
	x = @LISTINGCOUNT
    while x != z do
	puts "Listings #{z + 1} = " + @LISTINGARRAY[z]['listingid'].to_s
	z = z + 1
	end

	puts "Subject = " + @SUBJECT
	puts "Message = " + @MESSAGE
end

# Gets JSON data of all favourites for all listings
def getJson
	storeuser = Storeuser.new
	z = 0 
	x = @LISTINGCOUNT
    while x != z do
	storeuser.getjson(@LISTINGARRAY[z]['listingid'].to_s, @APIKEY)
	z = z + 1
	end
end

# Creates and formats new database if not already there also returns database instance 
def newDatabase
	storeuser = Storeuser.new
	storeuser._newDatabase
end

# Adds users based on listing id to the database
def addUsers
	storeuser = Storeuser.new
	z = 0 
	x = @LISTINGCOUNT
    while x != z do
	storeuser.addUsers(@LISTINGARRAY[z]['listingid'].to_s)
	z = z + 1
	end
end

# Signin with spider
def getAuthenticated
	websession = WebSession.new
	auth = websession._getAuthenticated(@USERNAME, @PASSWORD)
end

def sendMessage
	websession = WebSession.new
	array = websession.getUserids
	# agent = getAuthenticated
	# puts array
    array.each do |index|
    	websessionn = WebSession.new

      # ind = index.to_s
      # ind = ind.delete('[').to_i
      ind = 179
      websessionn._sendMessage(ind, @SUBJECT, @MESSAGE) 
    end
end


def runApplication
	createSettings # Sets environment and creates Settings file if it does not exist
	tempSettings # Stores settings in Application runtime memory
	getJson # Gets seperate JSON files of all favourites for each listing
	newDatabase # Prepares database if has not been created yet
	addUsers # Adds users based on listing id to the database
	sendMessage
	# puts websession.this
end
time = Benchmark.measure {
	runApplication
 }
 puts time.real #or save it to logs
def testApplication
	printSettings # Print all current Settings

end
# testApplication

# run(187018850)
# run(127179505)
# run(208315501)
# run(260860360)

