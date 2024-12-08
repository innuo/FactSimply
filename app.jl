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

@app begin
    @private id = 1
    @in what_text = ""
    @in when_text = ""
    @in prob_range = (min=0.0, max=1.0)
    @in assume_btn_clicked = false
    @in query_btn_clicked = false
    @in is_query = false

    @in process_new_fact = false  
    @in clear_completed = false  
    @in delete_fact_id = 0  
 
    # Define private and output variables
    @out fact = Fact(0, "", "", (min=0.0, max=1.0), false, "")
    @out facts = Fact[]  
    @out num_facts = 0  

    @onbutton assume_btn_clicked  begin
        is_query = false
        length(parse_input(what_text).vals) == 0 && return 

        fact = Fact(id, what_text, when_text, prob_range, is_query)
        id += 1
        push!(facts, fact)
        @push facts

        num_facts = length(facts)
        @show num_facts
        for f in facts
            @show f.what_text, f.when_text ,  f.prob_range , f.is_query
        end
    end

    @onbutton query_btn_clicked  begin
        is_query = true
        fact = Fact(0, what_text, when_text, (min=0.0, max=1.0), is_query)
    end

    @onchange delete_fact_id begin
        filter!(f -> f.id != delete_fact_id, facts)
        @push facts
        num_facts = length(facts)
    end

    @onchange prob_range begin
        @info "Probability range changed" prob_range
    end


    @onchange facts begin
        @info "Facts changed" facts
    end
end


function custom_styles()
    ["""
    <style>
        body { background-color: #f4f4f4; }
        .facts-container { max-width: 1200px; background: white; padding: 5px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .facts-header { text-align: center; color: #007bff; padding-bottom: 2px; }
        .facts-input { max-width: 1200px;  background: white; margin-bottom: 20px; margin-left: 5px; margin-right: 5px;  margin-top: 5px}
        .facts-text { margin-bottom: 20px; margin-left: 20px; margin-right: 5px;  margin-top: 5px; border-radius: 2px;}
        .facts-list { list-style-type: none; padding: 0; }
        .facts-item { display: flex; align-items: center; margin-bottom: 5px; padding: 5px; border-radius: 4px; background-color: #f8f9fa; }
        .facts-item label { margin-left: 10px; flex-grow: 1; }
        .facts-item button { padding: 2px 8px; }
        .facts-filters { margin-bottom: 20px; }
        .facts-filters .btn { margin-right: 5px; }
        .btn-delete_fact_id { margin-left: 10px; color: red; border-radius: 4px; background-color: #f8f9fa;}
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
        section(class="facts-container", v__cloak=true, [
            row([
                header(class="facts-header", [
                    h1("FactSimply: What Do Your Beliefs Imply?", style="margin-bottom: 50px; text-decoration: underline;")
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
            
                cell(class="col-2",   range(0.0:0.1:1.0, 
                            :prob_range;
                            snap=true,
                            labelalways=true,
                            label=true,
                            dragrange=true,
                            dense=true,
                            thumb__color="blue-13",
                            thumb__size="35px",
                            switch__label__side = true,
                            switch__marker__labels__side = true,
                            labelvalueleft=Symbol("'Min = ' + prob_range.min"),
                            labelvalueright=Symbol("'Max = ' + prob_range.max"),
                         )),

                        p("{{fact.printable}}", style="margin-left: 10px; font-weight: bold;"),

 
                ]),
                
                
                row([
                    cell(class="col-1 btn-fact",button("Assume", class="btn btn-outline-primary", (class!)="{ 'btn-focused' : filterAll }", @click(:assume_btn_clicked ))),
                    cell(class="col-1 btn-fact", button("Query", class="btn btn-outline-primary", (class!)="{ 'btn-focused' : filterActive }", @click(:query_btn_clicked ))),
                    ]),                   
            ]),
          
            section(class="facts-list", [
                ul(class="facts-list", [
                    li(class="facts-item", @recur("fact in facts"), [
                        p("{{fact.printable}}", style="margin: 0;"),
                        button("×", class="btn-delete_fact_id", outline=true,color = "red", @on("click", "delete_fact_id = fact.id"))
                    ])
                ])
            ]),
        ]
    
end


@page("/", ui)
end