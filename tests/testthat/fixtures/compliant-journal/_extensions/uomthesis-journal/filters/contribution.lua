-- contribution.lua
-- Renders {contribution="..."} attribute on H1 as a styled callout.
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
