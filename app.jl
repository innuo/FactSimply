module App
using FactSimply
using GenieFramework


using StippleLatex
using StippleUI

@genietools

@app begin
    @private id = 1
    @in what_text = ""
    @in when_text = ""
    @in pmin = 0.0
    @in pmax = 1.0
    
    @in assume_btn_clicked = false
    @in query_btn_clicked = false
    @in clear_btn_clicked = false
    @in is_query = false
    @out query_error = false

    @in process_new_fact = false  
    @in clear_completed = false  
    @in delete_fact_id = 0  
 
    # Define private and output variables
    @out fact = Fact(0, "", "", (min=0.0, max=1.0), false, "")
    @out feedback_str = ""
    
    @out prob_range = (min=0.0, max=1.0)
    @out facts = Fact[]  
    @out num_facts = 0  
    @out maxent_answer_str = ""
    @out bounds_answer_str = ""

    @out show_help=false
    
    @onchange what_text begin
        fact = Fact(id, what_text, when_text, prob_range, is_query)
        feedback_str = fact.printable
    end 
    @onchange when_text begin
        fact = Fact(id, what_text, when_text, prob_range, is_query)
        feedback_str = fact.printable
    end
    @onchange prob_range begin
        fact = Fact(id, what_text, when_text, prob_range, is_query)
        feedback_str = fact.printable
    end

    @onbutton assume_btn_clicked  begin
        @show "assume button clicked"
        is_query = false
        query_error = false
        fact = Fact(id, what_text, when_text, prob_range, is_query)

        feedback_str = fact.printable

        length(parse_input(what_text).vals) == 0 && return # nothing in the text field

        id += 1
        push!(facts, deepcopy(fact))

        @push facts

        num_facts = length(facts)
        @show num_facts
        
    end

    @onbutton query_btn_clicked  begin
        @info "query button clicked"
        is_query = true

        pmin = 0.0
        pmax = 1.0
        prob_range = (min=0.0, max=1.0)

        query = Fact(0, what_text, when_text, prob_range, is_query)
        feedback_str = query.printable

        (;sample_space, constraints, query_expression, query_vars) = parse_problem(facts, query)

        @show sample_space.vars, length(sample_space.vars)
        (length(sample_space.vars) == 0) && return

        @show query_vars
        if !all(query_vars .∈ Ref(sample_space.vars)) 
             query_error = true
             @show "query error"
             return
        else
            query_error = false
        end

        p = FactSimply.maxent(sample_space, constraints, query_expression)
        if !isnothing(p)
            p = round(clamp(p, 0.0, 1.0), digits=5)
            maxent_answer_str = to_string(Fact(0, what_text, when_text, (min=p, max=p), false))
        else
            maxent_answer_str = "Maximum Entropy solver returned status other than OPTIMAL. Your assumptions are likely inconsistent."
        end

        p = FactSimply.compute_bounds(sample_space, constraints, query_expression)

        if !isnothing(p)
            p = round.(clamp.(p, 0.0, 1.0), digits=5)
            bounds_answer_str = to_string(Fact(0, what_text, when_text, (min=p[1], max=p[2]), false); eps=1e-6)
        else
            bounds_answer_str = "Bounds solver returned status other than OPTIMAL. Your assumptions are likely inconsistent."
        end

    end

    @onchange delete_fact_id begin
        @show [f.id for f in facts]
        filter!(f -> f.id != delete_fact_id, facts)
        @push facts
        num_facts = length(facts)
        @show [f.id for f in facts]
        @show num_facts
        delete_fact_id[!] = 0 
        maxent_answer_str = ""
        bounds_answer_str = ""
    end

    @onchange pmin begin
        pmin_clamped = clamp(pmin, 0.0, pmax)
        prob_range = (min=pmin_clamped, max=pmax)
    end

    @onchange pmax begin
        pmax_clamped = clamp(pmax, pmin, 1.0)
        prob_range = (min=pmin, max=pmax_clamped)
    end

    @onbutton show_help begin end

    @onbutton clear_btn_clicked  begin
        what_text = ""
        when_text = ""
        pmin = 0.0
        pmax = 1.0
        assume_btn_clicked = false
        query_btn_clicked = false
        is_query = false
        query_error = false
        show_help=false

        feedback_str = ""
        latex_formula = raw""
        maxent_answer_str = ""
        bounds_answer_str = ""

        process_new_fact = false  
        clear_completed = false  
        delete_fact_id = 0  
 
        fact = Fact(0, "", "", (min=0.0, max=1.0), false, "")
        prob_range = (min=0.0, max=1.0)
        facts = Fact[]  
        num_facts = 0
        id = 1
    end
