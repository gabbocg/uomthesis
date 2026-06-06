-- contribution.lua
-- Renders a contribution statement as a styled callout. Two ways to mark one:
--   1. A Div with class "contribution":
--        ::: {.contribution}
--        I designed the study, ...
--        :::
--      This is the recommended form for Quarto book chapters because it
--      doesn't generate a phantom chapter heading.
--   2. An H1 with a {contribution="..."} attribute (legacy support).

function Div(el)
  if not el.classes:includes("contribution") then return nil end
  if FORMAT:match 'latex' then
    local stmt = pandoc.utils.stringify(el.content)
    return pandoc.RawBlock('latex',
      '\\begin{tcolorbox}[title=Contribution statement,breakable]'
      .. stmt .. '\\end{tcolorbox}')
  elseif FORMAT:match 'html' then
    return pandoc.Div(el.content,
                      pandoc.Attr('', {'contribution-statement'}, {}))
  end
  return nil
end

function Header(el)
  if el.level ~= 1 then return nil end
  local stmt = el.attributes["contribution"]
  if not stmt or stmt == "" then return nil end
  if FORMAT:match 'latex' then
    return {
      el,
      pandoc.RawBlock('latex',
        '\\begin{tcolorbox}[title=Contribution statement,breakable]'
        .. stmt .. '\\end{tcolorbox}')
    }
  elseif FORMAT:match 'html' then
    return {
      el,
      pandoc.Div({ pandoc.Para(stmt) },
                 { class = "contribution-statement" })
    }
  end
  return nil
end
