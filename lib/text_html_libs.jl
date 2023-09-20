
const FAMDIR = "budget" # old budget images; alternative is 'keiko' for VE images

const ARROWS_3 = Dict([
    "nonsig"          => "&#x25CF;",
    "positive_strong" => "&#x21c8;",
    "positive_med"    => "&#x2191;",
    "positive_weak"   => "&#x21e1;",
    "negative_strong" => "&#x21ca;",
    "negative_med"    => "&#x2193;",
    "negative_weak"   => "&#x21e3;" ])


const ARROWS_1 = Dict([
    "nonsig"          => "",
    "positive_strong" => "<i class='bi bi-arrow-up-circle-fill'></i>",
    "positive_med"    => "<i class='bi bi-arrow-up-circle'></i>",
    "positive_weak"   => "<i class='bi bi-arrow-up'></i>",
    "negative_strong" => "<i class='bi bi-arrow-down-circle-fill'></i>",
    "negative_med"    => "<i class='bi bi-arrow-down-circle'></i>",
    "negative_weak"   => "<i class='bi bi-arrow-down'></i>" ])



function format_and_class( change :: Real ) :: Tuple
    gnum = format( abs(change), commas=true, precision=2 )
    glclass = "";
    glstr = ""
    if change > 20.0
        glstr = "positive_strong"
        glclass = "text-success"
    elseif change > 10.0
        glstr = "positive_med"
        glclass = "text-success"
    elseif change > 0.01
        glstr = "positive_weak"
        glclass = "text-success"
    elseif change < -20.0
        glstr = "negative_strong"
        glclass = "text-danger"
    elseif change < -10
        glstr = "negative_med"
        glclass = "text-danger"
    elseif change < -0.01
        glstr = "negative_weak"
        glclass = "text-danger"
    else
        glstr = "nonsig"
        glclass = "text-body"
        gnum = "";
    end
    ( gnum, glclass, glstr )
end

"""
FIXME send parameters in here for Wealth Tax options
funding - one of the strings from the 'funding' conjoint ops - Tax on wealth, etc.
rate - value of VAT, etc. needed to equalise 
amount_needed - FIXME better name - amount needed to equalise.
"""
function format_optimising_change( funding :: AbstractString, rate :: Number, amount_needed :: Number )::String
    s = ""
    amv = format(abs(amount_needed/1_000_000.0),commas=true, precision=0)
    colour = "alert-danger"
    amstr = ""
    if amount_needed > 0
        amstr = "This raises approx <strong>£$amv</strong> mn p.a."
    else
        colour = "alert-success"
        amstr = "This is a cut of approx <strong>£$amv</strong> mn p.a."
    end
    if funding == "Tax on wealth"
        s = "a Wealth Tax of <strong>" * format(rate,precision=2)*"%</strong> of total non-pension household wealth, payable over 5 years, with the first £500,000 wealth exempt. $amstr"
    elseif funding == "Corporation tax increase" 
        if amount_needed > 0
            s = "extra Corporation Tax of <strong>£$amv</strong>mn p.a. "
        else 
            s = "Corporation Tax reductions of <strong>£$amv</strong>mn p.a. "
        end
        s *= ""
    elseif funding == "VAT increase"
        s = "a Standard VAT Rate of <strong>"*format(rate,precision=2)*"%</strong>, with the same increase in the Reduced Rate. $amstr"
    end
    if s !== ""
       s = "<div class='alert $colour'>For revenue neutrality, your changes require  $s</div>"
    end
    s
end

function thing_table(
    names::Vector{String}, 
    v1::Vector, 
    v2::Vector, 
    up_is_good::Vector{Int} )

    table = "<table class='table'>"
    table *= "<thead>
        <tr>
            <th></th><th>Baseline Policy</th><th>Your Policy</th><th>Change</th>
        </tr>
        </thead>"

    diff = v2 - v1
    n = size(names)[1]
    rows = []
    for i in 1:n
        colour = "text-primary"
        if (up_is_good[i] !== 0) && (! (diff[i] ≈ 0))
            if diff[i] > 0
                colour = up_is_good[i] == 1 ? "text-success" : "text-danger"
             else
                colour = up_is_good[i] == 1 ? "text-danger" : "text-success"
            end # neg diff   
        end # non zero diff
        ds = diff[i] ≈ 0 ? "-" : fp(diff[i])
        row = "<tr><td>$(names[i])</td><td style='text-align:right'>$(f2(v1[i]))</td><td style='text-align:right'>$(f2(v2[i]))</td><td class='text-right $colour'>$ds</td></tr>"
        table *= row
    end
    table *= "</tbody></table>"
    return table
end

