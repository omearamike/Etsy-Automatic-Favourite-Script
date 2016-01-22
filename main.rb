require 'rubygems'
# require 'crack'
require 'open-uri'
require 'rest-client'
require 'nokogiri' 
require 'mechanize'
require 'logger'
require 'json'
require 'sqlite3'
require 'logger'


$log = Logger.new('Log/weekly.log', 'weekly')
      # $log.error "This works yes"

# Sets up Appliction to run for the first time.
class SetupApplication
# Creates the neccessary Directorys for the application to run
	def prepareEnv
		Dir.mkdir("WorkingFiles") unless File.exists?("WorkingFiles")
		Dir.mkdir("Log") unless File.exists?("Log")
		Dir.mkdir("Database") unless File.exists?("Database")
  end
# Allows listings Ids to be dynamically added to the settings file
 	YourStruct = Struct.new(:id, :listingid)
 	class YourStruct
 		  def to_json(*a)
 		    {:id => self.id, :listingid => self.listingid}.to_json(*a)
 		  end
 
 		  def self.json_create(o)
 		    new(o['id'], o['listingid'])
 		  end
 	end

# Creates the Settings file to run the application
	def createSettings
    $log.info "Creating Application settings"
		print "Enter your API Key: "
		apikey = gets.chomp
    print "Enter your User Id: "
    userid = gets.chomp
		print "Enter your Username: "
		username = gets.chomp
		print "Enter your Password: "
		password = gets.chomp

		listing = "x", x = 1, allListings = [ YourStruct.new("Nil", "Nil")] # Varibles needed for the next bit of code
 		while listing != "done" do
 		print "Enter the Listing ID Numbers you would like to add (When your finished type done): "
 		listing = gets.chomp
 		a = [ YourStruct.new(x, listing)]
 		allListings = allListings + a
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
          "UserId" => userid,
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

  def jsonOpen
    file = open("settings.json")
    file = file.read
    file = JSON.parse(file)
  end

     def _getApikey
      apiKey = jsonOpen['LoginCredentials']['ApiKey']
      return apiKey
     end

     def _getUserid
      userid = jsonOpen['LoginCredentials']['UserId']
      return userid
     end

     def _getUsername
      username = jsonOpen['LoginCredentials']['Username']
      return username
     end

     def _getPassword
      password = jsonOpen['LoginCredentials']['Password']
      return password
     end

     def _getSubject
      subject = jsonOpen['Message']['Subject']
      return subject
     end

     def _getMessage
      message = jsonOpen['Message']['Message']
      return message
     end

     def _getTotalListings
      count = jsonOpen['Listings'].count
      return count
     end

     def _getListing(index)
      listingid = jsonOpen['Listings'][index]['listingid']
      return listingid
     end

     def _getListingArray
      listingArray = jsonOpen['Listings']
      return listingArray
     end
end #End of SetupApplication Class

class Storeuser

  # Takes the listing ID and apikey as an argument creates JSON file for each listing
  def getjson(listingid, apikey)
      $log.info "New Json File Listing: #{listingid}" unless File.exists?("WorkingFiles/data_#{listingid}.json")
      response = open("https://openapi.etsy.com/v2/listings/#{listingid}/favored-by?api_key=#{apikey}").read
      response = JSON.parse(response)
      response = JSON.pretty_generate(response)
      auth_file = File.open("WorkingFiles/data_#{listingid}.json", "w")
      auth_file.print response
      auth_file.close 
  end

# Creates a New Database if needed
  def _newDatabase
    db = SQLite3::Database.new "Database/Favourites_users.db"
    db.execute "CREATE TABLE IF NOT EXISTS FavouriteUsers(Id INTEGER PRIMARY KEY, DATE TEXT, ListingId INT, UserId INT, MessageSent INT)"
    return db
  end

