require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'

get('/') do
    redirect("objects/index")
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

get('/objects/index') do #DETTA FÖLJER INTE RESTFUL
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    objectlistfetch = db.execute("SELECT * FROM objects") # WHERE user_id = ?",id
    p "Alla: #{objectlistfetch}"
    slim(:"objects/index", locals:{objectlist:objectlistfetch})
end

get('/objects/new') do
    slim(:add_item)
end

get('/objects/:id/') do
    objectid = params[:id].to_i
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    objectfetch = db.execute("SELECT * FROM objects WHERE id = ?", objectid)
    p objectfetch
    slim(:"objects/object_detailview", locals:{objectinfo:objectfetch})
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