function costs_frame_to_table(
    df :: DataFrame )
    caption = "Values in £m pa; numbers of individuals paying or receiving."
    table = "<table class='table table-sm'>"
    table *= "<thead>
        <tr>
            <th></th><th colspan='2'>Baseline Policy</th><th colspan='2'>Your Policy</th><th colspan=2>Change</th>            
        </tr>
        <tr>
            <th></th><th style='text-align:right'>Costs £m</th><th style='text-align:right'>(Counts)</th>
            <th style='text-align:right'>Costs £m</th><th style='text-align:right'>(Counts)</th>
            <th style='text-align:right'>Costs £m</th><th style='text-align:right'>(Counts)</th>
        </tr>
        </thead>"
    table *= "<caption>$caption</caption>"
    i = 0
    for r in eachrow( df )
        i += 1
        # fixme to a function
        dv = r.dval ≈ 0 ? "-" : format(r.dval, commas=true, precision=1 )
        if dv != "-" && r.dval > 0
            dv = "+$(dv)"
        end 
        dc = r.dcount ≈ 0 ? "-" : format(r.dcount, commas=true, precision=0 )
        if dc != "-" && r.dcount > 0
            dc = "+$(dc)"
        end 
        v1 = format(r.value1, commas=true, precision=1)
        c1 = format(r.count1, commas=true, precision=0)
        v2 = format(r.value2, commas=true, precision=1)
        c2 = format(r.count2, commas=true, precision=0)
        row = "<tr><th class='text-left'>$(r.Item)</th>
                  <td style='text-align:right'>$v1</td>
                  <td style='text-align:right'>($c1)</td>
                  <td style='text-align:right'>$v2</td>
                  <td style='text-align:right'>($c2)</td>
                  <td style='text-align:right'>$dv</td>
                  <td style='text-align:right'>($dc)</td>
                </tr>"
        table *= row
    end
    table *= "</tbody></table>"
    return table
end

function format_diff(; before :: Number, after :: Number, up_is_good = 0, prec=2,commas=true ) :: NamedTuple
    change = round(after - before, digits=6)
    colour = ""
    if (up_is_good !== 0) && (! (change ≈ 0))
        if change > 0
            colour = up_is_good == 1 ? "text-success" : "text-danger"
        else
            colour = up_is_good == 1 ? "text-danger" : "text-success"
        end # neg diff   
    end # non zero diff
    ds = change ≈ 0 ? "-" : format(change, commas=true, precision=prec )
    if ds != "-" && change > 0
        ds = "+$(ds)"
    end 
    before_s = format(before, commas=commas, precision=prec)
    after_s = format(after, commas=commas, precision=prec)    
    (; colour, ds, before_s, after_s )
end

function frame_to_table(
    df :: DataFrame;
    up_is_good :: Vector{Int},
    prec :: Int = 2, 
    caption :: String = "",
    totals_col :: Int = -1 )
    table = "<table class='table table-sm'>"
    table *= "<thead>
        <tr>
            <th></th><th style='text-align:right'>Baseline Policy</th><th style='text-align:right'>Your Policy</th><th style='text-align:right'>Change</th>            
        </tr>
        </thead>"
    table *= "<caption>$caption</caption>"
    i = 0
    for r in eachrow( df )
        i += 1
        fmtd = format_diff( before=r.Before, after=r.After, up_is_good=up_is_good[i], prec=prec )
        row_style = i == totals_col ? "class='text-bold table-info' " : ""
        row = "<tr $row_style><th class='text-left'>$(r.Item)</th>
                  <td style='text-align:right'>$(fmtd.before_s)</td>
                  <td style='text-align:right'>$(fmtd.after_s)</td>
                  <td style='text-align:right' class='$(fmtd.colour)'>$(fmtd.ds)</td>
                </tr>"
        table *= row
    end
    table *= "</tbody></table>"
    return table
end


"""
FIXME just break UK/Scot in 2 here
"""
function costs_table( incs1 :: DataFrame, incs2 :: DataFrame; scotland = true, other_tax_name="" )
    df = DataFrame()
    if scotland
        df = costs_dataframe( incs1, incs2 )
    else
        df = uk_costs_dataframe( incs1, incs2, other_tax_name )
    end
    return frame_to_table( df, prec=0, up_is_good=COST_UP_GOOD, 
        caption="Tax Liabilities and Benefit Entitlements, £m pa, 2023/24" )
end


function overall_cost( incs1:: DataFrame, incs2:: DataFrame ) :: String
    n1 = incs1[1,:net_inc_indirect]
    n2 = incs2[1,:net_inc_indirect]
    # add in employer's NI
    eni1 = incs1[1,:employers_ni]
    eni2 = incs2[1,:employers_ni]
    d = (n1-eni1) - (n2-eni2)
    d /= 1_000_000
    colour = "alert-info"
    extra = ""
    change_str = "In total, your changes are revenue-neutral (to within £1m pa.)"
    change_val = ""
    if abs(d) > 1
        change_val = f0(abs(d))
        if d > 0
            colour = "alert-success"
            change_str = "In total, your changes raise £"
            extra = "m."
        else
            colour = "alert-danger"
            change_str = "In total, your changes cost £"
            extra = "m."
        end
    end
    costs = "<div class='alert $colour'>$change_str<strong>$change_val</strong>$extra</div>"
    return costs
