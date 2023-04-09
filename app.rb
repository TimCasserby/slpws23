require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'
require 'date'
require_relative 'model/model.rb'

enable :sessions
# RIKTIGT DOC

# Instantiate a new Model object and load the database
model = Model.new
model.loaddatabase('db/database.db')

# Redirect to landing page
#
get('/') do
    redirect("objects/")
end

# Display a list of tools (Verktyg) from the database
#
# @return [slim] Render the list of Verktyg objects and associated comments
get('/verktyg') do
    # db = SQLite3::Database.new('db/database.db')
    # db.results_as_hash = true
    # objectlistfetch = db.execute("SELECT * FROM objects WHERE class = 'Verktyg'") # WHERE user_id = ?",id
    # commentsfetch = db.execute("SELECT * FROM comments")
    objectlistfetch = model.get_objects_by_class('Verktyg')
    commentsfetch = model.get_comments()

    slim(:verktyg, locals:{objectlist:objectlistfetch,comments:commentsfetch})
end

# Display a list of machines (Maskin) from the database
#
# @return [slim] Render the list of Maskin objects and associated comments
get('/maskiner') do
    objectlistfetch = model.get_objects_by_class('Maskin')
    commentsfetch = model.get_comments()

    p "Alla: #{objectlistfetch}"
    slim(:maskiner, locals:{objectlist:objectlistfetch,comments:commentsfetch})
end

# Display a list of electronics (Elektronik) from the database
#
# @return [slim] Render the list of Elektronik objects and associated comments
get('/elektronik') do
    objectlistfetch = model.get_objects_by_class('Elektronik')
    commentsfetch = model.get_comments()

    p "Alla: #{objectlistfetch}"
    slim(:elektronik, locals:{objectlist:objectlistfetch,comments:commentsfetch})
end

# Display a list of all objects from the database
#
# @return [slim] Render the list of all objects and associated comments
get('/objects/') do 
    objectlistfetch = model.get_objects
    commentsfetch = model.get_comments()
    loggedinusername = session[:loggedinusername]

    #p "Alla: #{objectlistfetch}"
    slim(:"objects/index", locals:{objectlist:objectlistfetch,comments:commentsfetch,username:loggedinusername})
end

# Display a form for adding a new object to the database
#
# @return [slim] Render the form for adding a new object
get('/objects/new') do
    if session[:id] == nil
        raise("Du är inte inloggad!")
    end
    fetch = model.get_user_by_name(session[:loggedinusername])
    loggedinusername = fetch["name"]
    if session[:isadmin] != nil
        if session[:isadmin] == true
            slim(:"objects/new", locals:{username:loggedinusername})
        else
            "Du är inte admin! Hacka inte min sida tack."
        end
    else
        "Du är inte inloggad!"
    end
end

# Display a form for editing an object in the database
#
# @return [slim] Render the form for editing an object
get('/objects/:id/edit') do
    # objectid = params[:id].to_i
    # db = SQLite3::Database.new('db/database.db')
    # db.results_as_hash = true
    # objectfetch = db.execute("SELECT * FROM objects WHERE id = ?", objectid)
    objectid = params[:id].to_i
    objectfetch = model.get_object(objectid)
    p objectfetch
    slim(:"objects/edit", locals:{objectinfo:objectfetch})
end

# Update an object in the database
#
# @return [redirect] Redirect to the object page
post('/objects/:id/update') do
    objectid = params[:id].to_i
    status = params[:status]
    quantity = params[:quantity].to_i
    objectclass = params[:class]
    if session[:isadmin] != nil
        if session[:isadmin] == true
            model.update_object(objectid, status, quantity, objectclass)
            redirect("/objects/#{objectid}/")
        else
            raise("Du är inte admin. Du kan inte ändra objekt.")
        end
    else
        raise("Du är inte inloggad. Du kan inte ändra objekt.")
    end
    
end

# Display the page for a specific object
#
# @param [Integer] :id The id of the object to display
# @return [slim] Render the object page and associated comments
get('/objects/:id/') do
    objectid = params[:id].to_i
    objectfetch = model.get_object(objectid)
    commentsfetch = model.get_comments_by_object_id(objectid)
    slim(:"objects/show", locals:{objectinfo:objectfetch,comments:commentsfetch,userid:session[:id]})
end

# Add a new object to the database
#
# @param [String] :name The name of the new object
# @param [Integer] :quantity The quantity of the new object
# @param [String] :class The class of the new object
# @param [String] :status The status of the new object
# @param [String] :author The author of the new object
# @return [redirect] Redirect to the new object form
post('/objects') do
    objectname = params[:name]
    objectquantity = params[:quantity]
    objectclass = params[:class]
    objectstatus = params[:status]
    objectauthor = params[:author]
    if session[:isadmin] != nil
        if session[:isadmin] == true
            model.add_object(objectname, objectquantity, objectclass, objectstatus, objectauthor)
            redirect("/objects/new")
        else
            "Du är inte admin! Hacka inte min sida tack."
        end
    else
        "Du är inte inloggad!"
    end

