module App
using FactSimply
using GenieFramework


using StippleLatex
using StippleUI

@genietools

@kwdef mutable struct Fact{P}
    id::Int
    what_text::String
    when_text::String
    prob_range::P
    is_query::Bool
    printable::String = ""
end

function Fact(id, what_text, when_text, prob_range, is_query)
    f = Fact{typeof(prob_range)}(id, what_text, when_text, prob_range, is_query, "")
    f.printable = to_string(f)
    return f
end

# function Base.convert(
#       ::Type{RangeData{Float64}},
#       r::@NamedTuple{min::Float64, max::Float64},
#   ) 
#   @show r
#     return RangeData(UnitRange(r.min, r.max))
# end

# function Base.convert(
#     ::@NamedTuple{min::Float64, max::Float64},
#     r::Type{RangeData{Float64}}
# ) 
#     return (min=first(r.range), max=last(r.range))
# end

@app begin
    @private id = 1
    @in what_text = ""
    @in when_text = ""
    @in range_slider_val =  RangeData(0:20)
    
    @in assume_btn_clicked = false
    @in query_btn_clicked = false
    @in clear_btn_clicked = false
    @in is_query = false

    @out feedback_str = ""

    @in process_new_fact = false  
    @in clear_completed = false  
    @in delete_fact_id = 0  
 
    # Define private and output variables
    @out fact = Fact(0, "", "", (min=0.0, max=1.0), false, "")
    @private prob_range = (min=0.0, max=1.0)
    @out facts = Fact[]  
    @out num_facts = 0  
    @out latex_formula = raw""
    #@out latex_formula = raw"\sin^2 x"

    @onchange what_text begin
        fact = Fact(id, what_text, when_text, prob_range, is_query)
        feedback_str = fact.printable
    end 
    @onchange when_text begin
        fact = Fact(id, what_text, when_text, prob_range, is_query)
        feedback_str = fact.printable
    end

    @onbutton assume_btn_clicked  begin
        @show "assume button clicked"
        is_query = false
        fact = Fact(id, what_text, when_text, prob_range, is_query)
        feedback_str = fact.printable

        length(parse_input(what_text).vals) == 0 && return # nothing in the text field

        id += 1
        push!(facts, fact)
        @push facts
        latex_formula = raw"\begin{align} a &=b+c \\ d+e &=f \end{align}"

        num_facts = length(facts)
        @show num_facts

    end

    @onbutton query_btn_clicked  begin
        @show "assume button clicked"
        is_query = true
        fact = Fact(0, what_text, when_text, (min=0.0, max=1.0), is_query)
        feedback_str = fact.printable
    end

    @onchange delete_fact_id begin
        filter!(f -> f.id != delete_fact_id, facts)
        @push facts
        num_facts = length(facts)
    end


    @onchange range_slider_val begin
        @info " range changed" range_slider_val
        prob_range = (min=first(range_slider_val.range)/100.0, max=last(range_slider_val.range)/100.0)
        fact.prob_range = prob_range
        feedback_str = to_string(fact)
        @show prob_range
    end

    @onbutton clear_btn_clicked  begin
        id = 1
        what_text = ""
        when_text = ""
        range_slider_val =  RangeData(0:20)
        assume_btn_clicked = false
        query_btn_clicked = false
        is_query = false

        feedback_str = ""
        latex_formula = raw""

        process_new_fact = false  
        clear_completed = false  
        delete_fact_id = 0  
 
        fact = Fact(0, "", "", (min=0.0, max=1.0), false, "")
        prob_range = (min=0.0, max=1.0)
        facts = Fact[]  
        num_facts = 0

    end
end


