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



#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: "linux libertine",
  fontsize: 11pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: "linux libertine",
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set page(
    paper: paper,
    margin: margin,
    numbering: "1",
  )
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)
  if title != none {
    align(center)[#block(inset: 2em)[
      #set par(leading: heading-line-height)
      #if (heading-family != none or heading-weight != "bold" or heading-style != "normal"
           or heading-color != black or heading-decoration == "underline"
           or heading-background-color != none) {
        set text(font: heading-family, weight: heading-weight, style: heading-style, fill: heading-color)
        text(size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(size: subtitle-size)[#subtitle]
        }
      } else {
        text(weight: "bold", size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(weight: "bold", size: subtitle-size)[#subtitle]
        }
      }
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none
)

#show: doc => article(
  title: [A Julia toolkit for species distribution data],
  authors: (
    ( name: [Timothée Poisot],
      affiliation: [Département de Sciences Biologiques, Université de Montréal, Montréal, Canada],
      email: [timothee.poisot\@umontreal.ca] ),
    ),
  lang: "en",
  region: "CA",
  abstract: [LATER],
  abstract-title: "Abstract",
  margin: (x: 1.8cm,y: 2cm,),
  paper: "us-letter",
  font: ("EB Garamond",),
  fontsize: 10pt,
  toc_title: [Table of contents],
  toc_depth: 3,
  cols: 2,
  doc,
)
#set par(leading: 0.5em)
#show heading.where(level: 1): set text(rgb("#114f54"))
#show heading.where(level: 2): set text(rgb("#2e5385"))
#show heading.where(level: 1): it => block(width: 100%)[
  #smallcaps(it.body)
]
#show heading.where(level: 2): it => text(
  style: "italic",
  weight: "regular",
  size: 11pt,
  it.body + [: ]
)

= Introduction
<introduction>
Species Distribution Models (SDMs) are one of the most effective predictive approach to study the global distribution of biodiversity @Elith2009. The training and evaluation of a SDM requires many steps, governing both its design and reporting @Zurell2020 and ultimate use and interpretation @Araujo2019. In the recent years, there has been an increase in the number of software packages and tools to assist ecologists with the development of species distribution models.

Because the practice of species distribution modeling and analysis usually involve many different data types, tools that can provide an integrated environment are important: many existing packages have been designed independently, and therefore may suffer when it comes to interoperability. In this manuscript, we present #strong[SpeciesDistributionToolkit] (abbreviated as #strong[SDT];), a meta-package for the #strong[Julia] programming language, offering an integrated environment for the retrieval, formatting, and interpretation of data relevant to the modeling of species distributions.

As #cite(<Kass2024-vy>, form: "prose") point out, this increase in the diversity of packages (most of them in the #strong[R] language) is a good thing, as it can accommodate multiple workflows, and contributes to the adoption of good practices in the field. Yet, #cite(<Kellner2025>, form: "prose") highlight that about 20% of publications for abundance or distribution models are not reproducible because of issues in package dependencies. A leading design consideration for #strong[SDT] was to prevent this issue from happening, both by relying on strict semantic versioning, but also through the use of interfaces rather dependencies between the components of #strong[SDT];.

The #strong[SDT] package is now used as part of the BON-in-a-Box project @Griffith2024, which seeks to facilitate the calculation and reporting of biodiversity indicators supporting the Kunming-Montréal Global Biodiversity Framework, to remove barriers to biodiversity data analysis @Gonzalez2023. In this manuscript, we describe (i) the high-level functionalities of the package, (ii) core design principles that facilitate long-term maintenance and development, and (iii) illustrative case studies with fully reproducible Jupyter notebooks.

= Application description
<application-description>
#strong[SpeciesDistributionToolkit] is released as a package for the #strong[Julia] programming language @Bezanson2017, licensed under the open-source initiative approved MIT license. It has evolved from a previous collection of packages to handle GBIF data @Dansereau2021, and now provides extended functionalities and improved performances. The package is registered in the #strong[Julia] package repository and can be downloaded and installed anonymously. It is compatible with version 1.8 and above. The full source and complete edition history is available at #link("https://github.com/PoisotLab/SpeciesDistributionToolkit.jl")[`https://github.com/PoisotLab/SpeciesDistributionToolkit.jl`];. This page additionally has a link to the documentation, containing a full reference for the package functions, a series of briefs how-to examples, and longer vignettes showcasing more integrative examples.

