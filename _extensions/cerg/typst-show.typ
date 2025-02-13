#show: CERG.with(
$if(title)$
  title: "$title$",
$endif$
$if(abstract)$
  abstract: [$abstract$],
$endif$
$if(by-author)$
    authors: (
        $for(by-author)$
            $if(it.name.literal)$
                (
                    name: "$it.name.literal$",
                    affiliations: [$for(it.affiliations)$$it.number$$sep$,$endfor$],
                    email: "$it.email$",
                    orcid: "$it.orcid$"
                ),
            $endif$
        $endfor$
    ),
$endif$
$if(by-affiliation)$
    affiliations: (
        $for(by-affiliation)$
            $if(it.name)$
                (
                    name: "$it.name$",
                    number: "$it.number$",
                ),
            $endif$
        $endfor$
    ),
$endif$
$if(keywords)$
  keywords: ($for(keywords)$"$it$"$sep$, $endfor$),
$endif$
)