function custom_styles()
    ["""
    <style>
        body { background-color: #f4f4f4; }
        .facts-container {background: white; padding: 5px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); margin-bottom: 20px; }
        .facts-header-container { background: white; padding: 5px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .facts-header { text-align: center; color: #007bff; padding-bottom: 2px; }
        .facts-input {background: white; padding: 5px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); margin-top: 20px;}
        .facts-text { padding: 5px; margin-bottom: 20px; margin-left: 20px; margin-right: 5px;  margin-top: 5px; }
        .facts-list { list-style-type: none; padding: 5px; }
        .facts-list-container {background: white; padding: 5px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); margin-left: 10px; margin-right: auto; }
        .facts-latex-container {background: white; padding: 5px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);margin-left: auto; margin-right: 10px;}
        .facts-item { display: flex; align-items: center; margin-bottom: 0px; padding: 5px; border-radius: 4px; background-color: white; color: black; }
        .facts-item label { margin-left: 10px; flex-grow: 1; }
        .facts-item button { padding: 2px 8px; }
        .btn-delete_fact_id { margin-left: auto; margin-right: 0; color: red; border-radius: 8px; background-color: #f8f9fa;}
        [v-cloak] { display: none; }
    </style>
    """]
end

function ui()
    # Add Bootstrap CSS
    Stipple.Layout.add_css("https://bootswatch.com/5/lumen/bootstrap.min.css")
    #Stipple.Layout.add_css("https://bootswatch.com/5/litera/bootstrap.min.css")
    # Add custom styles
    Stipple.Layout.add_css(custom_styles)

    [
        section(class="facts-header-container", v__cloak=true, [
            row([
                header(class="facts-header", [
                    h1("FactSimply: What Do Your Beliefs Imply?", style="margin-bottom: 20px; text-decoration: underline;")
                ]),        
            ])
        ]),
        
        section(class="facts-container facts-input", [
            row([
            # Input field for new facts, bound to new_facts variable
                input(class="facts-text col-3", placeholder="The joint event (e.g., 'A, !B')", @bind(:what_text)),
                cell(class="col-1", p("conditioned on", style="text-align: center; font-weight: bold;")),
                input(class="facts-text col-3", placeholder="the joint conditions (e.g., '!A, !C')", @bind(:when_text)),
                p(class="col-2", " has probability in the range: ", style="font-weight: bold;"),
            
                cell(class="col-2",   range(0:5:100, 
                            :range_slider_val;
                            snap=true,
                            labelalways=true,
                            label=true,
                            dragrange=true,
                            dense=true,
                            thumb__color="blue-13",
                            thumb__size="55px",
                            switch__label__side = true,
                            switch__marker__labels__side = true,
                            labelvalueleft=Symbol("'Min = ' + range_slider_val.min/100.0"),
                            labelvalueright=Symbol("'Max = ' + range_slider_val.max/100.0"),
                         )),

                        p("{{feedback_str}}", style="margin-left: 10px; font-weight: bold;"),
                ]),
                
                row([
                    cell(class="col-1 btn-fact",button("Assume", class="btn btn-outline-primary", (class!)="{ 'btn-focused' : filterAll }", @click(:assume_btn_clicked ))),
                    cell(class="col-1 btn-fact", button("Query", class="btn btn-outline-primary", (class!)="{ 'btn-focused' : filterActive }", @click(:query_btn_clicked ))),
                    cell(class="col-2 btn-fact", style="margin-right: 0; margin-left: auto;", button("Clear & Restart", class="btn btn-outline-primary", (class!)="{ 'btn-focused' : filterActive }", @click(:clear_btn_clicked ))),
                    ]),                   
            ]),
          
            row([
                section(class="col facts-list-container", [
                    h5("Facts", style="margin-bottom: 10px; text-decoration: underline;"),
                    ul(class="facts-list", [
                        li(class="facts-item", @recur("fact in facts"), [
                            p("{{fact.printable}}", style="margin: 0;"),
                            button("×", class="btn-delete_fact_id", outline=true,color = "red", @on("click", "delete_fact_id = fact.id"))
                        ])
                    ])
                ]),
                section(class="col facts-latex-container", [
                    h5("Implications", style="margin-bottom: 10px; text-decoration: underline;"),
                    cell(class = "facts-item", latex":latex_formula"display), 
                ]),
            ]),
        ]
    
end


@page("/", ui)
end