end

function mr_table( mr1, mr2 )
    df = mr_dataframe( mr1.hist, mr2.hist, mr1.mean, mr2.mean )
    n = size(df)[1]
    table = frame_to_table( 
        df, 
        prec=0, 
        up_is_good=MR_UP_GOOD, 
        caption="Working age individuals with Marginal Effective Tax Rates
                (METRs) in the given range. METR is the percentage of the next £1 you earn that is taken away in taxes or 
                reduced means-tested benefits.",
        totals_col = n )   
    return table
end


function ineq_table( ineq1 :: InequalityMeasures, ineq2 :: InequalityMeasures )
    df = ineq_dataframe( ineq1, ineq2 )
    up_is_good = fill( -1, 6 )
    return frame_to_table( 
        df, 
        prec=2, 
        up_is_good=up_is_good, 
        caption="Standard Inequality Measures, using Before Housing Costs Equivalised Net Income." )
end


function pov_table( 
    pov1 :: PovertyMeasures, 
    pov2 :: PovertyMeasures,
    ch1  :: GroupPoverty, 
    ch2  :: GroupPoverty )
    df = pov_dataframe( pov1, pov2, ch1, ch2 )
    up_is_good = fill( -1, 7 )
    return frame_to_table( 
        df, 
        prec=2, 
        up_is_good=up_is_good, 
        caption="Standard Poverty Measures, using Before Housing Costs Equivalised Net Income." )
end


function gain_lose_table( gl :: NamedTuple )
    lose = format(gl.losers, commas=true, precision=0)
    gain = format(gl.gainers, commas=true, precision=0)
    nc = format(gl.nc, commas=true, precision=0)
    losepct = md_format(100*gl.losers/gl.popn)
    gainpct = md_format(100*gl.gainers/gl.popn)
    ncpct = md_format(100*gl.nc/gl.popn)
    caption = "Individuals living in households where net income has risen by at least 1%, fallen by at least 1%, or stayed the same respectively."
    table = "<table class='table table-sm'>"
    table *= "<thead>
        <tr>
            <th></th><th style='text-align:right'></th><th style='text-align:right'>%</th>
        </tr>";
    table *= "<caption>$caption</caption>"
    table *= "
        </thead>
        <tbody>"
        table *= "<tr><th>Gainers</th><td style='text-align:right'>$gain</td><td style='text-align:right'>$(gainpct)</td></tr>"
        table *= "<tr><th>Losers</th><td style='text-align:right'>$lose</td><td style='text-align:right'>$(losepct)</td></tr>"
    table *= "<tr><th>Unchanged</th><td style='text-align:right'>$nc</td><td style='text-align:right'>$(ncpct)</td></tr>"
    table *= "</tbody></table>"
    return table
end
#=
 choice of arrows/numbers for the tables - we use various uncode blocks;
 see: https://en.wikipedia.org/wiki/Arrow_(symbol)
 Of 'arrows', only 'arrows_3' displays correctly in Windows, I think,
 arrows_1 is prettiest
=#
    
function make_example_card( settings :: Settings, hh :: ExampleHH, res :: NamedTuple ) :: String
    change = res.pres.bhc_net_income - res.bres.bhc_net_income
    ( gnum, glclass, glstr ) = format_and_class( change )
    i2sp = inctostr(res.pres.income )
    i2sb = inctostr(res.bres.income )
    changestr = gnum != "" ? "&nbsp;"*ARROWS_1[glstr]*"&nbsp;&pound;"* gnum*"pw" : "No Change"
    card = "

    <div class='card' 
        style='width: 12rem;' 
        data-bs-toggle='modal' 
        data-bs-target='#$(hh.picture)' >
            <img src='images/families/$(FAMDIR)/$(hh.picture).png'  
                alt='Picture of Family'  width='100' height='140' />
            <div class='card-body'>
                <p class='$glclass'><strong>$changestr</strong></p>
                <h5 class='card-title'>$(hh.label)</h5>
                <p class='card-text'>$(hh.description)</p>
            </div>
        </div><!-- card -->
";
    @info "card=$card"
    return card
end

