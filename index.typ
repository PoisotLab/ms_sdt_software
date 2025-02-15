// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let unescape-eval(str) = {
  return eval(str.replace("\\", ""))
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: white, width: 100%, inset: 8pt, body))
      }
    )
}

#let CERG(
  // The paper's title.
  title: "Paper Title",

  // An array of authors. For each author you can specify a name,
  // department, organization, location, and email. Everything but
  // but the name is optional.
  authors: (),
  affiliations: (),

  // The paper's abstract. Can be omitted if you don't have one.
  abstract: none,

  // A list of index terms to display after the abstract.
  keywords: (),

  // The article's paper size. Also affects the margins.
  paper-size: "us-letter",

  // The path to a bibliography file if you want to cite some external
  // works.
  bibliography-file: none,

  // The paper's content.
  body
) = {
  // Set document metadata.
  set document(title: title, author: authors.map(author => author.name))

  show figure.caption: it => {
    set align(left)
    set par(leading: 0.35em, hanging-indent: 0pt, justify: false)
    text(8pt, it)
  }

    // show bibliography: set text(7pt)

  // Set the body font.
  set text(font: "Libertinus Serif", size: 10pt)

  // Configure the page.
  set page(
    paper: paper-size,
    // The margins depend on the paper size.
    margin: if paper-size == "a4" {
      (x: 41.5pt, top: 80.51pt, bottom: 89.51pt)
    } else {
      (
        x: (40pt / 216mm) * 100%,
        top: (55pt / 279mm) * 100%,
        bottom: (64pt / 279mm) * 100%,
      )
    }
  )

  // Configure equation numbering and spacing.
  set math.equation(numbering: "(1)")
  show math.equation: set block(spacing: 0.65em)

  // Configure lists.
  set enum(indent: 10pt, body-indent: 9pt)
  set list(indent: 10pt, body-indent: 9pt)

  // Code
  show raw: set text(font: "JuliaMono", rgb("#232323"))

  // Paragraph options
  set par(leading: 0.5em, first-line-indent: 0pt)
  show heading.where(level: 1): set text(12pt, rgb("#114f54"), font: "Inter", weight: "medium")
  show heading.where(level: 2): set text(10pt, rgb("#2e5385"), font: "Inter", weight: "regular", style: "italic")
  show heading.where(level: 1): it => block(width: 100%)[
    #block(it.body)
  ]
  show heading.where(level: 2): it => block(width: 100%)[
    #block(it.body)
  ]

  // Display the paper's title.
  text(18pt, rgb("#1d8265"), weight: "light",  font: "Inter", title)
  v(8.35mm, weak: true)


  if authors.len() > 0 {
    box(inset: (y: 10pt), {
      authors.map(author => {
        text(10pt, author.name)
        h(1pt)
        if "affiliations" in author {
          super(author.affiliations)
        }
      }).join(", ", last: " and ")
    })
  }
  v(2mm, weak: true)
  if affiliations.len() > 0 {
    box(inset: (y: 10pt), {
      affiliations.map(affiliation => {
        text(9pt, weight: "semibold", super(affiliation.number))
        h(2pt)
        text(9pt, affiliation.name)
      }).join("; ", last: "; ")
    })
  }

  v(8.35mm, weak: true)

    // Display abstract and index terms.
  if abstract != none [
    #set par(justify: false, first-line-indent: 0em)
    #set text(weight: 600)
    _Abstract_:
    #set text(weight: 400)
    #abstract

    #if keywords != () [
        #set text(weight: 600)
      _Keywords_: 
      #set text(weight: 400)
      #keywords.join(", ")
    ]
    #v(2pt)
  ]

  v(1cm)

  // Start two column mode and configure paragraph properties.
  show: columns.with(2, gutter: 14pt)
  set par(justify: true, first-line-indent: 0em)
  show par: set block(spacing: 0.65em)

  // Display the paper's contents.
  body
}

