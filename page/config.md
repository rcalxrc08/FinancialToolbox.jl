<!--
The definitions here control the layout of the page: basic geometry, colors,
and elements. To avoid errors, do not remove definitions, rather, leave them
empty. Some definitions are only used if a toggle is set.

You can add your own rules if you so desire by either:
  - directly modifying `_css/custom.css`
  - adding rules to `_layout/style_tuning.fcss`
The latter allows you to plug in values that you would have defined here.
-->

<!-- META DEFINITIONS
  NOTE:
  - prepath: this is used to specify the base URLs; if your site should be
             available at `https://username.github.io/YourPackage.jl/` then the
             pre-path should be `YourPackage.jl`. If your site is meant to be
             hosted on a specific URL such as `https://awesomepkg.org` then set
             `prepath` to an empty string. Finally, adjust this if you want the
             deployed page to be in a subfolder e.g.: `YourPackage.jl/web/`.
-->
@def title       = "FinancialToolbox.jl"
@def prepath     = "FinancialToolbox.jl"
@def description = """
                   Pricing, Greeks and implied volatility under the Black and Black &amp; Scholes models,
                   with the same syntax as the Matlab Financial Toolbox. Generic in the number type:
                   it works with <code>Float32</code>, <code>BigFloat</code>, complex numbers and
                   automatic differentiation out of the box.
                   """
@def tagline     = "<b>Black &amp; Scholes</b> · <b>Greeks</b> · <b>Implied volatility</b>"
@def home_url    = "https://rcalxrc08.github.io/"
@def authors     = "Nicola Scaramuzzino"

<!--  NAVBAR SPECS
  NOTE:
  - add_docs:  whether to add a pointer to your docs website
  - docs_url:  the url of the docs website (ignored if add_docs=false)
  - docs_name: how the link should be named in the navbar

  - add_nav_logo:  whether to add a logo left of the package name
  - nav_logo_path: where the logo is
-->
@def add_docs  = false
@def docs_url  = "https://franklinjl.org/"
@def docs_name = "Docs"

@def add_nav_logo   = true
@def nav_logo_path  = "/assets/logo.png"
@def nav_logo_alt   = "Logo"
@def nav_logo_style = """
                      height:         26px;
                      margin-right:   10px;
                      """

<!-- HEADER SPECS
  NOTE:
  - use_header:         if false, toggle the header off completely
  - tagline:            line shown under the title (HTML allowed)
  - home_url:           "All projects" button and footer link
  - add_github_view:    whether to add a "GitHub" button in header
  - add_github_star:    whether to add a "Star" button in header
  - github_repo:        path to the GitHub repo for the GitHub buttons
-->
@def use_header       = true

@def add_github_view  = true
@def add_github_star  = true
@def github_repo      = "rcalxrc08/FinancialToolbox.jl"

<!-- SECTION LAYOUT
NOTE:
  - section_width:  integer number to control the default width of sections
                    you can also set it for individual sections by specifying
                    the width argument: `\begin{:section, ..., width=10}`.
-->
@def section_width = 10

<!-- COLORS
NOTE:
  - header_color:  theme color of the page (browser UI); the palette itself,
                   light and dark, is defined in `_css/custom.css`
-->
@def header_color       = "#3b6fb6"

<!-- CODE LAYOUT
NOTE:
  - highlight_theme:    theme for the code; only the stylesheet of this theme
                        is kept in `_libs/highlight/styles/`, to switch theme
                        add the corresponding file from
                        https://highlightjs.org/static/demo/ (lower case,
                        spaces replaced with `-`).
  - code_border_radius: how rounded the corners of code blocks should be
  - code_output_indent: how much left-identation to add for "output blocks"
                        (results of the evaluation of code blocks), use 0 if
                        you don't want indentation.
-->
@def highlight_theme    = "atom-one-dark"
@def code_border_radius = "10px"
@def code_output_indent = "15px"


<!-- YOUR DEFINITIONS
See franklinjl.org for more information on how to introduce your own
definitions and how they can be useful.
-->


<!-- INTERNAL DEFINITIONS =====================================================
===============================================================================
These definitions are important for the good functioning of some of the
commands that are defined and used in PkgPage.jl
-->
@def sections        = Pair{String,String}[]
@def section_counter = 1
@def showall         = true

\newcommand{\html}[1]{~~~#1~~~}

\newenvironment{center}{\html{<div style="text-align:center;">}}{\html{</div>}}

\newenvironment{columns}{\html{<div class="container"><div class="row">}}{\html{</div></div>}}
