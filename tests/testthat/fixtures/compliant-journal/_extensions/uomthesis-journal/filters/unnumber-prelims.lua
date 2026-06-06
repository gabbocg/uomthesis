-- unnumber-prelims.lua
--
-- Quarto book mode renders every chapter file as a numbered `\chapter{Title}`
-- in LaTeX, even chapters with `unnumbered: true` in YAML. This filter walks
-- the document AST and rewrites two cases:
--
-- 1. Headers whose title matches a known *unnumbered* preliminary heading
--    (Abstract, Declaration of originality, Copyright statement,
--    Acknowledgements, Dedication, etc.) become raw LaTeX
--    `\chapter*{Title}` plus an explicit `\addcontentsline{toc}{chapter}{Title}`
--    so the entry still appears in the table of contents without a number.
--
-- 2. Headers whose title matches a *suppressed* heading ("Preface", from
--    the Quarto-mandatory `index.qmd` home page that only exists to hold
--    project metadata) are removed entirely. The chapter heading does not
--    appear in the body or in the TOC.

local unnumber_titles = {
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

local suppress_titles = {
  ["Preface"] = true,
}

local function escape_lua_pattern(s)
  return (s:gsub("([().%+%-%*%?%[%]%^%$])", "%%%1"))
end

function Header(el)
  if FORMAT ~= 'latex' and not FORMAT:match('latex') then return nil end
  if el.level ~= 1 then return nil end
  local txt = pandoc.utils.stringify(el.content)
  if suppress_titles[txt] then
    -- Drop the chapter heading entirely.
    return {}
  end
  if unnumber_titles[txt] then
    return pandoc.RawBlock('latex',
      "\\chapter*{" .. txt .. "}\n" ..
      "\\addcontentsline{toc}{chapter}{" .. txt .. "}")
  end
end

function RawBlock(el)
  if FORMAT ~= 'latex' and not FORMAT:match('latex') then return nil end
  if el.format ~= 'tex' and el.format ~= 'latex' then return nil end
  local new_text = el.text
  local changed = false
  -- Suppression: drop `\chapter{Preface}` (and any line containing it).
  for title, _ in pairs(suppress_titles) do
    local pattern = "\\chapter%{" .. escape_lua_pattern(title) .. "%}"
    local stripped, n = new_text:gsub(pattern, "")
    if n > 0 then
      new_text = stripped
      changed = true
    end
  end
  -- Unnumbering: rewrite known prelim chapter commands.
  for title, _ in pairs(unnumber_titles) do
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
