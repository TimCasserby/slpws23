require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

get('/') do
    slim(:verktyg)
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
    slim(:objects)
end

get('/inlägg') do
    slim(:inlägg)
end

post('/objects') do
    # hej
    # redirect
end