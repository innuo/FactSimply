### App 
To see the app in action visit http://nullities.org/factsimply/

### Probabilistic Statements and Their Implications:
The basic function of this tool is to enable positing the probability of joint specifications 
        of certain variables conditioned on the joint specification of other variables, e.g.,  \(P(A=true | C=false, B=true) = 0.4\), 
        and querying the probability of other such predicates, e.g., \(P(C=true | A=true) = ?\). Any number of such probabilistic
        assumptions can be made before a query. Moreover, instead of an exact equality, the probability of
        an assumption can be specified to lie in a range of values.

The query is answered in two different ways. The first asks "of all probability distributions that agree with the assumptions 
specified, what is the smallest and the largest probability that can be assigned to the query?", and the second asks 
"of all the probability distributions that are consistent with the assumptions, what probability does the 'flattest' 
(or the most uniform) one assign to the query?" -- the so-called Maximum Entropy estimate .

How To Use
For each assumption or query, the joint and conditional specification of the event are entered into the two text boxes resp., 
and the probability range is specified. (Setting the min and max probabilities close enough will turn the assumption into an equality.) 
The assume button adds the probabilistic statement to the set of facts.

The joint event is specified by typing in variables separated by commas. A '!' before a variable indicates that it 
is set to false. For example '!x, !Y, z' would denote 'X=false, Y=false, Z=true'

### Example Uses
Simple Bayesian Inversion: The simplest use one can put this tool to is to answer questions of the WebMD type: 
"If a rare disease expresses a symptom with a certain probability, then what is probability that I have the disease given that 
I am showing the symptom." For instance, this cancer example can be coded by making the 
assumptions P(C) = 0.00001, P(S|C) = 1.0, P(S| !C) = 0.0001, and querying P(C|S).

More complicated sets of assumptions are allowed, such as if the disease also had a test with known false positive and 
false negative rate, and it came back negative for you, but your family history triples your risk over the general population etc. etc.

Fréchet Inequalities: If 51% of U.S. households have a dog and 35% have a cat, what is the minimum percentage of 
households that own neither a cat nor a dog; and what is your best guess at that percentage? 
(You'd specify: P(D) = 0.51, P(C) = 0.36, P(!D,!C)= ?) This, and thornier questions of this sort are all grist for this mill.

Prediction Market Arbitrage: If you prefer to be crassly commercial and insist on enquiring about the cash value of the tool,
I'll simply point out that you can use it to look for arbitrage opportunities in conditional betting markets like Metaculus.

### What's Left?
Because of some arcane technical reasons like convexity of the optimization problems, and linearizability of the constraints, 
some obvious varieties of assumptions like statistical independence, or constraints of the type P(A|B) > P(C|B) are not currently 
supported. If you have a good idea on how to handle them, please file an issue, or better yet, a merge request here. 