== Component packages
<component-packages>
An overview of the #strong[SDT] package is given in @fig-components. The project is organized as a "monorepo", in which multiple packages live. This allows expanding the scope of the package by moving functionalities into new component packages, without complexifying the installation process. As #strong[SDT] is registered in the #strong[Julia] package repository, it can be installed by using `add SpeciesDistributionToolkit` when in package mode at the #strong[Julia] prompt.

When loading the #strong[SDT] package with `using SpeciesDistributionToolkit`, all component packages are automatically and transparently loaded. Therefore, users do not need to know where a specific method or function resides to use it. In the next section, we discuss how this modular design ensure that we can grow the functionality of the toolkit over time, while maintaining strict backward compatibility #emph[and] allowing full reproducibility of an analysis.

#figure([
#box(image("figures/SDT.png"))
], caption: figure.caption(
position: bottom, 
[
Overview of the packages included in #strong[SpeciesDistributionToolkit];. The packages are color-coded by intended use, and their more specific content is presented in the main text. Note that because the package relies on #emph[interfaces] to facilitate code interoperability, there are only three dependency relationships.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-components>


The #strong[SDT] package primarily provides integration between the other packages, through the mechanism of method overloading, allowing to efficiently join packages together @Roesch2023. Additional functionalities that reside in the top-level package are the generation of pseudo-absences inspired by #cite(<Barbet-Massin2012>, form: "prose");, access to the `gadm.org` database, handling of polygon data and zonal statistics, and various quality of life methods. Because of the modular nature of the code, any of these functions can be transparently moved to their own packages in the future.

The #strong[SimpleSDMLayers] package offers a series of types to represent raster data in various projections, and a series of functions to operate on these layers. This package provides the main data representation for most functionalities that #strong[SDT] supports, and handles saving and loading data.

The #strong[OccurrencesInterface] is a light-weight package to provide a common interface for occurrence data. It implements abstract and concrete types to define a single occurrence and a collection thereof, and a series of methods allowing any occurrence data provider or data representation to become fully interoperable with the rest of #strong[SDT];. All #strong[SDT] methods that handle occurrence data do so through the #strong[OccurrencesInterface] interface, allowing future data sources to be integrated without the need for new code.

The #strong[GBIF] package offers access to the `gbif.org` streaming API @GBIF:TheGlobalBiodiversityInformationFacility2025, including the ability to retrieve, filter, and restart downloads. Although this package returns a rich data representation for occurrence data, all the objects it returns adhere to the #strong[OccurrencesInterface] interface.

#strong[SimpleSDMDatasets] implements an interface to retrieve and locally store raster data, which can be extended by users to support additional data sources. In addition, it offers access to a series of data sources, including the biodiversity mapping project @Jenkins2013, the EarthEnv collection for land cover @Tuanmu2014 and habitat heterogeneity @Tuanmu2015, Copernicus land cover 100m data @Buchhorn2020, the PaleoClim @Brown2018 data, the WorldClim 1 and 2 data @Fick2017 and their projections under various RCPs and SSP, and part of the CHELSA 1 and 2 data @Karger2017 and their projections under various RCPs and SSPs.

#strong[Phylopic] offers a wrapper around the `phylopic.org` API to download silhouettes for taxonomic entities. It also provides utilities for citation of the downloaded images. Its functionalities are similar to the #strong[rphylopic] package @Gearty2023.

The #strong[Fauxcurrences] packages is inspired by the work of #cite(<Osborne2022>, form: "prose");, and allows generating a series of simulated occurrence data that have the same statistical structure as observed ones. The package supports multi-species data, with user-specified relative weight of intra and inter-specific distances conservation.

The #strong[SDeMo] package is aimed at providing tools to use as part of training and education material on species distribution modeling. By providing a series of data transformation (PCA, Whitening, z-score) and classifiers (BIOCLIM, Naive Bayes, and decision trees), it offers the basic elements to demonstrate training and evaluation of SDMs, as well as techniques related to ensembles and bagging. In addition, to promote the use of interpretable techniques, the package supports regular @Elith2005 and inflated @Zurell2012 partial responses, as well as the calculation and mapping of Shapley values @Wadoux2023@Mesgaran2014, and the generation of counterfactuals @VanLooveren2019[#cite(<Karimi2019>, form: "prose");].

== Software information
<software-information>
#strong[SDT] uses the built-in #strong[Julia] package manager to ensure that the version of all dependencies are kept up to date. Furthermore, we use strict semantic versioning: major versions correspond to no breaking changes in user-developped code, minor versions increase with additional functionalities, and patch releases cover minor bug fixes or documentation changes. All packages have a #emph[CHANGELOG] file, which documents what changes are included in each release. Following a constructive cost model analysis @Kemerer1987 of the version described in this publication, the package represents approx. 11k lines of active code (no blank lines, no comments), for an estimated development cost of approx. 325k USD.

This strict reliance on semantic versioning solves the issues of maintaining compatibility when new functionalities are added: all releases in the #emph[v1.x.x] branch of #strong[SDT] depend on component packages in their respective #emph[v1.x.x] branch, and users can benefit from now functionalities without risking to break existing code. This behavior is extensively tested, both using unit tests, and through integration testing generated as part of the online documentation.

#cite(<Kellner2025>, form: "prose") reported that about 20% of failures to reproduce species distribution or abundance modeling code was related to package issues. The strict reliance on semantic versioning, alongside technical choices in the #strong[Julia] package manager and repository, means that it is possible to specify the full version of all dependencies used in a project, which addresses this important obstacle to reproducibility.

== Integration with other packages
<integration-with-other-packages>
The #strong[SDT] package benefits from close integration with other packages in the #strong[Julia] universe. Notably, this includes #strong[Makie] (and all related backends) for plotting and interactive data visualisation, where usual plot types are overloaded for both layer and occurrence data. Most data handled by #strong[SDT] can be exported using the #strong[Tables] interface, which allows data to be consumed by other packages like #strong[DataFrames] and #strong[MLJ];, or directly saved as csv files.

Interfaces internal to #strong[Julia] are also implemented whenever they make sense. In particular, #strong[SimpleSDMLayers] objects behave like arrays, are iterable, and broadcastable; objects from #strong[OccurrencesInterface] behave as arrays and are similarly iterable. The #strong[SDeMo] package relies on part of the #strong[StatsAPI] interface, allowing to easily define new data transformation and classifier types to support additional features.

Achieving integration with other packages through method overloading and the adherence to well-established interfaces is important, as it increases the chances that additional functionalities external to #strong[SDT] can be used directly or fully supported with minimal addition of code.

= Illustrative case studies
<illustrative-case-studies>
In this section, we provide a series of case studies, meant to illustrate the use of the package. The on-line documentation offers longer tutorials, as well as a series of how-to vignettes to illustrate the full scope of what the package allows. The code for each of these case studies is available as fully independent Jupyter notebooks, forming the supplementary material of this article. The example we use throughout is the distribution of #emph[Akodon montensis] (Rodentia, family Cricetidae), a host or orthohantaviruses @Burgos2021@Owen2010, in Paraguay. As the notebooks accompanying this article cover the full code required to run these case studies, we do not present code snippets in the main text, and instead focus on explaining which component packages are used in each example.

== Landcover consensus map
<landcover-consensus-map>
In this case study, we retrieve the land cover data from #cite(<Tuanmu2014>, form: "prose");, clip them to a GeoJSON polygon describing the country of Paraguay (#strong[SDT] can download data directly from `gadm.org`), and apply the `mosaic` operation to figure out which class is the most locally abundant. This case study uses the #strong[SimpleSDMDatasets] package to download (and locally cache) the raster data, as well as the #strong[SimpleSDMLayers] package to provide basic utility functions on raster data.

#block[
#figure([
#box(image("index_files/figure-typst/appendix-consensus-fig-landcover-consensus-output-1.png"))
], caption: figure.caption(
position: bottom, 
[
yeah
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-landcover-consensus>


]
== Using data from GBIF
<using-data-from-gbif>
@Karger2017

#block[
#figure([
#box(image("index_files/figure-typst/appendix-gbif-fig-gbif-phylopic-output-1.png"))
], caption: figure.caption(
position: bottom, 
[
yeah
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-gbif-phylopic>


]
In practice, although the data are retrieved using the #strong[GBIF] package, they are used internally by #strong[SDT] through the #strong[OccurrencesInterface] package. This package defines a small convention to handle georeferenced occurrence data, and allows to transparently integrate additional occurrence sources. By defining five methods for a custom data type, users can plug-in any occurrence data source and enjoy full compatibility with the entire #strong[SDT] functionalities.

== Training a species distribution model
<training-a-species-distribution-model>
@Bagnall2018

#block[
#figure([
#box(image("index_files/figure-typst/appendix-sdm-fig-sdm-output-output-1.png"))
], caption: figure.caption(
position: bottom, 
[
also yeah
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-sdm-output>


]
== Generating the distribution of a virtual species
<generating-the-distribution-of-a-virtual-species>
@Leroy2016

#block[
#figure([
#box(image("index_files/figure-typst/appendix-virtualspecies-fig-virtual-species-output-1.png"))
], caption: figure.caption(
position: bottom, 
[
yeah
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-virtual-species>


]
= References
<references>




#bibliography("references.bib")

