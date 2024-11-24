module App
using FactSimply
using GenieFramework
using StippleLatex
using StippleUI

@genietools

@app begin
    # Reactive variables
    @in slider_value = 0.5
    @in text_input = ""
end

function ui()
    [
       
            slider(:slider_value)
            textinput(:text_input)
    
            ]
end

@page("/", ui)
end