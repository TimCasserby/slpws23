require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'
require 'date'

enable :sessions
# RIKTIGT DOC

get('/') do
    redirect("objects/")
end

get('/verktyg') do
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    objectlistfetch = db.execute("SELECT * FROM objects WHERE class = 'Verktyg'") # WHERE user_id = ?",id
    commentsfetch = db.execute("SELECT * FROM comments")

    p "Alla: #{objectlistfetch}"
    slim(:verktyg, locals:{objectlist:objectlistfetch,comments:commentsfetch})
end

get('/maskiner') do
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    objectlistfetch = db.execute("SELECT * FROM objects WHERE class = 'Maskin'") # WHERE user_id = ?",id
    commentsfetch = db.execute("SELECT * FROM comments")

    p "Alla: #{objectlistfetch}"
    slim(:maskiner, locals:{objectlist:objectlistfetch,comments:commentsfetch})
end

get('/elektronik') do
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    objectlistfetch = db.execute("SELECT * FROM objects WHERE class = 'Elektronik'") # WHERE user_id = ?",id
    commentsfetch = db.execute("SELECT * FROM comments")

    p "Alla: #{objectlistfetch}"
    slim(:elektronik, locals:{objectlist:objectlistfetch,comments:commentsfetch})
end

get('/objects/') do 
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    objectlistfetch = db.execute("SELECT * FROM objects") # WHERE user_id = ?",id
    commentsfetch = db.execute("SELECT * FROM comments")
    # loggedinid = session[:id]
    loggedinusername = session[:loggedinusername]

    #p "Alla: #{objectlistfetch}"
    slim(:"objects/index", locals:{objectlist:objectlistfetch,comments:commentsfetch,username:loggedinusername})
end

get('/objects/new') do
    if session[:isadmin] != nil
        if session[:isadmin] == true
            slim(:"objects/new")
        else
            "Du är inte admin! Hacka inte min sida tack."
        end
    else
        "Du är inte inloggad!"
    end
end

get('/objects/:id/edit') do
    objectid = params[:id].to_i
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    objectfetch = db.execute("SELECT * FROM objects WHERE id = ?", objectid)
    slim(:"objects/edit", locals:{objectinfo:objectfetch})
end

post('/objects/:id/update') do
    objectid = params[:id].to_i
    status = params[:status]
    quantity = params[:quantity].to_i
    objectclass = params[:class]
    db = SQLite3::Database.new('db/database.db')
    db.execute("UPDATE objects SET quantity = ?, status = ?, class = ? WHERE id = ?", quantity, status, objectclass, objectid)
    redirect("/objects/#{objectid}/")
end

get('/objects/:id/') do
    objectid = params[:id].to_i
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    objectfetch = db.execute("SELECT * FROM objects WHERE id = ?", objectid)
    commentsfetch = db.execute("SELECT * FROM comments INNER JOIN users on users.id = comments.author_id WHERE object_id = ?", objectid)
    p "UNDER"
    p commentsfetch
    slim(:"objects/show", locals:{objectinfo:objectfetch,comments:commentsfetch})
end


post('/objects') do
    objectname = params[:name]
    objectquantity = params[:quantity]
    objectclass = params[:class]
    objectstatus = params[:status]
    objectauthor = params[:author]
    db = SQLite3::Database.new('db/database.db')
    db.execute('INSERT INTO objects (name, quantity, class, status, author) VALUES (?,?,?,?,?)',objectname, objectquantity, objectclass, objectstatus, objectauthor)
    redirect("/objects/new")

end

post('/objects/:id/delete') do
    objectid = params[:objectid]
    # id = session[:id].to_i
    db = SQLite3::Database.new('db/database.db')
    db.execute("DELETE FROM objects WHERE id='#{objectid}'")
    redirect("/objects/")

end

post('/objects/:id/deletecomment') do
    objectid = params[:id]
    comment_id = params[:commentid]
    db = SQLite3::Database.new('db/database.db')
    db.execute("DELETE FROM comments WHERE comment_id='#{comment_id}'")
    redirect("/objects/#{objectid}/")

end

get('/logout') do
    session.clear
    redirect('/objects/')
end



post('/objects/:id/newcomment') do
    commenttext = params[:commenttext]
    authorid = params[:authorid]
    objectid = params[:objectid]
    if session[:isadmin] == nil
        raise("Du får bara lägga till kommentarer om du är inloggad.")
    end
    date = DateTime.now #VI FIXAR DETTA SEN
    date = date.strftime "%d/%m/%Y %H:%M"
    db = SQLite3::Database.new('db/database.db')
    db.execute('INSERT INTO comments (object_id, author_id, text, date) VALUES (?,?,?,?)',objectid, authorid, commenttext, date)
    redirect("/objects/#{objectid}/")

end

get('/login') do
    slim(:login)
end

post('/login') do
    username = params[:username]
    password = params[:password]
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    result = db.execute('SELECT * FROM users WHERE name = ?', username).first
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
  end

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
      db = SQLite3::Database.new('db/database.db')
      db.execute('INSERT INTO users (name, encryptedpassword, join_date, rank) VALUES (?,?,?,?)',username, password_digest, join_date, rank)
      redirect("/objects/")
    else
      # felhantering
      "Lösenorden matchade inte!"
    end
  
  end