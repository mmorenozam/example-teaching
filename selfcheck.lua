-- Turns ::: {.selfcheck} divs into interactive multiple-choice questions.
-- Inside the div: the question (any blocks), then a task list where
-- "- [x]" marks the correct option, then an optional ::: {.explanation} div.

local counter = 0

local function to_html(inlines)
  local html = pandoc.write(pandoc.Pandoc({ pandoc.Plain(inlines) }), "html")
  return (html:gsub("%s+$", ""))
end

function Div(el)
  if not el.classes:includes("selfcheck") then
    return nil
  end
  if not quarto.doc.is_format("html") then
    return nil
  end

  counter = counter + 1
  local id = "sc-" .. counter
  local before, after, options = pandoc.List(), pandoc.List(), {}
  local found = false

  for _, blk in ipairs(el.content) do
    if not found and blk.t == "BulletList" then
      found = true
      for i, item in ipairs(blk.content) do
        local inl = pandoc.List(item[1].content)
        local correct = false
        if inl[1] and inl[1].t == "Str" and (inl[1].text == "☒" or inl[1].text == "☐") then
          correct = (inl[1].text == "☒")
          inl:remove(1)
          if inl[1] and inl[1].t == "Space" then inl:remove(1) end
        end
        table.insert(options, string.format(
          '<label class="sc-option"><input type="radio" name="%s" value="%d" data-correct="%s"><span>%s</span></label>',
          id, i, tostring(correct), to_html(inl)))
      end
    elseif found then
      after:insert(blk)
    else
      before:insert(blk)
    end
  end

  local out = pandoc.List()
  out:insert(pandoc.RawBlock("html", '<div class="selfcheck" id="' .. id .. '">'))
  out:extend(before)
  out:insert(pandoc.RawBlock("html",
    '<div class="sc-options">' .. table.concat(options, "\n") .. '</div>' ..
    '<button type="button" class="sc-check">Check answer</button>' ..
    '<p class="sc-result" aria-live="polite"></p>'))
  out:insert(pandoc.Div(after, pandoc.Attr("", { "sc-explanation" })))
  out:insert(pandoc.RawBlock("html", "</div>"))
  return out
end
