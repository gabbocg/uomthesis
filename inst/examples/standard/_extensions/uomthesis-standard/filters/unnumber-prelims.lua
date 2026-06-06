-- unnumber-prelims.lua
--
-- Quarto book mode renders every chapter file as `\chapter{Title}` in
-- LaTeX, including ones marked `unnumbered: true` in the chapter YAML --
-- the per-chapter metadata doesn't reach Pandoc filters because Quarto
-- assembles the entire book into one Pandoc document.
--
-- This filter walks the post-Quarto LaTeX output and rewrites any
-- `\chapter{Title}` whose title matches a known preliminary heading to
-- `\chapter*{Title}` plus an explicit `\addcontentsline{toc}{chapter}{Title}`.
-- The result: prelims appear in the TOC without chapter numbers, and the
-- main-body chapter counter starts at 1 with the first numbered chapter.

local prelim_titles = {
  ["Preface"]                  = true,
  ["List of publications"]     = true,
  ["List of Publications"]     = true,
  ["Abstract"]                 = true,
  ["Declaration of originality"] = true,
  ["Declaration of Originality"] = true,
  ["Copyright statement"]      = true,
  ["Copyright Statement"]      = true,
  ["Acknowledgements"]         = true,
  ["Acknowledgments"]          = true,
  ["Dedication"]               = true,
  ["Lay abstract"]             = true,
  ["Lay Abstract"]             = true,
}

local function escape_lua_pattern(s)
  return (s:gsub("([().%+%-%*%?%[%]%^%$])", "%%%1"))
end

function Pandoc(doc)
  if FORMAT ~= 'latex' and not FORMAT:match('latex') then return nil end

  doc.blocks = doc.blocks:walk({
    RawBlock = function(el)
      if el.format ~= 'tex' and el.format ~= 'latex' then return nil end
      local new_text = el.text
      local changed = false
      for title, _ in pairs(prelim_titles) do
        local pattern = "\\chapter%{" .. escape_lua_pattern(title) .. "%}"
        local replacement = "\\chapter*{" .. title .. "}\n" ..
                            "\\addcontentsline{toc}{chapter}{" .. title .. "}"
        local replaced, n = new_text:gsub(pattern, replacement)
        if n > 0 then
          new_text = replaced
          changed = true
        end
      end
      if changed then
        return pandoc.RawBlock(el.format, new_text)
      end
    end
  })

  return doc
end
