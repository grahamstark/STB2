
const ENDNOTES = md"""

#### Notes

* Likewise, changing the *Universal Credit: single 25+ adult* field changes the rates for young people and couples. 
* Scotland is [in the process of switching working-age families to Universal Credit from 'Legacy Benefits' (Income Support, Housing Benefit, etc.) ](https://commonslibrary.parliament.uk/constituency-data-universal-credit-roll-out/). I've written a [note on how this is modelled](https://stb-blog.virtual-worlds.scot/articles/2021/11/12/uc-legacy.html) - the code is [here](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/UCTransition.jl);

Poverty and Inequality: 
* based on [equivalised before housing costs income](https://www.gov.scot/publications/poverty-in-scotland-methodology/pages/household-income-definition/). 
* uses 60% of *Scottish* (not UK) median income as poverty line (official target uses the UK median).
* poverty line is [relative](https://www.gov.scot/publications/poverty-in-scotland-methodology/pages/poverty-definition/) - so may be different after your changes.

#### Key Assumptions

* *No behavioural changes*: increasing or decreasing taxes doesn't cause people to change how they work and earn;
* the model reports *entitlements to benefits and liability to taxes*, not receipts and payments - so we may overstate the costs of benefits since some eligible families may not claim the things they're entitled to. With taxes, some may be paid with a considerable delay, and some evaded or avoided.

See [the model blog](https://stb-blog.virtual-worlds.scot/) for more gory details (*content warning - very boring and rambling)*.

#### Known Problems

* measures of inequality seem low compared to official statistics.

I'd very much welcome contributions and suggestions. If you spot anything odd or if you have any ideas for how this can be improved, you can:

* [Open an issue on GitHub](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/issues); or
* [email me](mailto:graham.stark@virtual-worlds.biz).

### To Find Out More

You'll have to do some reading, I'm afraid. Some links:

* **Tax Benefit Models**: [A short introduction to microsimulation and tax benefit models](https://stb.virtual-worlds.scot/intro.html). Originally written for the Open University, it covers all the essential ideas. | [Blog Posts about the Model](https://stb-blog.virtual-worlds.scot/);
* **Poverty and Inequality**: [My Notes](https://stb.virtual-worlds.scot/poverty.html) | [World Bank Handbook](http://documents.worldbank.org/curated/en/488081468157174849/Handbook-on-poverty-and-inequality) | [Official Figures for Scotland](https://data.gov.scot/poverty/);
* **Scotland's Finances**: [Scottish Fiscal Commission](https://www.fiscalcommission.scot/publications/scotlands-economic-and-fiscal-forecasts-august-2021/) | [Scottish Government Budget Documents](https://www.gov.scot/budget/).


* Created with [Julia](https://julialang.org/) | [Genie](https://genieframework.com/) | [Bootstrap](https://getbootstrap.com/) | [JQuery](https://jquery.com/) | [Vega](https://vega.github.io/vega-lite/) | [Poverty and Inequality Measures](https://github.com/grahamstark/PovertyAndInequalityMeasures.jl);
* Part of the [Scottish Tax Benefit Model](https://github.com/grahamstark/ScottishTaxBenefitModel.jl);	
* Open Source software released under the [MIT Licence](https://github.com/grahamstark/STB2/blob/main/LICENSE). [Source Code](https://github.com/grahamstark/STB2).


Written by [Graham Stark](https://virtual-worlds.scot) | email: [graham.stark@virtual-worlds.scot](mailto:graham.stark@virtual-worlds.scot) | [Mastodon](https://mastodon.social/@graham_s)  

"""