end


function custom_styles()
    ["""
    <style>
        body { background-color: #f4f4f4; }
        .facts-container {background: white; padding: 5px; border-radius: 8px; margin-bottom: 20px; }
        .facts-header-container { background: white; padding: 5px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .facts-header { text-align: center; color: #007bff; padding-bottom: 2px; }
        .facts-input {background: white; padding: 5px; border-radius: 8px;  margin-top: 20px;}
        .facts-text { padding: 5px; margin-bottom: 20px; margin-left: 20px; margin-right: 5px;  margin-top: 5px; }
        .facts-list { list-style-type: none; padding: 5px; }
        .facts-list-container {background: white; padding: 5px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); margin-left: 10px; margin-right: auto; }
        .facts-latex-container {background: white; padding: 5px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);margin-left: auto; margin-right: 10px;}
        .facts-item { display: flex; align-items: center; margin-bottom: 0px; padding: 5px; border-radius: 4px; background-color: white; color: black; }
        .facts-item label { margin-left: 10px; flex-grow: 1; }
        .facts-item button { padding: 2px 8px; }
        .btn-delete_fact_id { margin-left: auto; margin-right: 0; color: red; border-radius: 8px; background-color: #f8f9fa;}
        .fact_help { color: var(--bs-primary); } 
        .fact_help:hover { color: #3596fa; }'
        .help-card {width: 100%; max-width: 350px}
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
        dialog(:query_error, auto__close=true, no__shake=false, noesc=false,
        [
          card([
            card_section(class="text-h6", "Invalid Query", style="margin-bottom: 5px; text-decoration: underline;"),
            card_section(class="q-pt-none", "Query contains variables not found in assumptions")
          ])
        ]),

        dialog(:show_help, position="top", persistent=false, auto__close=false, no__shake=true, noesc=false,
        [
            card(class = "help-card", bordered = true, flat=true, [
                card_section(class="text-h5", "What Is This Tool For?", style="text-align: center;  color: var(--bs-primary); margin-bottom: 0px; margin-top=0px"),
                separator(),
                card_section(helpmsg())
            ])
        ]),

        section(class="facts-header-container", v__cloak=false, [
            row([
                header(class="facts-header", [
                    h1("<a class='fact_help' v-on:click='show_help=true'>FactSimply: What Do Your Beliefs Imply?</a>", @click("show_help=true"), style="margin-bottom: 20px; text-decoration: underline;"),
                ]),        
            ]),

        ]),
        
        section(class="col-12 facts-container facts-input", [
            row([
                cell(class="col-3", 
                    textfield("", :what_text, placeholder="The joint event (e.g., 'A, !B')"), style="padding-left:20px"),
                cell(class="col-1",  style="margin-top: 20px; margin-left: 0px; max-width: 130px", span("conditioned on", style="text-align: center; font-weight: bold;")),
                cell(class="col-3",   
                    textfield("", :when_text, placeholder="The joint event (e.g., 'A, !B')"), style="padding-left:20px"),
                cell(class="col-2",  style="margin-top: 20px; max-width: 200px", span("has probability in the range: ", style="font-weight: bold;")),
                
                cell(class="col-2",  style="margin-top: 0px; max-width: 130px;margin-right:2px; margin-left:5px; padding-right:2px", 
                    numberfield("", :pmin,
                    style="padding-left:0px; width=130px",
                    borderless = true, dense=true,  
                    hint = "Min", noerroricon=true,
                    min="0.0", step = "0.1", max= Symbol("prob_range.max"), 
                    rules= "[ val => parseFloat(val) >= 0.0 && parseFloat(val) <= 1.0 || 'Invalid probability' ]",
                    placeholder="{{prob_range.min}}")),

                cell(class="col-2",  style="margin-top: 0px; max-width: 130px; padding-left:2px; margin-left:2px", 
                    numberfield("", :pmax,
                    style="padding-left:0px; width=130px",
                    borderless = true, dense=true,  
                    hint = "Max", noerroricon=true,
                    min=Symbol("prob_range.min"), step = "0.1", max= "1.0", 
                    rules= "[ val => parseFloat(val) >= 0.0 && parseFloat(val) <= 1.0 || 'Invalid probability' ]",
                    placeholder="{{prob_range.max}}")),

                p("{{feedback_str}}", style="margin-left: 10px; font-weight: bold;"),
                        
                ]),
                
                row([
                    cell(class="col-1", style=" margin-right: 0px;",button("Assume", class="btn btn-primary", @click(:assume_btn_clicked))),
                    cell(class="col-1",  style=" margin-right: 0px;", button("Query", class="btn btn-primary", @click(:query_btn_clicked))),
                    cell(class="col-2", style="margin-right: 0; margin-left: auto;", button("Clear & Restart", class="btn btn-primary", @click(:clear_btn_clicked))),
                    ]),                   
            ]),
          
            row([
                section(class="col facts-list-container", [
                    h4("Facts", style="margin-bottom: 10px; text-decoration: underline; color: var(--bs-primary);"),
                    ul(class="facts-list", [
                        li(class="facts-item", @recur("fact in facts"), [
                            p("{{fact.printable}}", style="margin: 0;"),
                            button("×", class="btn-delete_fact_id", outline=true, color = "red", @on("click", "delete_fact_id = fact.id"))
                        ])
                    ])
                ]),
                section(class="col facts-latex-container", [
                    h4("Implications", style="margin-bottom: 10px; text-decoration: underline; color: var(--bs-primary);"),
                    #cell(class = "facts-item", latex":latex_formula"display), 
                    h6("Bounds on the probability", style="margin-top: 20px; font-weight: bold;"),
                    cell(class = "facts-item", p("{{bounds_answer_str}}")), 
                    h6("The maximum entropy probability", style="margin-top: 10px; font-weight: bold;"),
                    cell(class = "facts-item", p("{{maxent_answer_str}}")), 
                    ]),
            ]),
            row([footer("", class = "bg-blue-1")])
        ]
end

function layout(; title::String = "FactSimply",
    meta::D = Dict(),
    head_content::Union{AbstractString, Vector} = "",
    core_theme::Bool = true) where {D <:AbstractDict}
    tags = Genie.Renderers.Html.for_each(x -> """<meta name="$(string(x.first))" content="$(string(x.second))">\n""", meta)
    """
    <!DOCTYPE html>
    <html>
    <head>
    <meta charset="utf-8">
    $tags
    <% Stipple.sesstoken() %>
    <title>$title</title>
    <% if isfile(joinpath(Genie.config.server_document_root, "css", "genieapp.css")) %>
    <link rel='stylesheet' href='$(Genie.Configuration.basepath())/css/genieapp.css'>
    <% else %>
    <% end %>
    <style>
    ._genie_logo {
    background:url('https://genieframework.com/logos/genie/logo-simple-with-padding.svg') no-repeat;
    background-size:40px;
    padding-top:22px;
    padding-right:10px;
    color:transparent !important;
    font-size:9pt;
    }
    ._genie .row .col-12 { width:50%; margin:auto; }
    </style>
    $(join(head_content, "\n    "))
    </head>
    <body>
    <div class='container'>
    <div class='row'>
    <div class='col-12'>
    <% Stipple.page(model, partial = true, v__cloak = true, [Stipple.Genie.Renderer.Html.@yield], Stipple.@if(:isready); core_theme = $core_theme) %>
    </div>
    </div>
    </div>
    <% if isfile(joinpath(Genie.config.server_document_root, "js", "genieapp.js")) %>
    <script src='$(Stipple.Genie.Configuration.basepath())/js/genieapp.js'></script>
    <% else %>
    <% end %>
    <% if isfile(joinpath(Genie.config.server_document_root, "css", "theme.css")) %>
    <link rel='stylesheet' href='$(Genie.Configuration.basepath())/css/theme.css'>
    <% else %>
    <% end %>
    <% if isfile(joinpath(Genie.config.server_document_root, "css", "autogenerated.css")) %>
    <link rel='stylesheet' href='$(Genie.Configuration.basepath())/css/autogenerated.css'>
    <% else %>
    <% end %>
    </body>
    </html>
    """
end


function helpmsg()
   [
    p("A great mind once asserted that a foolish consistency is the hobgoblin of little minds. 
    He probably followed that right away by declaring its exact opposite, 
    so we can safely ignore him."),
    
    p("Other, more medium sized minds are troubled sometimes by the possibility of an inconsistency 
    in their beliefs, and wonder what else those beliefs might imply. 
    This tool in some small measure attempts to allay those worries."), 

     h6("Probabilistic Statements and Their Implications", style="margin-bottom: 10px;"),
        p(latex"The basic function of this tool is to enable positing the probability of joint specifications 
        of certain variables conditioned on the joint specification of other variables, e.g.,  \(P(A=true | C=false, B=true) = 0.4\), 
        and querying the probability of other such predicates, e.g., \(P(C=true | A=true) = ?\). Any number of such probabilistic
        assumptions can be made before a query. Moreover, instead of an exact equality, the probability of
        an assumption can be specified to lie in a range of values."auto),

        p("The query is answered in two different ways. The first asks \"of all probability distributions that 
        agree with the assumptions specified, what is the smallest and the largest probability that can be assigned
        to the query?\", and the second asks \"of all the probability distributions that are consistent with the assumptions, what probability does
        the 'flattest' (or the most uniform) one assign to the query?\" -- the so-called <a href='https://en.wikipedia.org/wiki/Principle_of_maximum_entropy' target='_blank' rel='noopener noreferrer'> <em> Maximum Entropy estimate </em></a>."),
   

    h6("How To Use", style="margin-bottom: 10px;"),
        p("For each assumption or query, the joint and conditional specification of the event 
        are entered into the two text boxes resp., and the probability range is specified. (Setting
        the min and max probabilities close enough will turn the assumption into an equality.)
        The assume button adds the probabilistic statement to the set of facts."),

        p("The joint event is specified by typing in variables separated by commas. A '!' before a variable
        indicates that it is set to false. For example '!x, !Y, z' would denote 'X=false, Y=false, Z=true'"),

        p("The first query is usually slower and might take a few seconds to answer. The ones after that should 
        be very quick."),


    h6("Example Uses", style="margin-bottom: 10px;"),
        p("<em> Simple Bayesian Inversion: </em> The simplest use one can put this tool to is to answer questions
        of the WebMD type: \"If a rare disease expresses a symptom with a certain probability, then what is
        probability that I have the disease given that I am showing the symptom.\" 
        For instance, this <a href='https://en.wikipedia.org/wiki/Bayes%27_theorem#:~:text=45/92%20%E2%89%88%2049%25-,Cancer%20rate,-%5Bedit%5D' target='_blank' rel='noopener noreferrer'> 
        cancer example</a> can be coded by making the assumptions 
        P(C) = 0.00001, P(S|C) = 1.0, P(S| !C) = 0.0001, and querying P(C|S)."),

        p("More complicated sets of assumptions are allowed, such as if the disease also had a test with known false
        positive and false negative rate, and it came back negative for you, but your family history
        triples your risk over the general population etc. etc."),

        p("<a href='https://en.wikipedia.org/wiki/Fr%C3%A9chet_inequalities' target='_blank' rel='noopener noreferrer'> 
         <em> Fréchet Inequalities</em> </a>: If 51% of U.S. households have a dog and 35% have a cat, what
         is the minimum percentage of households that own neither a cat nor a dog; and what
         is your best guess at that percentage? (You'd specify: P(D) = 0.51, P(C) = 0.36, 
         P(!D,!C)= ?) This, and thornier questions of this sort are all grist for this mill.
         " ),

        p("<em>Prediction Market Arbitrage: </em> If you prefer to be crassly commercial and
        insist on enquiring about the cash value of the tool, I'll simply point out that you can use it
        to look for arbitrage opportunities in conditional betting markets like Metaculus."),
    
    h6("What's Left?", style="margin-bottom: 10px;"),

        p("Because of some arcane technical reasons like convexity of the optimization problems, and 
        linearizability of the constraints, some obvious varieties of assumptions like statistical independence, 
        or constraints of the type P(A|B) > P(C|B) are not currently supported. If you have a good idea 
        on how to handle them, please file an issue, or better yet, a merge request at https://github.com/innuo/FactSimply."),
   ]
end

@page("/", ui, layout=layout(); debounce = 200)
end