function pers_inc_table( res :: NamedTuple ) :: String
    df = two_incs_to_frame( res.bres.income, res.pres.income )
    n = size(df)[1]
    up_is_good = zeros(Int, n )  
    df.Item = fill("",n)
    df.Change = df.After - df.Before
    df.Item = iname.(df.Inc)
    for i in 1:n
       up_is_good[i] =  (df[i,:Inc] in DIRECT_TAXES_AND_DEDUCTIONS) ? -1 : 1
    end
    # indirect tax stuff FIXME make a function somewhere
    push!( up_is_good, -1 )
    push!( df.Item, "VAT")
    push!( df.Inc, OTHER_TAX )     # not actually used
    push!( df.Before, res.bres.indirect.VAT )
    push!( df.After, res.pres.indirect.VAT )
    push!( df.Change, res.pres.indirect.VAT - res.bres.indirect.VAT)
    @info "pers_in_table; final df=$df"
    return frame_to_table( df, prec=2, up_is_good=up_is_good, 
        caption="Household incomes £pw" )    
end

function indirect_table( res :: NamedTuple ) :: String
    up_is_good = [-1]
    df = DataFrame( :Inc=>items, :Before => pres, :After => posts, :)
    ## yada 
end

function hhsummary( hh :: Household )
    caption = ""
    ten = pretty(hh.tenure)
    rm = "Rent"
    hc = format( hh.gross_rent, commas=true, precision=2)
    hregion = pretty(hh.region)
    if is_owner_occupier( hh.tenure )
        hc = format(hh.mortgage_payment, commas=true, precision=2)
        rm = "Mortgage"
    end
    table = "<table class='table table-sm'>"
    table *= "<thead>
        <tr>
            <th></th><th style='text-align:right'></th>
        </tr>";
    table *= "<caption>$caption</caption>"
    table *= "
        </thead>
        <tbody>"
    table *= "<tr><th>Tenure</th><td style='text-align:right'>$ten</td></tr>"
    table *= "<tr><th>$rm</th><td style='text-align:right'>$hc</td></tr>"
    table *= "<tr><th>Living in:</th><td style='text-align:right'>$hregion</td></tr>"
    # ... and so on
    table *= "</tbody></table>"
    table
end

function make_example_popups( settings :: Settings, hh :: ExampleHH, res :: NamedTuple ) :: String
    pit = pers_inc_table( res )
    hhtab = hhsummary( hh.hh )
    modal = """
<!-- Modal -->
<div class='modal fade' id='$(hh.picture)' tabindex='-1' role='dialog' aria-labelledby='$(hh.picture)-label' aria-hidden='true'>
  <div class='modal-dialog' role='document'>
    <div class='modal-content'>
      <div class='modal-header'>
      <h5 class='modal-title' id='$(hh.picture)-label'/>$(hh.label)</h5>
      <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
         
      </div> <!-- header -->
      <div class='modal-body'>
        <div class='row'>
            <div class='col'>
            <img src='images/families/$(FAMDIR)/$(hh.picture).png'  
                width='100' height='140'
                alt='Picture of Family'
              />
            </div>
            <div class='col'>
                $hhtab
            </div>
        </div>
        
        $pit
          
      </div> <!-- body -->
    </div> <!-- content -->
  </div> <!-- dialog -->
</div><!-- modal container -->
"""
    @info modal
    return modal
end

function make_examples( settings::Settings, example_results :: Vector )
    cards = "<div class='card-group'>"
    EXAMPLE_HHS = get_example_hhs(settings)
    n = size( EXAMPLE_HHS )[1]
    for i in 1:n
        cards *= make_example_card( settings, EXAMPLE_HHS[i], example_results[i])
    end
    cards *= "</div>"
    for i in 1:n
        cards *= make_example_popups( settings, EXAMPLE_HHS[i], example_results[i])
    end
    return cards;
end

"""
components = (; lev, tx, fun, lxp, mh, elig, mt, cit, pov, ineq )
return (; avg, components )
"""

const POP_LABELS = Dict([
    :lev=>"Benefit Level",
    :tx =>"Taxation",
    :fun => "Funding",
    :lxp => "Life Expectancy", 
    :mh => "Mental Health", 
    :elig => "Eligibility", 
    :mt => "Means Testing", 
    :cit=>"Citizenship", 
    :pov=>"Poverty", 
    :ineq=>"Inequality"    
])

