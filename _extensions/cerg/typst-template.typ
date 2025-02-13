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
  set par(leading: 0.35em, hanging-indent: 3pt, justify: false)
  text(8pt, it)
}

    // show bibliography: set text(7pt)

  // Set the body font.
  set text(font: "Linux Libertine", size: 10pt)

  // Configure the page.
  set page(
    paper: paper-size,
    // The margins depend on the paper size.
    margin: if paper-size == "a4" {
      (x: 41.5pt, top: 80.51pt, bottom: 89.51pt)
    } else {
      (
        x: (50pt / 216mm) * 100%,
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

// Paragraph options
    set par(leading: 0.5em, first-line-indent: 0pt)
    show heading.where(level: 1): set text(rgb("#114f54"))
    show heading.where(level: 2): set text(rgb("#2e5385"))
    show heading.where(level: 1): set text(rgb("#114f54"))
          show heading.where(level: 2): set text(rgb("#2e5385"))
          show heading.where(level: 1): it => block(width: 100%)[
            #block(it.body)
          ]
          show heading.where(level: 2): it => text(
            style: "italic",
            weight: "regular",
            size: 10pt,
            it.body + [: ]
          )

  // Display the paper's title.
  text(18pt, weight: "medium", title)
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
  show: columns.with(2, gutter: 12pt)
  set par(justify: true, first-line-indent: 0em)
  show par: set block(spacing: 0.65em)

  // Display the paper's contents.
  body
}