# Add users from Json file to the database
	def addUsers(listingid)
    file = open("WorkingFiles/data_#{listingid}.json")
    json = file.read
    parsed = JSON.parse(json)
    parsed['results'].each do |child|
    # db = _newDatabase
    @listing_id = child['listing_id']
    @user_id = child['user_id']
        if @user_id != nil
          @user_id = @user_id

        db = _newDatabase
        id = db.get_first_row "SELECT UserId FROM FavouriteUsers WHERE UserId='#{@user_id}'" 
        def existsCheck( db, id )
            testing = db.execute( "select 1 from FavouriteUsers where UserId = ?", [id] ).length > 0

            if testing == true   
            else 
            db.execute( "INSERT INTO FavouriteUsers ( DATE, ListingId, UserId, MessageSent ) VALUES ( CURRENT_TIMESTAMP, '#{@listing_id}', '#{@user_id}', 'TRUE' )" )
            end

        end #End of existsCheck Method
            
        existsCheck(db, id)

        else
          $log.warn "No UserId for user from Listing: #{listingid}" 
        end
      end #End of do loop
  end

  def totalRecords
    _newDatabase
    results = _newDatabase.get_first_row "select Id from FavouriteUsers order by Id desc limit 1"
    results = results.join.to_i
    @max_id = results + 1
  end
end #end of Database Class



class WebSession

  # Takes the username and password creates
  def _getAuthenticated(username, password)

    url = "https://www.etsy.com/ie/signin"

  resp = Net::HTTP.get_response(URI.parse(url))
    if resp.code.match(/20\d/)
      $log.info "Authentication Success: Status #{resp.code}"
    elsif resp.code.match(/40\d/)
      $log.fatal "Authentication Failed: Status #{resp.code}"
    else
      $log.debug "Authentication Potential Issue: Status #{resp.code}"
    end
    
    agent = Mechanize.new
    #handle the sign in stuff
    page = agent.get(url)
    page = page.body
    agent.log = Logger.new "Log/mechanize.log"
    agent.page.forms[2]
    agent.page.forms[2]["username"] = username
    agent.page.forms[2]["password"] = password
    loginin = agent.page.forms[2].submit
    agent.cookie_jar.save_as("cookies.yml")
    $log.info "Authenication Cookie: Successfully Obtained"
  end

  # Outputs list of the Index of all the records in databasee that are set to true
  def getUserids
    storeuser = Storeuser.new
    db = storeuser._newDatabase
    notUploadedIds = db.execute ("SELECT Id FROM FavouriteUsers WHERE MessageSent = 'TRUE'")
    return notUploadedIds
  end

$agent = Mechanize.new

  # Puts userid into link and takes the database index, subject and message as aurguemnts
  def _sendMessage(index, subject, message)


  websession = WebSession.new
  auth = websession._getAuthenticated('urbanmooseapparel', 'Mikemeara1995')

# Checks if the cookies are valid
    
    $agent.cookie_jar.load('cookies.yml')
    cookies = $agent.cookies
    cookies.each do |c|
    $log.warn "Session Cookie: Expired #{c.name} " if "#{c.expired?}" == "true"
    @flag = true if c.expired? == true 
    end # End of do

# If the cookie is not valid it will attempt to get new Session Cookie
    if @flag == true
        tempCred = SetupApplication.new
        tempUsername = tempCred._getUsername
        tempPassword = tempCred._getPassword
        _getAuthenticated(tempUsername, tempPassword)
      else
    end

    db = SQLite3::Database.new "Database/Favourites_users.db"
    userId = db.execute "SELECT UserId FROM FavouriteUsers WHERE Id='#{index}'" # Selects Userid
    userId = userId[0][0]
    url = "https://www.etsy.com/conversations/new?with_id=#{userId}&ref=pr_contact" # Forms the link which will be used to send message
    puts url
    page = $agent.get(url)
    body = page.body
    page = Nokogiri::HTML(body)
    name = page.css('span.default-recipient').text
    name = name.split(" ")[0]
    @name = name.capitalize 

    # Swaps out name in string with the name obtained from the webpage
    subject = subject.gsub! '#name', @name 
    message = message.gsub! '#name', @name 

    # Send the message out
    $agent.page.forms[2]["subject"] =  subject
    $agent.page.forms[2]["message"] = message
    $agent.page.forms[2].submit
    # db.execute "UPDATE FavouriteUsers SET MessageSent='FALSE' WHERE Id='#{index}'" #update Record to  True only if all the above was success full
    $log.info "Message Sent: Database Index = #{index} UserID = #{userId} Name = #{@name}"
  end
end