# Joe's note:
# Graham, I also need to clarify what left-right means in this instance. 
# Both the Labour-Tory and Left-Right variables are drawn from the same 
# survey question asking for their 2019 vote (rather than affiliation). 
# But the Left-Right variable groups Labour, Green, SNP, Plaid Cymru, and Lib Dems 
# together on the one side and Tory/Brexit party on the other. 
# This also means the Other category means something quite different 
# for the two options (The Labour-Tory variable includes all Green SNP Plaid Lib Dem Brexit in 
# “Other/DNV” while Left-Right variable only has independents and if they say actually other). So it is not left-right orientation per se. We might only want to include one of the two if it is overcomplicating it but I wanted to give us two options depending on what people preferred. 
# Or we could leave both but be clearer about what left-right means in this context.
# On the financial well-being variable it might be worth stating the categories under the hood 
# rather than just Difficult-not Difficult. Not difficult = either “Living comfortably” 
# or “Doing alright”, while Difficult = either “Finding it quite difficult” or “Finding it very difficult”. “Just about managing” is just one category as already stated.
POPULARITY_CAPTIONS = Dict(
    [
        "Total"=>"Whole Population",
        "Left"=> "In the 2019 general election, voted for Labour, the Greens, the SNP, Plaid Cymru, the Lib Dems or another left of centre party.",
        "DNV/Other"=>"In the 2019 general election, either did not vote, or voted for an Independent.",
        "Right"=> "In the 2019 general election, voted for the Conservatives, Brexit Party, or another right of centre party.",
        "Labour"=> "Voted Labour at the 2019 General Election.",
        "DNV"=> "In the 2019 Election, voted for some other party, (including SNP, Greens, Brexit, Lib Dems, Independents), or did not vote.",
        "Tory"=>"Voted Conservative at the 2019 General Election.",
        "Not difficult"=>"Living comfortably/doing alright financially.",
        "Just about getting by"=>"Just about managing financially",
        "Difficult"=> "Finding things quite or very difficult financially."
    ]
)


"""
see Dan's email of 5 Jul. Kinda sorta normalise round 50 & use the whole range 0..100.
if the range is 40-60 then this works
"""
function dannify( v :: Number; minr = 0.4, maxr=0.6 ) :: Number
    rng = maxr - minr
    (100*(v - minr)/rng)
    ### (100*(v - 0.5)) + 50
end


function make_popularity_table( 
    pop :: NamedTuple, 
    defaultPop :: NamedTuple,
    caption :: AbstractString  ) :: String
  v = dannify(pop.avg)
  d = dannify(defaultPop.avg)
  fmtd = format_diff( before=d, after=v, up_is_good = true, prec=1,commas=false )
  caption_text = get(POPULARITY_CAPTIONS, caption, caption ) # one of Joe's explanations above, or just the key itself.
  s = """
    <table class='table table-sm'>
        <thead><caption>$caption_text</caption></thead>
        <tr> 
            <th></th>
            <th style='text-align:right'>Baseline</th>
            <th style='text-align:right'>Your Policy</th>
            <th style='text-align:right'>Change</th>
        </tr>
        <tr class='text-primary text-bg'><th>Overall Popularity</th>
            <td style='text-align:right' >$(fmtd.before_s)</td>
            <td style='text-align:right'>$(fmtd.after_s)</td>
            <td style='text-align:right' class='$(fmtd.colour)'>$(fmtd.ds)</td>            
        </tr>
        <tr><td style='text-align:center' colspan='4'>Components:</td></tr>
    """
    
    for k in keys(pop.components)
        lab = POP_LABELS[k]
        v = dannify(pop.components[k])
        d = dannify(defaultPop.components[k])
        fmtd = format_diff( before=d, after=v, up_is_good = true, prec=1,commas=false )
        s *= """
            <tr><th>$lab</th>
                <td style='text-align:right'>$(fmtd.before_s)</td>
                <td style='text-align:right'>$(fmtd.after_s)</td>
                <td style='text-align:right' class='$(fmtd.colour)' >$(fmtd.ds)</td>
            </tr>
            """
    end
    s *= """
    </table>
  """
  return s
end

"""
Main output generation for standard model
"""
function results_to_html( 
    settings     :: Settings, 
    base_results :: AllOutput, 
    results      :: AllOutput ) :: NamedTuple
    
    gain_lose = gain_lose_table( results.gain_lose )
    gains_by_decile = trunc.(results.summary.deciles[1][:,4] - base_results.summary.deciles[1][:,4],digits=5,base=10)

    @info "gains_by_decile = $gains_by_decile"
    costs = costs_table( 
        base_results.summary.income_summary[1],
        results.summary.income_summary[1])
    overall_costs = overall_cost( 
        base_results.summary.income_summary[1],
        results.summary.income_summary[1])
    mrs = mr_table(
        base_results.summary.metrs[1], 
        results.summary.metrs[1] )       
    poverty = pov_table(
        base_results.summary.poverty[1],
        results.summary.poverty[1],
        base_results.summary.child_poverty[1],
        results.summary.child_poverty[1])
    inequality = ineq_table(
        base_results.summary.inequality[1],
        results.summary.inequality[1])
    lorenz_pre = base_results.summary.deciles[1][:,2]
    lorenz_post = results.summary.deciles[1][:,2]
    example_text = make_examples( settings, results.examples )
    big_costs = costs_frame_to_table( 
        detailed_cost_dataframe( 
            base_results.summary.income_summary[1],
            results.summary.income_summary[1] )) 
    outt = ( 
        phase = "end", 
        gain_lose = gain_lose, 
        gains_by_decile = gains_by_decile,
        costs = costs, 
        overall_costs = overall_costs,
        mrs = mrs, 
        poverty=poverty, 
        inequality=inequality, 
        lorenz_pre=lorenz_pre, 
        lorenz_post=lorenz_post,
        examples = example_text,
        big_costs_table = big_costs,
        endnotes = Markdown.html( ENDNOTES ))
    return outt
