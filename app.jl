module App
using FactSimply
using GenieFramework
@genietools

@app begin
    #reactive code goes here
end

function ui()
    p("") #initialized to an empty paragraph
end

@page("/", ui)
end