end

# Delete an object from the database
#
# @param [Integer] :id The id of the object to delete
# @return [redirect] Redirect to the objects page
post('/objects/:id/delete') do
    objectid = params[:objectid]
    # id = session[:id].to_i
    if session[:isadmin] != nil
        if session[:isadmin] == true
            model.delete_object(objectid)
            # p objectid
            # model.remove_comments_for_object(objectid)
            redirect("/objects/")
        else
            raise("Du är inte admin. Du kan inte ta bort objekt.")
        end
    else
        raise("Du är inte inloggad. Du kan inte ta bort objekt.")
    end

end

# Delete a comment from the database
#
# @param [Integer] :id The id of the object associated with the comment
# @param [Integer] :commentid The id of the comment to delete
# @return [redirect] Redirect to the object page
post('/objects/:id/deletecomment') do
    objectid = params[:id]
    comment_id = params[:commentid]
    p comment_id
    result = model.get_comment(comment_id)
    if session[:isadmin] == nil or session[:isadmin] == false
        p session[:isadmin]
        p session[:id]
        p result["author_id"]
        p result
        if session[:id] == result["author_id"]
            p "Han tar bort sin egen comment bara"
        else
            raise("Du får bara ta bort kommentarer om du är admin eller ägaren av kommentaren.")
        end
    end
    model.delete_comment(comment_id)
    redirect("/objects/#{objectid}/")

end

# Clear the session (no logout page shown)
#
# @return [redirect] Redirect to the objects page
get('/logout') do
    session.clear
    redirect('/objects/')
end

# Add a new comment to the database
#
# @param [String] :commenttext The text of the comment to add
# @param [Integer] :authorid The id of the user who authored the comment
# @param [Integer] :objectid The id of the object associated with the comment
# @return [redirect] Redirect to the object page
post('/objects/:id/newcomment') do
    commenttext = params[:commenttext]
    authorid = params[:authorid]
    objectid = params[:objectid]
    if session[:isadmin] == nil
        raise("Du får bara lägga till kommentarer om du är inloggad.")
    end
    date = DateTime.now #VI FIXAR DETTA SEN
    date = date.strftime "%d/%m/%Y %H:%M"
    model.add_comment(objectid, authorid, commenttext, date)
    redirect("/objects/#{objectid}/")

end

# Display the login page
#
# @return [slim] Render the login page
get('/login') do
    slim(:login)
end

# Authenticate a user and log them in
#
# @param [String] :username The username to authenticate
# @param [String] :password The password to authenticate
# @return [redirect] Redirect to the objects page
post('/login') do
    # JAG SKA KOMPLETTERA MED EN COOLDOWN
    username = params[:username]
    password = params[:password]
    result = model.get_user_by_name(username)
    if result != nil
        pwdigest = result["encryptedpassword"]
        id = result["id"]
        loggedinusername = result["name"]
    
        if BCrypt::Password.new(pwdigest) == password
            session[:id] = id
            session[:loggedinusername] = loggedinusername

            p loggedinusername
            p session[:loggedinusername] #RETURNAR RÄTT USERNAME

            admin = false
            if result != nil
                if result["rank"] == 2
                    admin = true
                end
            end

            session[:isadmin] = admin

            redirect("/objects/")
            p "DU FICK RÄTT LÖSENORD"
        else
            p "DU FICK FEL LÖSENORD"
            "FEL LÖSENORD!"
        end
    else
        "Fel användarnamn."
    end
  end

# Display the registration form (admin only)
#
# @return [slim] Render the registration form
get('/register') do
    if session[:isadmin] != nil
        if session[:isadmin] == true
            slim(:register)
        else
            "Du är inte admin! Hacka inte min sida tack."
        end
    else
        "Du är inte inloggad!"
    end
  end

# Add a new user to the database (admin only)
#
# @param [String] :username The username of the new user
# @param [String] :password The password of the new user
# @param [String] :password_confirm The confirmation password of the new user, has to be same as first password to proceed
# @param [String] :userrank The rank of the new user (user or admin)
# @return [redirect] Redirect to the objects page
post('/users/new') do
    if session[:isadmin] != true
        raise("HACKING ATTEMPT?")
    end
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    date = DateTime.now #VI FIXAR DETTA SEN
    date = date.strftime "%d/%m/%Y"
    join_date = date
    rank = params[:userrank]
  
    if (password == password_confirm)
      # lägg till användare
      password_digest = BCrypt::Password.create(password)
      model.add_user(username, password_digest, join_date, rank)
      redirect("/objects/")
    else
      # felhantering
      "Lösenorden matchade inte!"
    end
  
  end