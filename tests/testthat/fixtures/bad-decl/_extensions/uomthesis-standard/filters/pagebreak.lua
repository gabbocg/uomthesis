-- Force a \newpage before any "References" or "Appendices" section
-- heading. In the monograph (standard) format the thesis-wide bibliography
-- and any appendices should each start on a fresh page rather than
-- continuing on from the body text.
--
-- Only runs for LaTeX (PDF) output.

local pagebreak_titles = {
  ["References"] = true,
  ["Appendices"] = true,
}

function Header(el)
  if FORMAT ~= 'latex' and not FORMAT:match('latex') then
    return nil
  end
  if el.level ~= 1 and el.level ~= 2 then
    return nil
  end
  local txt = pandoc.utils.stringify(el.content)
  if pagebreak_titles[txt] then
    return {
      pandoc.RawBlock('latex', '\\newpage'),
      el,
    }
  end
end
