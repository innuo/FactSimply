module App
using FactSimply
using GenieFramework
using StippleLatex


@genietools

@app begin
    @in what_text = ""
    @in when_text = ""
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
        .facts-input { margin-bottom: 20px; }
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
    Stipple.Layout.add_css("https://bootswatch.com/5/lumen/bootstrap.min.css")
    # Add custom styles
    Stipple.Layout.add_css(custom_styles)

    [
        section(class="facts-container", v__cloak=true, [
            header(class="facts-header", [
                h1("FactSimply: What Do Your Beliefs Imply?", style="margin-bottom: 50px; text-decoration: underline;")
            ]),
            cell(
            section(class="facts-input", [

                row([
                # Input field for new facts, bound to new_facts variable
                input(class="form-control col-3", placeholder="The joint event (e.g., 'A, !B')", @bind(:new_facts), @on("keyup.enter", "process_new_facts = !process_new_facts")),
                cell(class="col-1", p("Given", style="text-align: center;")),
                input(class="form-control col-3", placeholder="What joint conditions (e.g., '!A, !C')", @bind(:new_facts), @on("keyup.enter", "process_new_facts = !process_new_facts")),
                cell(class="col-1", p("")),
                Html.div(class="col-3",
                    range(0.0:0.1:1.0, 
                        :prob_range;
                        snap=true,
                        labelalways=true,
                        label=true,
                        lazy=true,
                        dragrange=true,
                    ))
                ])
            ]),
            ),
            section(class="facts-button", [
                # Filter buttons
                button("Assume", class="btn btn-outline-primary", (class!)="{ 'btn-focused' : filterAll }", @on("click", "filter = 'assume'")),
                button("Query", class="btn btn-outline-primary", (class!)="{ 'btn-focused' : filterActive }", @on("click", "filter = 'query'")),
            ]),
            section(class="facts-list", [
                ul(class="facts-list", [
                    # List of factss, using @recur for iteration
                    li(class="facts-item", @recur("facts in filtered_factss"), (key!)="facts.id", [
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
        ])
    ]
end


@page("/", ui)
end