end


function make_disaggregated_popularity_table( 
    preferences :: Dict ) :: String
    d = Dict()
    for( k, v ) in preferences
        # lab = k == "Total" ? "Whole Population" : k
        popularity = make_popularity_table( 
            v.popularity, v.default_popularity, k )
        d[k] = popularity 
    end
    return """
<div id='conjoint-top'>
    <nav>
        <ul class='nav'>
            <li class="nav-item">
                <a class='nav-link active' href='#conjoint-total'>Whole Population</a>
            </li>
            <li class='nav-item'>
                <a class='nav-link' href='#conjoint-left-right'>Left/Right Orientation</a>
            </li>
            <li class='nav-item'>
                <a class='nav-link' href='#conjoint-party'>Party Identification</a>
            </li>
            <li class='nav-item'>
                <a class='nav-link' href='#conjoint-gender'>Gender</a>
            </li>
            <li class='nav-item'>
                <a class='nav-link' href='#conjoint-financial'>Financial Wellbeing</a>
            </li>
            <li class='nav-item'>
                <a class='nav-link' href='#conjoint-age'>Age</a>
            </li>
        </ul>
    </nav>
    <div class='row border-top border-primary pt-2'  id='conjoint-total'>
        <div class='col-3'><h3 class="text-center">Whole Population</h3></div>
    </div>
    <div class='row border-bottom border-primary pb-2 mb-2'>
        <div class='col'></div>
        <div class='col'>$(d["Total"])</div>
        <div class='col'></div>
    </div>
    <div class='row' id='conjoint-left-right'>
        <div class='col-3'><h3 class="text-center">Left/Right Orientation</h3></div>
    </div>
    <div class='row border-bottom border-primary pb-2 mb-2'>
        <div class='col'>
            <h4>Left</h4>
            $(d["Left"])
        </div>
        <div class='col'>
            <h4>Did Not Vote / Other</h4>
            $(d["DNV/Other"])
        </div>
        <div class='col'>
            <h4>Right</h4>
            $(d["Right"])
        </div>
    </div>
    <div class='row' id='conjoint-party'>
        <div class='col-3'><h3  class="text-center">Party Vote 2019</h3></div>
    </div>    
    <div class='row  border-bottom border-primary pb-2 mb-2'>
        <div class='col'>
            <h4>Labour</h4>
            $(d["Labour"])       
        </div>
        <div class='col'>
            <h4>Did Not Vote / Other</h4>
            $(d["DNV"])
        </div>
        <div class='col'>
            <h4>Conservative</h4>
            $(d["Tory"])
        </div>
    </div>
    <div class='row' id='conjoint-gender'>
        <div class='col-3'><h3 class="text-center">Gender</h3></div>
    </div>
    <div class='row  border-bottom border-primary pb-2 mb-2'>
        <div class='col'>
            <h4>Male</h4>
            $(d["Male"])
        </div>
        <div class='col'>
            <h4>Female</h4>
            $(d["Female"])
        </div>
        <div class='col'></div>
    </div>
    <div class='row' id='conjoint-financial'>
        <div class='col-3'><h3 class="text-center">Financial Wellbeing</h3></div>
    </div>
    <div class='row  border-bottom border-primary pb-2 mb-2'>
        <div class='col'>
            <h4>Not difficult</h4>
            $(d["Not difficult"])
        </div>
        <div class='col'>
            <h4>Just about getting by</h4>
            $(d["Just about getting by"])
        </div>
        <div class='col'>
            <h4>Difficult</h4>
            $(d["Difficult"])
        </div>
    </div>
    <div class='row' id='conjoint-age'>
        <div class='col-3'><h3  class="text-center">Age Range</h3></div>
    </div>
    <div class='row'>
        <div class='col'>
            <h4>18-54</h4>
            $(d["18-54"])
        </div>
        <div class='col'>
            <h4>55+</h4>
            $(d["55+"])
        </div>
        <div class='col'></div>
    </div>
</div>
"""
end

