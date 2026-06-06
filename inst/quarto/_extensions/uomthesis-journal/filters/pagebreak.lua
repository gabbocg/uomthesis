-- Force a \newpage before any "References" or "Appendices" section
-- heading. In the journal format each paper chapter ends with these two
-- sections; readers expect them on a fresh page rather than continuing
-- the body of the chapter.
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
  if el.level ~= 2 then
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