#show: CERG.with(
  title: "A Julia toolkit for species distribution data",
  abstract: [(1) Species distribution modeling requires to handle varied types of data, and benefits from an integrated approach to programming. (2) We introduce #strong[SpeciesDistributionToolkit];, a #strong[Julia] package aiming to facilitate the production of species distribution models. It covers various steps of the data collection and analysis process, extending to the development of interfaces for integration of additional functionalities. (3) By relying on semantic versioning and strong design choices on modularity, we expect that this package will lead to improved reproducibility and long-term maintainability. (4) We illustrate the functionalities of the package through several case studies, accompanied by reproducible code.],
    authors: (
                                    (
                    name: "Timothée Poisot",
                    affiliations: [1],
                    email: "timothee.poisot\@umontreal.ca",
                    orcid: ""
                ),
                                                (
                    name: "Ariane Bussières-Fournel",
                    affiliations: [1],
                    email: "ariane.bussieres-fournel\@umontreal.ca",
                    orcid: ""
                ),
                                                (
                    name: "Gabriel Dansereau",
                    affiliations: [1],
                    email: "gabriel.dansereau\@umontreal.ca",
                    orcid: ""
                ),
                                                (
                    name: "Michael D. Catchen",
                    affiliations: [1],
                    email: "michael.catchen\@umontreal.ca",
                    orcid: ""
                ),
                        ),
    affiliations: (
                                    (
                    name: "Université de Montréal",
                    number: "1",
                ),
                        ),
  keywords: ("species distribution models", "biogeography", "occurrence data", "land use", "climatic data", "pseudo-absences"),
)

