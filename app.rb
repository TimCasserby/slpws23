require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

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
    slim(:"objects", locals:{objectlist:objectlistfetch})
end

get('/objects/new') do
    slim(:inlägg)
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