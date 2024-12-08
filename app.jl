module App
using FactSimply
using GenieFramework


using StippleLatex
using StippleUI


@genietools


mutable struct Fact{P}
    what_text::String
    when_text::String
    prob_range::P
    is_query::Bool
end


@app begin
    @in what_text = ""
    @in when_text = ""
    @in prob_range = (min=0.0, max=1.0)
    @in prob_range_changed = false
    @in type = ""

    @in process_new_fact = false  
    @in clear_completed = false  
    @in delete_fact = 0  
 
    # Define private and output variables
    @private facts = Fact[]  
    @out num_facts = 0  

    @onchange type  begin
        @info "Type changed" type
        #@info prob_range
    end

    @onchange prob_range begin
        @info "Probability range changed" prob_range
    end

    @onchange prob_range_changed begin
        @info "Probability range changed" prob_range
    end


    @onchange facts begin
        @info "Facts changed" todos
    end
end

# function ui()

#     col([
#         row([
#             cell(    
#                 # Header cell with app description
#                 class="col-12", 
#                 h1("FactSimply: What Do Your Beliefs Imply?", style="margin-bottom: 50px; text-decoration: underline;"),
#             )
#         ]),

#         row([  
#             textfield(class = "col-3", "What", :input, hint = "E.g., A, !B"),
#             Stipple.Html.div(class = "col-1", col([
#                 p("|", style="font-weight: bold;"),
#                 p("|", style="font-weight: bold;")
#             ])),
#             textfield(class = "col-3", "When", :input, hint = "E.g., !C, !D"),
#             Stipple.Html.div(class = "q-pa-md", 
#                 col([
#                     p("Probability", style="font-weight: bold;"),
#                     range(0.0:0.1:1.0, 
#                         :prob_range;
#                         snap=true,
#                         labelalways=true,
#                         label=true,
#                         lazy=true,
#                         dragrange=true,
#                     )])
#                 )
#         ]),
#         row([  
#             col([
#                 p(""),
#                 button("Assume", :constraint, class = "btn btn-primary", @on("click", "process = true")),
#                 p(""),
#                 button("Query", :query, class = "btn btn-primary", @on("click", "process = true")),
#             ])
#         ])

#     ]) #col

# end

function custom_styles()
    ["""
    <style>
        body { background-color: #f4f4f4; }
        .facts-container { max-width: 1200px; margin: auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .facts-header { text-align: center; color: #007bff; padding-bottom: 20px; }
        .facts-input { margin-bottom: 20px; margin-left: 5px; margin-right: 5px; }
        .facts-list { list-style-type: none; padding: 0; }
        .facts-item { display: flex; align-items: center; margin-bottom: 10px; padding: 10px; border-radius: 4px; background-color: #f8f9fa; }
        .facts-item label { margin-left: 10px; flex-grow: 1; }
        .facts-item button { padding: 2px 8px; }
        .facts-filters { margin-bottom: 20px; }
        .facts-filters .btn { margin-right: 5px; }
        .facts-footer { display: flex; justify-content: space-between; align-items: center; margin-top: 20px; }
        .btn-focused { background-color: #007bff; color: white; }
        [v-cloak] { display: none; }
    </style>
    """]
end

function ui()
    # Add Bootstrap CSS
    #Stipple.Layout.add_css("https://bootswatch.com/5/lumen/bootstrap.min.css")
    Stipple.Layout.add_css("https://bootswatch.com/5/litera/bootstrap.min.css")
    # Add custom styles
    Stipple.Layout.add_css(custom_styles)

    [
        row(
            section(class="facts-container", v__cloak=true, [
            header(class="facts-header", [
                # h1("FactSimply: What Do Your Beliefs Imply?", style="margin-bottom: 50px; text-decoration: underline;")
                h1("TITLE", style="margin-bottom: 50px; text-decoration: underline;")
                ]),        
        ])),
        
        section(class="facts-input", [
            row([
            # Input field for new facts, bound to new_facts variable
                input(class="facts-input col-2", placeholder="The joint event (e.g., 'A, !B')", @bind(:what_text)),
                cell(class="col-1", p("conditioned on", style="text-align: center; font-weight: bold;")),
                input(class="facts-input col-2", placeholder="the joint conditions (e.g., '!A, !C')", @bind(:when_text)),
                p(class="col-2", " has probability in the range: ", style="font-weight: bold;"),
            
                cell(class="col-3",   range(0.0:0.1:1.0, 
                            :prob_range;
                            snap=true,
                            labelalways=true,
                            label=true,
                            dragrange=true,
                            dense=true,
                            thumb__color="purple",
                            thumb__size="35px",
                            labelvalueleft=Symbol("'Min = ' + prob_range.min"),
                            labelvalueright=Symbol("'Max = ' + prob_range.max"),
                            @on("change", "prob_range_changed = true")
                        )),
                        p("P({{what_text}} | {{when_text}}) ∈ [{{prob_range.min}}, {{prob_range.max}}]", style="font-weight: bold; margin-left: 10px;"),
                ]),
                
                
                row([
                    cell(class="col-1",button("Assume", class="btn btn-outline-primary", (class!)="{ 'btn-focused' : filterAll }", @on("click", "type = 'assume'"))),
                    cell(class="col-1", button("Query", class="btn btn-outline-primary", (class!)="{ 'btn-focused' : filterActive }", @on("click", "type = 'query'"))),
                    ]),                   
            ]),

        
            
            section(class="facts-list", [
                ul(class="facts-list", [
                    li(class="facts-item", @recur("facts in filtered_facts"), (key!)="facts.id", [
                        # Checkbox for toggling facts status
                        input(type="checkbox", class="form-check-input", @on("change", "toggle_facts = facts.id"), (checked!)="facts.completed", (id!)="'facts-' + facts.id"),
                        # facts text
                        label(class="form-check-label", "{{ facts.text }}", (for!)="'facts-' + facts.id"),
                        # Delete button
                        button("×", class="btn btn-sm btn-outline-danger", @on("click", "delete_facts = facts.id"))
                    ])
                ])
            ]),

            footer(class="facts-footer", [
                # Display count of active factss
                span("{{ active_facts }} facts left", class="text-muted")
            ])
        ]
    
end


@page("/", ui)
end