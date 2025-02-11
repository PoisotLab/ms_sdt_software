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
#show heading: set text(gray)

= Introduction
<introduction>
Species Distribution Models (SDMs) are one of the most effective predictive approach to study the global distribution of biodiversity (Elith and Leathwick 2009). The training and evaluation of a SDM requires many steps, governing both its design and reporting (Zurell et al. 2020) and ultimate use and interpretation (Araújo et al. 2019). In the recent years, there has been an increase in the number of software packages and tools to assist ecologists with the development of species distribution models. As Kass et al. (2024) point out, this increase in the diversity of packages (most of them in the #strong[R] language) is a good thing, as it can accommodate multiple workflows, and contributes to the adoption of good practices in the field.

Because the practice of species distribution modeling and analysis usually involve many different data types, tools that can provide an integrated environment are important: many existing packages have been designed independently, and therefore may suffer when it comes to interoperability. In this manuscript, we present #strong[SpeciesDistributionToolkit] (abbreviated as #strong[SDT];), a meta-package for the #strong[Julia] programming language, offering an integrated environment for the retrieval, formatting, and interpretation of data relevant to the modeling of species distributions.

previous pub Dansereau and Poisot (2021)

Griffith et al. (2024) for large-scale SDM

= Application description
<application-description>
#strong[SpeciesDistributionToolkit] is released as a package for the #strong[Julia] programming language, licensed under the open-source initiative approved MIT license. The package is registered in the #strong[Julia] package repository and can be downloaded and installed anonymously. The full source and complete edition history is available at #link("https://github.com/PoisotLab/SpeciesDistributionToolkit.jl")[`https://github.com/PoisotLab/SpeciesDistributionToolkit.jl`];. This page has a link to the documentation, containing a full reference for the package functions, a series of briefs how-to examples, and longer vignettes showcasing more integrative examples.

== Component packages
<component-packages>
An overview of the #strong[SDT] package is given in @fig-components. The project is organized as a "monorepo", in which multiple packages live. This allows expanding the scope of the package by moving functionalities into new component packages, without complexifying the installation process. As #strong[SDT] is registered in the #strong[Julia] package repository, it can be installed with:

```julia
import Pkg; Pkg.add("SpeciesDistributionToolkit")
```

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


#strong[GBIF]

#strong[SimpleSDMDatasets]

#strong[Phylopic]

#strong[OccurrencesInterface]

#strong[SimpleSDMLayers]

The #strong[Fauxcurrences] packages is inspired by the work of Osborne et al. (2022), and

#strong[SDeMo]

== Software information
<software-information>
#strong[SDT] uses the built-in #strong[Julia] package manager to ensure that the version of all dependencies are kept up to date. Furthermore, we use strict semantic versioning: major versions correspond to no breaking changes in user-developped code, minor versions increase with additional functionalities, and patch releases cover minor bug fixes or documentation changes. All packages have a #emph[CHANGELOG] file, which documents what changes are included in each release.

This strict reliance on semantic versioning solves the issues of maintaining compatibility when new functionalities are added: all releases in the #emph[v1.x.x] branch of #strong[SDT] depend on component packages in their respective #emph[v1.x.x] branch, and users can benefit from now functionalities without risking to break existing code. This behavior is extensively tested, both using unit tests, and through integration testing generated as part of the online documentation.

Kellner, Doser, and Belant (2025) reported that about 20% of failures to reproduce species distribution or abundance modeling code was related to package issues. The strict reliance on semantic versioning, alongside technical choices in the #strong[Julia] package manager and repository, means that it is possible to specify the full version of all dependencies used in a project, which addresses this important obstacle to reproducibility.

== Integration with other packages
<integration-with-other-packages>
The #strong[SDT] package benefits from close integration with other packages in the Julia universe. Notably, this includes #strong[Makie] (and all related backends) for plotting and data visualisation, where usual plot types are overloaded for layer and occurrence data. Most data can be exported using the #strong[Tables] interface, which allows data to be consumed by other packages like #strong[DataFrames] and #strong[MLJ];. Interfaces internal to Julia are also implemented whenever they make sense. Layers behave like arrays, are iterable, and broadcastable; occurrences collections are arrays and iterables.

Beyond supporting external interfaces, #strong[SDT] defines its own internally. Access to raster data is supported by a trait-based interface for #strong[SimpleSDMDatasets];.

Internal use of other interfaces like #strong[StatsAPI] in #strong[SDeMo]

one of the component packages (#strong[OccurrencesInterface];) implements a minimalist interface to facilite the consumption of occurrence data.

= Illustrative case studies
<illustrative-case-studies>
In this section, we provide a series of case studies, meant to illustrate the use of the package. The on-line documentation offers longer tutorials, as well as a series of how-to vignettes to illustrate the full scope of what the package allows. The code for each of these case studies is available as fully independent Jupyter notebooks, forming the supplementary material of this article. The example we use throughout is the distribution of #emph[Akodon montensis] (Rodentia, family Cricetidae), and a host or orthohantaviruses (Burgos et al. 2021; Owen et al. 2010), in Paraguay. As the notebooks accompanying this article cover the full code required to run these examples, we do not present code snippets in the main text, and instead focus on explaining which component packages are used in each example.

== Landcover consensus map
<landcover-consensus-map>
In this case study, we retrieve the land cover data from Tuanmu and Jetz (2014), clip them to a GeoJSON polygon describing the country of Paraguay (#strong[SDT] can download data directly from `gadm.org`), and apply the `mosaic` operation to figure out which class is the most locally abundant. This case study uses the #strong[SimpleSDMDatasets] package to download (and locally cache) the raster data, as well as the #strong[SimpleSDMLayers] package to provide basic utility functions on raster data.

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
(GBIF: The Global Biodiversity Information Facility 2025)

(Karger et al. 2017)

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
(Bagnall et al. 2018)

PA routines from Barbet-Massin et al. (2012)

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
(Leroy et al. 2016)

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
#heading(level: 1, numbering: none)[References]
<references>
#block[
#block[
Araújo, Miguel B, Robert P Anderson, A Márcia Barbosa, Colin M Beale, Carsten F Dormann, Regan Early, Raquel A Garcia, et al. 2019. “Standards for Distribution Models in Biodiversity Assessments.” #emph[Science Advances] 5 (January): eaat4858. #link("https://doi.org/10.1126/sciadv.aat4858");.

] <ref-Araujo2019>
#block[
Bagnall, A, M Flynn, J Large, J Line, A Bostrom, and G Cawley. 2018. “Is Rotation Forest the Best Classifier for Problems with Continuous Features?” #emph[arXiv \[Cs.LG\]];, September.

] <ref-Bagnall2018>
#block[
Barbet-Massin, Morgane, Frédéric Jiguet, Cécile Hélène Albert, and Wilfried Thuiller. 2012. “Selecting Pseudo‐absences for Species Distribution Models: How, Where and How Many?: How to Use Pseudo-Absences in Niche Modelling?” #emph[Methods in Ecology and Evolution] 3 (April): 327–38. #link("https://doi.org/10.1111/j.2041-210x.2011.00172.x");.

] <ref-Barbet-Massin2012>
#block[
Burgos, E F, M V Vadell, C M Bellomo, V P Martinez, O D Salomon, and I E Gómez Villafañe. 2021. “First Evidence of Akodon-Borne Orthohantavirus in Northeastern Argentina.” #emph[EcoHealth] 18 (December): 429–39. #link("https://doi.org/10.1007/s10393-021-01564-6");.

] <ref-Burgos2021>
#block[
Dansereau, Gabriel, and Timothée Poisot. 2021. “SimpleSDMLayers.jl and GBIF.jl: A Framework for Species Distribution Modeling in Julia.” #emph[Journal of Open Source Software] 6 (January): 2872. #link("https://doi.org/10.21105/joss.02872");.

] <ref-Dansereau2021>
#block[
Elith, Jane, and John R Leathwick. 2009. “Species Distribution Models: Ecological Explanation and Prediction Across Space and Time.” #emph[Annual Review of Ecology, Evolution, and Systematics] 40 (December): 677–97. #link("https://doi.org/10.1146/annurev.ecolsys.110308.120159");.

] <ref-Elith2009>
#block[
GBIF: The Global Biodiversity Information Facility. 2025. “#emph[What Is GBIF?];” 2025.

] <ref-GBIF:TheGlobalBiodiversityInformationFacility2025>
#block[
Griffith, Jory, Jean-Michel Lord, Michael D Catchen, Maria Isabel Arce-Plata, Manuel Fernandez Galvez Bohorquez, Matusan Chandramohan, María Camilla Diaz-Corzo, et al. 2024. “BON in a Box: An Open and Collaborative Platform for Biodiversity Monitoring, Indicator Calculation, and Reporting,” October. #link("https://doi.org/10.32942/X2M320");.

] <ref-Griffith2024>
#block[
Karger, Dirk Nikolaus, Olaf Conrad, Jürgen Böhner, Tobias Kawohl, Holger Kreft, Rodrigo Wilber Soria-Auza, Niklaus E Zimmermann, H Peter Linder, and Michael Kessler. 2017. “Climatologies at High Resolution for the Earth’s Land Surface Areas.” #emph[Scientific Data] 4 (September): 170122. #link("https://doi.org/10.1038/sdata.2017.122");.

] <ref-Karger2017>
#block[
Kass, Jamie M, Adam B Smith, Dan L Warren, Sergio Vignali, Sylvain Schmitt, Matthew E Aiello-Lammens, Eduardo Arlé, et al. 2024. “Achieving Higher Standards in Species Distribution Modeling by Leveraging the Diversity of Available Software.” #emph[Ecography];, November. #link("https://doi.org/10.1111/ecog.07346");.

] <ref-Kass2024-vy>
#block[
Kellner, Kenneth F, Jeffrey W Doser, and Jerrold L Belant. 2025. “Functional R Code Is Rare in Species Distribution and Abundance Papers.” #emph[Ecology] 106 (January): e4475. #link("https://doi.org/10.1002/ecy.4475");.

] <ref-Kellner2025>
#block[
Leroy, Boris, Christine N Meynard, Céline Bellard, and Franck Courchamp. 2016. “Virtualspecies, an R Package to Generate Virtual Species Distributions.” #emph[Ecography] 39 (June): 599–607. #link("https://doi.org/10.1111/ecog.01388");.

] <ref-Leroy2016>
#block[
Osborne, Owen G, Henry G Fell, Hannah Atkins, Jan van Tol, Daniel Phillips, Leonel Herrera-Alsina, Poppy Mynard, et al. 2022. “Fauxcurrence: Simulating Multi‐species Occurrences for Null Models in Species Distribution Modelling and Biogeography.” #emph[Ecography] 2022 (July): e05880. #link("https://doi.org/10.1111/ecog.05880");.

] <ref-Osborne2022>
#block[
Owen, Robert D, Douglas G Goodin, David E Koch, Yong-Kyu Chu, and Colleen B Jonsson. 2010. “Spatiotemporal Variation in Akodon Montensis (Cricetidae: Sigmodontinae) and Hantaviral Seroprevalence in a Subtropical Forest Ecosystem.” #emph[Journal of Mammalogy] 91 (April): 467–81. #link("https://doi.org/10.1644/09-MAMM-A-152.1");.

] <ref-Owen2010>
#block[
Tuanmu, Mao-Ning, and Walter Jetz. 2014. “A Global 1‐km Consensus Land‐cover Product for Biodiversity and Ecosystem Modelling: Consensus Land Cover.” #emph[Global Ecology and Biogeography: A Journal of Macroecology] 23 (September): 1031–45. #link("https://doi.org/10.1111/geb.12182");.

] <ref-Tuanmu2014>
#block[
Zurell, Damaris, Janet Franklin, Christian König, Phil J Bouchet, Carsten F Dormann, Jane Elith, Guillermo Fandos, et al. 2020. “A Standard Protocol for Reporting Species Distribution Models.” #emph[Ecography] 43 (September): 1261–77. #link("https://doi.org/10.1111/ecog.04960");.

] <ref-Zurell2020>
] <refs>



