-- unnumber-prelims.lua
--
-- Quarto book mode renders every chapter file as a numbered `\chapter{Title}`
-- in LaTeX even when the chapter YAML declares `unnumbered: true` -- the
-- per-chapter metadata doesn't reach Pandoc filters because Quarto assembles
-- the entire book into one Pandoc document.
--
-- This filter walks the AST and rewrites any level-1 Header whose plain-text
-- content matches a known preliminary heading. The replacement is a raw
-- LaTeX block emitting `\chapter*{Title}` (no number) plus an explicit
-- `\addcontentsline{toc}{chapter}{Title}` so the entry still appears in
-- the table of contents -- without a number.
--
-- It also handles the case where the chapter title comes through as a
-- RawBlock containing `\chapter{Title}` (some Quarto/Pandoc pipelines emit
-- that form directly), by performing a string substitution.

local prelim_titles = {
  ["Preface"]                    = true,
  ["List of publications"]       = true,
  ["List of Publications"]       = true,
  ["Abstract"]                   = true,
  ["Declaration of originality"] = true,
  ["Declaration of Originality"] = true,
  ["Copyright statement"]        = true,
  ["Copyright Statement"]        = true,
  ["Acknowledgements"]           = true,
  ["Acknowledgments"]            = true,
  ["Dedication"]                 = true,
  ["Lay abstract"]               = true,
  ["Lay Abstract"]               = true,
}

local function escape_lua_pattern(s)
  return (s:gsub("([().%+%-%*%?%[%]%^%$])", "%%%1"))
end

local function is_prelim_title(t)
  return prelim_titles[t] == true
end

function Header(el)
  if FORMAT ~= 'latex' and not FORMAT:match('latex') then return nil end
  if el.level ~= 1 then return nil end
  local txt = pandoc.utils.stringify(el.content)
  if not is_prelim_title(txt) then return nil end
  -- Replace this Header with a raw LaTeX `\chapter*{}` plus a TOC entry.
  return pandoc.RawBlock('latex',
    "\\chapter*{" .. txt .. "}\n" ..
    "\\addcontentsline{toc}{chapter}{" .. txt .. "}")
end

function RawBlock(el)
  if FORMAT ~= 'latex' and not FORMAT:match('latex') then return nil end
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