= Introduction
<introduction>
Species Distribution Models \[SDMs; #cite(<Elith2009>, form: "prose");\], in addition to being key tools to further our knowledge of biodiversity, are key components of effective conservation decisions @Guisan2013-ps, planning @McShea2014, and ecological impact assesment @Baker2021. The training and evaluation of a SDM is a complex process, with key decisions to make on design and reporting @Zurell2020. The ability to link data to these steps is central to support the correct interpretation of these models @Araujo2019. In the recent years, there has been an increase in the number of software packages and tools to assist ecologists with various steps of the development of species distribution models.

As #cite(<Kass2024-vy>, form: "prose") point out, this increase in the diversity of software tools (most of them in the #strong[R] language) is a good thing. Because the SDMs are a general-purpose methodology, a varied software offers increases the chances that specific decisions can be chained together in the way that best support a specific use case. By making code available for all users, package developers reduce the need for custom implementation of analytical steps, and contribute to the adoption of good practices in the field. However, because building, validating, and applying SDMs requires a diversity of data types, from different sources, many existing packages have been designed independentl. Therefore, they may suffer from low interoperability, which can create friction when using multiple tools together. As an illustration, #cite(<Kellner2025>, form: "prose") highlight that about 20% of publications for abundance or distribution models are not reproducible because of issues in package dependencies.

To promote interoperability and improve reproductibility, tools that provide an integrated environment are important. In this manuscript, we present #strong[SpeciesDistributionToolkit] (abbreviated as #strong[SDT];), a meta-package for the #strong[Julia] programming language, offering an integrated environment for the retrieval, formatting, and interpretation of data relevant to the modeling of species distributions. #strong[SDT] was in part designed to work within the BON-in-a-Box project @Gonzalez2023@Griffith2024, a GEO BON initiative to facilitate the calculation and reporting of biodiversity indicators supporting the Kunming-Montréal Global Biodiversity Framework. A leading design consideration for #strong[SDT] was therefore to maximize interoperability between components and functionalities from the ground up. This is achieved through two mechanisms. First, by relying on strict semantic versioning: package releases provide information about the compatibility of existing code. Second, through the use of #emph[interfaces];: separate software components (including ones external to the package) can interact without prior knowledge of either implementation, and without #emph[dependencies] between the components of #strong[SDT];.

In this manuscript, we describe provide a high-level overview of the functionalities of the package(s) forming #strong[SDT];. We then discuss design principles that facilitate long-term maintenance, development, and integration. We finish by presenting four illustrative case studies: extraction of data at known species occurrences, manipulation of multiple geospatial layers, training and explanation of a SDM, and creation of a virtual species. This later case study is intended to provide an impression of what using #strong[SDT] as a support for the development of novel analyses feels like. All of the case studies are available as supplementary material, in the form of fully reproducible, self-contained Jupyter notebooks.

= Application description
<application-description>
#strong[SpeciesDistributionToolkit] is released as a package for the #strong[Julia] programming language @Bezanson2017. It is licensed under the open-source initiative approved MIT license. It has evolved from a previous collection of packages to handle GBIF and raster data @Dansereau2021, and now provides extended functionalities as well as improved performance. The package is registered in the #strong[Julia] package repository and can be downloaded and installed anonymously. It is compatible with the current long-term support (LTS) release of #strong[Julia];. The full source code, complete commit history, plans for future development, and a forum, are available at #link("https://github.com/PoisotLab/SpeciesDistributionToolkit.jl")[`https://github.com/PoisotLab/SpeciesDistributionToolkit.jl`];. This page additionally has a link to the documentation, containing a full reference for the package functions, a series of briefs how-to examples, and longer vignettes showcasing more integrative tutorials.

== Component packages
<component-packages>
An overview of the #strong[SDT] package is given in @fig-components. The project is organized as a "monorepo", in which separate but interoperable packages reside. This allows expanding the scope of the package by moving functionalities into new component packages, without requiring interventions from users. As #strong[SDT] is registered in the #strong[Julia] package repository, it can be installed by using `add SpeciesDistributionToolkit` when in package mode at the #strong[Julia] prompt. When loading the #strong[SDT] package with `using SpeciesDistributionToolkit`, all component packages are automatically and transparently loaded. Therefore, users do not need to know where a specific method or function resides to use it.

#figure([
#box(image("figures/SDT.png"))
], caption: figure.caption(
position: bottom, 
[
Overview of the packages included in #strong[SpeciesDistributionToolkit];. The packages are color-coded by intended use, and their more specific content is presented in the main text. Note that because the package relies on #emph[interfaces] to facilitate code interoperability, there are only three dependency relationships (black arrows).
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-components>


The #strong[SDT] package primarily provides integration between the other packages via method overloading (reusing method names for intuitive and concise code), allowing to efficiently join packages together @Roesch2023. Additional functionalities that reside in the top-level package are the generation of pseudo-absences @Barbet-Massin2012, access to the `gadm.org` database, handling of polygon data and zonal statistics, and various quality of life methods. Because of the modular nature of the code, any of these functions can be transparently moved to their own packages without affecting reproducibility. Note that all packages can still be installed (and would be fully functional) independently.

The #strong[SimpleSDMLayers] package offers a series of types to represent raster data in arbitrary projections defined by a proj string @Evenden2024-yi. This package provides the main data representation for most spatial functionalities that #strong[SDT] supports, and handles saving and loading data. In addition, it contains utility functions to deal with raster data, including interpolation to different spatial grids and CRS, rescaling and quantization of data, masking, and most mathematical operations that can be applied to rasters.

#strong[OccurrencesInterface] is a light-weight package to provide a common interface for occurrence data. It implements abstract and concrete types to define a single occurrence and a collection thereof, and a series of methods allowing any occurrence data provider (e.g.~GBIF) or data representation to become fully interoperable with the rest of #strong[SDT];. All #strong[SDT] methods that handle occurrence data do so through the interface provided by the #strong[OccurrencesInterface] package, allowing future data sources to be integrated without the need for new code.

The #strong[GBIF] package offers access to the `gbif.org` streaming API @GBIF:TheGlobalBiodiversityInformationFacility2025, including the ability to retrieve, filter, and restart downloads. Although this package provides a rich data representation for occurrence data when access to the full GBIF data schema is required, all the objects it returns adhere to the #strong[OccurrencesInterface] interface.

#strong[SimpleSDMDatasets] implements an interface to retrieve and locally store raster data, which can be extended by users to support additional data sources. In addition, it offers access to a series of common data sources for spatial biodiversity modeling, including the biodiversity mapping project @Jenkins2013, the EarthEnv collection for land cover @Tuanmu2014 and habitat heterogeneity @Tuanmu2015, Copernicus land cover 100m data @Buchhorn2020, the PaleoClim @Brown2018 data, the WorldClim 1 and 2 data @Fick2017 and their projections under various RCPs and SSP, and part of the CHELSA 1 and 2 data @Karger2017 and their projections under various RCPs and SSPs.

#strong[Phylopic] offers a wrapper around the `phylopic.org` API to download silhouettes for taxonomic entities. It also provides utilities for citation of the downloaded images. Its functionalities are similar to the #strong[rphylopic] package @Gearty2023.

The #strong[Fauxcurrences] packages is inspired by the work of #cite(<Osborne2022>, form: "prose");, and allows generating a series of simulated occurrence data that have the same statistical structure as observed ones. The package supports multi-species data, with user-specified weights for conserving intra and inter-specific occurrence distances.

The #strong[SDeMo] package is aimed at providing tools to use as part of training and education material on species distribution modeling. By providing a series of data transformation (PCA, Whitening, z-score) and classifiers (BIOCLIM, Naive Bayes, logistic regression, and decision trees), it offers the basic elements to demonstrate training and evaluation of SDMs, as well as techniques related to heterogeneous ensembles and bagging with support for arbitrary consensus @Marmion2009 and voting @Drake2014 functions. In addition, #strong[SDeMo] promotes the use of interpretable techniques: the package supports regular @Elith2005 and inflated @Zurell2012 partial responses, as well as the calculation and mapping of Shapley values @Wadoux2023@Mesgaran2014 using the standard Monte-Carlo approach @Mitchell2021. Counterfactuals @VanLooveren2019@Karimi2019, representing perturbation of the input data leading to the opposite prediction (#emph[i.e.] "what environmental conditions would lead to the species being absent") can also be generated.

== Software information
<software-information>
#strong[SDT] uses the built-in #strong[Julia] package manager to ensure that the version of all dependencies are kept up to date. Furthermore, we use strict semantic versioning: major versions correspond to no breaking changes in user-developped code, minor versions increase with additional functionalities, and patch releases cover minor bug fixes or documentation changes. All packages have a #emph[CHANGELOG] file, which documents what changes are included in each release. Following a constructive cost model analysis @Kemerer1987 of the version described in this publication, the package represents approx. 11k lines of active code (no blank lines, no comments), for an estimated development cost of approx. 325k USD.

This strict reliance on semantic versioning solves the issues of maintaining compatibility when new functionalities are added: all releases in the #emph[v1.x.x] branch of #strong[SDT] depend on component packages in their respective #emph[v1.x.x] branch, and users can benefit from now functionalities without risking to break existing code. This behavior is extensively tested, both using unit tests, and through integration testing generated as part of the online documentation.

== Integration with other packages
<integration-with-other-packages>
The #strong[SDT] package benefits from close integration with other packages in the #strong[Julia] universe. Notably, this includes #strong[Makie] (and all related backends, with support for #strong[GeoMakie];) @Danisch2021 for plotting and interactive data visualisation, where usual plot types are overloaded for both layer and occurrence data. Most data handled by #strong[SDT] can be exported using the #strong[Tables] interface, which allows data to be consumed by other packages like #strong[DataFrames] @Bouchet-Valat2023 and #strong[MLJ] @Blaom2020, or directly saved as csv files.

Interfaces to internal #strong[Julia] methods are also implemented whenever they are pertinent. In particular, #strong[SimpleSDMLayers] objects behave like arrays, are iterable, and broadcastable; objects from #strong[OccurrencesInterface] behave as arrays and are similarly iterable. The #strong[SDeMo] package relies on part of the #strong[StatsAPI] interface, allowing to easily define new data transformation and classifier types to support additional features.

Achieving integration with other packages through method overloading and the adherence to well-established interfaces is important, as it increases the chances that additional functionalities external to #strong[SDT] can be used directly or fully supported with minimal addition of code.

= Illustrative case studies
<illustrative-case-studies>
In this section, we provide a series of case studies, meant to illustrate the use of the package. The on-line documentation offers longer tutorials, as well as a series of how-to vignettes to illustrate the full scope of what the package allows. The code for each of these case studies is available as fully independent Jupyter notebooks, forming the supplementary material of this article. The example we use throughout is the distribution of #emph[Akodon montensis] (Rodentia, family Cricetidae), a known host of orthohantaviruses @Burgos2021@Owen2010, in Paraguay. As the notebooks accompanying this article cover the full code required to run these case studies, we do not present code snippets in the main text, and instead focus on explaining which component packages are used in each example.

== Using data from GBIF
<using-data-from-gbif>
To illustrate the interactions between the component packages, we provide a simple illustration (Supp. Mat. 1) where we (i) request occurrence data using the #strong[GBIF] package, (ii) download the silhouette of the species through #strong[Phylopic];, and (iii) extract temperature and precipitation data at the points of occurrence. The results are presented in @fig-gbif-phylopic. The full notebook includes information about basic operations on raster data, as well as extraction of data based on occurrence records.

#block[
#figure([
#box(image("index_files/figure-typst/appendix-gbif-fig-gbif-phylopic-output-1.png"))
], caption: figure.caption(
position: bottom, 
[
Relationship between temperature and precipitation (BIO1 and BIO12) at each georeferenced occurrence known to GBIF for #emph[Akodon montensis];. The code to produce this figure is available as Supp. Mat. 1.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-gbif-phylopic>


]
In practice, although the data are retrieved using the #strong[GBIF] package, they are used internally by #strong[SDT] through the #strong[OccurrencesInterface] package. This package defines a small convention to handle georeferenced occurrence data, and allows to transparently integrate additional occurrence sources. By defining five methods for a custom data type, users can plug-in any occurrence data source and enjoy full compatibility with the entire #strong[SDT] functionalities.

== Landcover consensus map
<landcover-consensus-map>
In this case study (Supp. Mat. 2), we retrieve the land cover data from #cite(<Tuanmu2014>, form: "prose");, clip them to a GeoJSON polygon describing the country of Paraguay (#strong[SDT] can download data directly from `gadm.org`), and apply the `mosaic` operation to figure out which class is the most locally abundant. This case study uses the #strong[SimpleSDMDatasets] package to download (and locally cache) the raster data, as well as the #strong[SimpleSDMLayers] package to provide basic utility functions on raster data. The results are presented in @fig-landcover-consensus.

#block[
#figure([
#box(image("index_files/figure-typst/appendix-consensus-fig-landcover-consensus-output-1.png"))
], caption: figure.caption(
position: bottom, 
[
Land cover consensus (defined as the class with the strongest local representation) in the country of Paraguay. Only the classes that were most abundant in at least one pixel are represented. The code to produce this ﬁgure is available as Supp. Mat. 2.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-landcover-consensus>


]
When first downloading data through #strong[SimpleSDMDatasets];, they will be stored locally for future use. When the data are requested a second time, they are read directly from the disk, speeding up the process massively. Note that the location of the data is (i) standardized by the package itself, making the file findable to humans, and (ii) changeable by the user to, #emph[e.g.];, store the data within the project folder rather than in a central location. As much as possible, #strong[SDT] will only read the part of the raster data that is required given the region of interest to the user. This is done by providing additional context in the form of a bounding box (in WGS84, regardless of the underlying raster data projection). #strong[SDT] has methods to calculate the bounding box for all the objects it supports.

== Training a species distribution model
<training-a-species-distribution-model>
In this case study, we illustrate the integration of #strong[SDeMo] and #strong[SimpleSDMLayers] to train a species distribution model. We specifically train a rotation forest @Bagnall2018, an homogeneous ensemble of PCA followed by decision trees. The results are presented in @fig-sdm-output. The model is built by selecting an optimal suite of BioClim variables, then predicted in space, and the resulting predicted species range is finally clipped by the elevational range observed in the occurrence data.

#block[
#figure([
#box(image("index_files/figure-typst/appendix-sdm-fig-sdm-output-output-1.png"))
], caption: figure.caption(
position: bottom, 
[
Predicted range of #emph[Akodon montensis] in Paraguay based on a rotation forest trained on GBIF occurrences and the BioClim variables. The predicted range is clipped to the elevational range of the species. The code to produce this ﬁgure is available as Supp. Mat. 3.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-sdm-output>


]
The full notebook (Supp. Mat. 3) has additional information on routines for variable selection, stratified cross-validation, as well as the construction of the ensemble from a single PCA and decision tree. In addition, we report in @fig-sdm-responses the partial and inflated partial responses to the most important variable (highlighting an interpretable effect of the variable in the model), as well as the (Monte-Carlo) Shapley values @Wadoux2023@Mesgaran2014@Mitchell2021 for each prediction in the training set. Because #strong[SDeMo] works through generic functions, these methods can be applied to any model specified by the user. In practice, flexible ML frameworks exist for #strong[Julia];, notably #strong[MLJ] @Blaom2020, which can be used for real-world applications.

#block[
#figure([
#box(image("index_files/figure-typst/appendix-sdm-fig-sdm-responses-output-1.png"))
], caption: figure.caption(
position: bottom, 
[
Partial responses (red) and inflated partial responses (grey) to the most important variable. In addition, the Shapley values for all training data are presented in the same figure. Shapley values were added to the average model prediction to be comparable to partial responses. The code to produce this ﬁgure is available as Supp. Mat. 3.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-sdm-responses>


]
== Distribution of a virtual species
<distribution-of-a-virtual-species>
In the final case study (Supp. Mat. 4), we simulate a virtual distribution @Hirzel2001, using a species with a logistic response to each environmental covariate @Leroy2016, and a prevalence similar to the one predicted in @fig-sdm-output. The results are presented in @fig-virtual-species.

#block[
#figure([
#box(image("index_files/figure-typst/appendix-virtualspecies-fig-virtual-species-output-1.png"))
], caption: figure.caption(
position: bottom, 
[
Virtual distribution for a hypothetical species with logistic response to the environment, as well as a sample of simulated occurrences. The prevalence of the virtual species is equivalent to the results in @fig-sdm-output. The code to produce this ﬁgure is available as Supp. Mat. 4.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-virtual-species>


]
Because the layers used by #strong[SDT] are broadcastable, we can rapidly apply a function (here, the logistic response to the environmental covariate) to each layer, and then multiply the suitabilities together. The last step is facilitated by the fact that most basic arithmetic operations are defined for layers, allowing for example to add, multiply, substract, and divide them by one another.

= Conclusion
<conclusion>
We have presented #strong[SpeciesDistributionToolkit];, a package for the #strong[Julia] programming language aiming to facilitate the collection, curation, analysis, and visualisation of data commonly used in species distribution modeling. Through the use of interfaces and a modular design, we have made this package robust to changes, easy to add functionalities to, and well integrated to the rest of the #strong[Julia] ecosystem. All code for the case studies can be found in Supp. Mat. 1-4.

Plans for active development of the package are focused on (i) additional techniques for pseudo-absence generations, likely leading to their separate component package, (ii) full compatibility with the #strong[MultivariateStatistics] and #strong[Clustering] packages for transformation and aggregation, and (iii) additional #strong[SDeMo] functionalities to allow cross-validation techniques with biologically relevant structure @Roberts2017.

#strong[Acknowledgements];: TP is funded by an NSERC Discovery grant, a Discovery Acceleration Supplement grant, and a Wellcome Trust grant (223764/Z/21/Z). MDC is funded by an IVADO Postdoctoral Fellowship.

 

#set bibliography(style: "springer-basic-author-date")


#bibliography("references.bib")