function one_gain_lose( gl :: DataFrame, caption :: String ) :: String
    nr,nc = size( gl )
    nms = names(gl)
    for c in 2:(n-2)
        nms[c] = pretty(nms[c])
    end    
    s = """
    <table class='table table-sm'>
        <thead><caption>By $(caption), 000s of People.</caption></thead>
        <tr> 
            <th>$caption</th>
    """
    for c = 2:nc 
       s *= "<th style='text-align:right'>$(nms[c])</th>"
    end
    s *= """
    </tr>
    """    
    startr = sum( gl[1,2:(nc-2)]) == 0 ? 2 : 1 # skip 1st row if all blank counts
    for r in startr:nr
        v = pretty(gl[r,1])
        s *=  """
            <tr><th>$v</th>
        """
        for c in 2:nc
            vs = ""
            v = gl[r,c]
            if c in 2:(nc-2) # format last 2 cols (average change) with more precision 
                v /= 1_000.0
                vs = format(v, commas=true, precision=0)
            elseif c == (nc-1) # average equiv change in £s pw
                vs = format(v, commas=true, precision=2 )
            elseif( c == nc ) # final total transfer col in £m
                vs = format(v, commas=true, precision=0 )
            end
            s *= "<td style='text-align:right'>$vs</td>"
        end
        s *= """
        </tr>
        """
    end
    s *= """
        </table>
    """
    return s
end

function make_disaggregated_gain_lose_tables( gain_lose :: NamedTuple ) :: String
    ten_gl = one_gain_lose( gain_lose.ten_gl, "Tenure" )
    dec_gl = one_gain_lose( gain_lose.dec_gl, "Decile" )
    children_gl = one_gain_lose( gain_lose.children_gl, "Number of Children" )
    hhtype_gl = one_gain_lose( gain_lose.hhtype_gl, "Household Size" )
    
    return """
        <div>
    
            <div class='row'>
                <div class='col'>
                    <h5>By Household Size</h5>
                    $hhtype_gl
                </div>
            </div>

            <div class='row'>
                <div class='col'>
                    <h5>By Income Decile</h5>
                    $dec_gl
                </div>
            </div>

            <div class='row'>
                <div class='col'>
                    <h5>By Tenure</h5>
                    $ten_gl
                </div>
            </div>

            <div class='row'>
                <div class='col'>
                    <h5>By Number of Children</h5>
                    $children_gl
                </div>
            </div>

        </div>
    """
end

function make_sf_12_table( 
    sf_pre::NamedTuple, 
    sf_post::NamedTuple, 
    sf12_depression_limit::Number ) :: String
    pre = format( sf_pre.depressed/1000, commas=true, precision=0 )
    post = format( sf_post.depressed/1000, commas=true, precision=0 )
    pre_pct = format( sf_pre.depressed_pct, commas=false, precision=1 )
    post_pct = format( sf_post.depressed_pct, commas=false, precision=1 )
    fmtd = format_diff( 
        before=sf_pre.depressed/1000, 
        after=sf_post.depressed/1000, 
        up_is_good=false, 
        prec=0 )
    chpct = 100*(sf_post.depressed-sf_pre.depressed)/sf_pre.depressed
    changepct = format( chpct, commas=false, precision=1 )

    pre_mean = format( sf_pre.average, commas=false, precision=1 )
    post_mean = format( sf_post.average, commas=false, precision=1 )
    fmtd_mean = format_diff( 
        before=sf_pre.average, 
        after=sf_post.average, 
        up_is_good=true, 
        prec=1 )
    pre_median = format( sf_pre.med, commas=false, precision=1 )
    post_median = format( sf_post.med, commas=false, precision=1 )
    fmtd_median = format_diff( 
        before=sf_pre.med, 
        after=sf_post.med, 
        up_is_good=true, 
        prec=1 )
    
    # (; colour, ds, before_s, after_s )
    caption = """
    The estimated number of adults (in 000s) with 
    <a href='https://www.rand.org/health-care/surveys_tools/mos/12-item-short-form.html'>SF-12 Mental Health Component</a> 
    score of less than $(sf12_depression_limit),
    and the mean and median SF-12 score for the adult population.
    SF-12 is a 12-question survey often used to summarise a patients' mental health.
    Higher scores are better; a score of less than $(sf12_depression_limit) may 
    indicate a mental health problem.
    """

    return """
    <table class='table table-sm'>
    <thead><caption>$(caption)</caption></thead>
    <tr> 
        <th></th>
        <th style='text-align:right'>Baseline</th>
        <th style='text-align:right'>Your Policy</th>
        <th style='text-align:right'>Change</th>
    </tr>
    <tr>
        <th>Adults below Critical Threshold ($sf12_depression_limit) (000s)</th>
        <td style='text-align:right'> $pre ($(pre_pct)%)</td>
        <td style='text-align:right'> $post ($(post_pct)%)</td>
        <td  style='text-align:right' class="$(fmtd.colour)">$(fmtd.ds) ($(changepct)%)</td>
    </tr>

    <tr>
        <th>Mean Score (range 0-100)</th>
        <td style='text-align:right'> $pre_mean </td>
        <td style='text-align:right'> $post_mean </td>
        <td  style='text-align:right' class="$(fmtd_mean.colour)">$(fmtd_mean.ds)</td>
    </tr>
    <tr>
        <th>Median Score (range 0-100)</th>
        <td style='text-align:right'> $pre_median </td>
        <td style='text-align:right'> $post_median </td>
        <td  style='text-align:right' class="$(fmtd_median.colour)">$(fmtd_median.ds)</td>
    </tr>

    </table>
    """
