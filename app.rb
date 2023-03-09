require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'
require 'date'

get('/') do
    redirect("objects/")
end

get('/verktyg') do
    slim(:verktyg)
end

get('/maskiner') do
    slim(:maskiner)
end

get('/elektronik') do
    slim(:elektronik)
end

get('/objects/') do 
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    objectlistfetch = db.execute("SELECT * FROM objects") # WHERE user_id = ?",id
    p "Alla: #{objectlistfetch}"
    slim(:"objects/index", locals:{objectlist:objectlistfetch})
end

get('/objects/new') do
    slim(:"objects/new")
end

get('/objects/:id/edit') do
    objectid = params[:id].to_i
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    objectfetch = db.execute("SELECT * FROM objects WHERE id = ?", objectid)
    slim(:"objects/edit", locals:{objectinfo:objectfetch})
end

get('/objects/:id/') do
    objectid = params[:id].to_i
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    objectfetch = db.execute("SELECT * FROM objects WHERE id = ?", objectid)
    commentsfetch = db.execute("SELECT * FROM comments WHERE object_id = ?", objectid)
    p objectfetch
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
    redirect("../objects/new")

end

post('/objects/:id/delete') do
    objectid = params[:objectid]
    # id = session[:id].to_i
    db = SQLite3::Database.new('db/database.db')
    db.execute("DELETE FROM objects WHERE id='#{objectid}'")
    redirect("/objects/")

end



post('/objects/:id/newcomment') do
    commenttext = params[:commenttext]
    authorid = params[:authorid]
    objectid = params[:objectid]
    date = DateTime.now #VI FIXAR DETTA SEN
    date = date.strftime "%d/%m/%Y %H:%M"
    db = SQLite3::Database.new('db/database.db')
    db.execute('INSERT INTO comments (object_id, author_id, text, date) VALUES (?,?,?,?)',objectid, authorid, commenttext, date)
    redirect("../objects/#{objectid}/")

end