end

"""
Main output generation for conjoint model FIXME do the ; [...], thing trick here
"""
function results_to_html_conjoint( 
  settings     :: Settings,  
  results      :: NamedTuple ) :: NamedTuple
  # table expects a tuple
  gls = ( gainers = results.summary.gain_lose[2].gainers, 
          losers=results.summary.gain_lose[2].losers, 
          nc=results.summary.gain_lose[2].nc,
          popn = results.summary.gain_lose[2].popn )

  gain_lose = gain_lose_table( gls )
  big_gain_lose = make_disaggregated_gain_lose_tables(
    results.summary.gain_lose[2]
  )
  # Round to stop Vega printing silly graphs with all-ish zero changes.
  #= FIXME make this 'Rawls' version swappable with the gl "Marx" version below. 
  v1. Gains by decile allowing the hhls in the bottom decile to change with e.g. wealth tax.
  gains_by_decile = trunc.( results.summary.deciles[2][:,4] -
        results.summary.deciles[1][:,4]; digits=5,base=10)
  =#

  # v2: Decgains - average again by fixed system1 decile, in case the decile changes in sys2 e.g with big wealth tax changes
  decgains = results.summary.gain_lose[2].dec_gl."Total Transfer £m" # FIXME silly column name.
  gains_by_decile = trunc.(decgains,digits=5,base=10)[2:end] # skipping 1st 0 entry

    
  @info "gains_by_decile = $gains_by_decile"
  other_tax_name = if results.funding == "Tax on wealth"
    "Wealth Tax"
  elseif results.funding == "Corporation tax increase"
    "Corporation Tax Increase"
  else # and so on...
    ""
  end

  costs = costs_table( 
    results.summary.income_summary[1],
    results.summary.income_summary[2],
    scotland = false,
    other_tax_name = other_tax_name )

  costs_one_liner = overall_cost( 
      results.summary.income_summary[1],
      results.summary.income_summary[2])
  big_costs = costs_frame_to_table( 
        detailed_cost_dataframe( 
            results.summary.income_summary[1],
            results.summary.income_summary[2] ))
    
  mrs = mr_table(
      results.summary.metrs[1], 
      results.summary.metrs[2] )       
  poverty = pov_table(
      results.summary.poverty[1],
      results.summary.poverty[2],
      results.summary.child_poverty[1],
      results.summary.child_poverty[2])
  inequality = ineq_table(
      results.summary.inequality[1],
      results.summary.inequality[2])
  lorenz_pre = results.summary.deciles[1][:,2]
  lorenz_post = results.summary.deciles[2][:,2]
  example_text = make_examples( settings, results.examples )
           
  popularity = make_popularity_table( 
    results.preferences["Total"].popularity, 
    results.preferences["Total"].default_popularity,
    "Preferences for the whole population." )
  big_popularity = make_disaggregated_popularity_table( 
    results.preferences )

  mortality_table = "<h3>MORT GOES HERE</h3>"
  sf_12_table = make_sf_12_table( 
    results.sf_pre, 
    results.sf_post, 
    results.sf12_depression_limit )
  pre_thresh = results.sf_pre.thresholds # .* results.sf_pre.popn
  post_thresh = results.sf_post.thresholds # .* results.sf_post.popn
  @info "post_thresh = $post_thresh"
  sf_12_ranges = collect(results.sf_post.range) .* results.sf_post.popn
  optchange = format_optimising_change( results.funding, results.optimised_rate, results.amount_needed )
  outt = ( 
      phase = "end", 
      
      optchange = optchange,

      popularity = popularity,
      big_popularity = big_popularity,

      gain_lose = gain_lose, 
      big_gain_lose = big_gain_lose,

      costs = costs, 
      costs_one_liner = costs_one_liner,
      big_costs = big_costs,

      gains_by_decile = gains_by_decile,
      mrs = mrs, 
      poverty=poverty, 
      inequality=inequality, 
      lorenz_pre=lorenz_pre, 
      lorenz_post=lorenz_post,
      examples = example_text,
      big_costs_table = big_costs,
      sf_12_table = sf_12_table,
      sf12_depression_limit = results.sf12_depression_limit,
      sf_12_thresholds_pre = pre_thresh,
      sf_12_thresholds_post = post_thresh,
      sf_12_ranges = sf_12_ranges,
      sf_12_popn = results.sf_post.popn,
      mortality_table = mortality_table,
      endnotes = Markdown.html( CONJOINT_ENDNOTES ))
  return outt
end

