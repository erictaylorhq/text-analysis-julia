# A Porter2 stemmer implimentation.
# See http://snowball.tartarus.org/algorithms/english/stemmer.html

module Porter2
export stem

# Define a vowel as one of following:

vowels = ["a", "e", "i", "o", "u", "y"]

# Define a double as one of following:

doubles = ["bb", "dd", "ff", "gg", "mm", "nn", "pp", "rr", "tt"]

# Define a valid li-ending as one of following:

validLi = ["c", "d", "e", "g", "h", "k", "m", "n", "r", "t"]

# excpetion1 handles special words (can be extended):

exception1 = Dict(
"skis" => "ski",
"skies" => "sky",
"dying" => "die",
"lying" => "lie",
"tying" => "tie",
"idly" => "idl",
"gently" => "gentl",
"ugly" => "ugli",
"early" => "earli",
"only" => "onli",
"singly" => "singl",
"sky" => "sky",
"news" => "news",
"howe" => "howe",
"atlas" => "atlas",
"cosmos" => "cosmos",
"bias" => "bias",
"andes" => "andes"
)

# excpetion2 prevents stemming the following words after step 1a (can be extended):

exception2 = ["inning", "outing", "canning", "herring", "earring", "proceed", "exceed", "succeed"]

# Remove apostrophe from beginning of word

function removeApostrophe(w::AbstractString)
  if startswith(w, "'")
    return w[1:end]
  else
    return w
  end
end

# Mark instances of y that are consonants by capitalizing them

function capitalizeY(w::AbstractString)
  m = matchall(r"[aeiou]y", w)
  if startswith(w, "y")
    return "Y"w[2:end]
  elseif length(m) > 1
    return replace(w, r"[aeiou]y", r"[aeiou]Y")
  else
    return w
  end
end

# Get index of first character in R1

function getR1(w::AbstractString)
  m = match(r"[aeiouy][^aeiouy]", w)
  if startswith(w, "gener") || startswith(w, "arsen")
    return 6
  elseif startswith(w, "commun")
    return 7
  elseif ismatch(r"[aeiouy][^aeiouy]", w)
    return searchindex(w, m.match)+2
  else
    return length(w)
  end
end

# Get index of first character in R2

function getR2(w::AbstractString)
  m = matchall(r"[aeiouy][^aeiouy]", w)
  l = length(w)
  r1 = getR1(w)
  if l == r1
    return r1
  elseif length(m) > 1
    s = m[2]
    return searchindex(w, m[2])+2
  elseif length(m) == 1
    return l
  end
end

function containsVowel(w::AbstractString)
  if contains(w, "a") || contains(w, "e") || contains(w, "i") || contains(w, "o") || contains(w, "u") || contains(w, "y")
    return true
  else
    return false
  end
end


#  Determines whether a word ends in a short syllable.
#  Define a short syllable in a word as either
#  (a) a vowel followed by a non-vowel other than w, x or Y and preceded by a
#      non-vowel
#  (b) a vowel at the beginning of the word followed by a non-vowel.

function endsShortSyl(w::AbstractString)
  l = length(w)
  if l >= 3
    if ismatch(r"[^aeiouy][aeiouy][^aeiouywxY]$", w)
      return true
    else
      return false
    end
  elseif l == 2
    if ismatch(r"^[aeiouy][^aeiouy]", w)
      return true
    end
  else
    return false
  end
end

# Remove apostrophe from ends of word

function step0(w::AbstractString)
  if endswith(w, "'s'")
    return w[1:end-3]
  elseif endswith(w, "'s")
    return w[1:end-2]
  elseif endswith(w, "'")
    return return w[1:end-1]
  end
  return w
end

# sses
#   replace by ss
# ied   ies
#   replace by i if preceded by more than one letter, otherwise by ie
#   (so ties -> tie, cries -> cri)
# us   ss
#   do nothing
# s
#   delete if the preceding word part contains a vowel not immediately before
#   the s (so gas and this retain the s, gaps and kiwis lose it)ted

function step1a(w::AbstractString)
  a = ["ied", "ies"]
  b = ["us", "ss"]
  if endswith(w, "sses")
    return w[1:end-2]
  elseif in(w[end-2:end], a)
    if length(w) >= 5
      return w[1:end-2]
    else
      return w[1:end-1]
    end
  elseif in(w[end-1:end], b)
    return w
  elseif endswith(w, "s") && !endswith(w, "sses")
    p = w[1:end-1]
    q = w[end-1]
    if q !="a" && q !="e" && q !="i" && q !="o" && q !="u" && q !="y"
      if ismatch(r"[aeiouy].", p)
        return p
      end
    end
  end
  return w
end

# eed   eedly
#    replace by ee if in R1
# ed   edly   ing   ingly
#    delete if the preceding word part contains a vowel, and after the
# deletion:
#    if the word ends at, bl or iz add e (so luxuriat -> luxuriate), or
#    if the word ends with a double remove the last letter (so hopp -> hop), or
#    if the word is short, add e (so hop -> hope)

function step1b(w::AbstractString)
  r1 = parse(Int, string(getR1(w)))
  l = length(w)
  if endswith(w, "ingly")
    m = 5
    p = w[1:end-m]
    q = w[end-m-1:end-m]
    if containsVowel(p)
      a = ["at", "bl", "iz"]
      x = w[1:end-m]
      if in(q, a)
        return string(x,"e")
      elseif in(q, doubles)
        return p[1:end-1]
      elseif r1 == length(p)+1 && endsShortSyl(p)
        return string(p,"e")
      else
        return p
      end
    end
  elseif endswith(w, "edly") && !endswith(w, "eedly")
    m = 4
    p = w[1:end-m]
    q = w[end-m-1:end-m]
    if containsVowel(p)
      a = ["at", "bl", "iz"]
      x = w[1:end-m]
      if in(q, a)
        return string(x,"e")
      elseif in(q, doubles)
        return p[1:end-1]
      elseif r1 == length(p)+1 && endsShortSyl(p)
        return string(p,"e")
      else
        return p
      end
    end
  elseif endswith(w, "ing")
    m = 3
    p = w[1:end-m]
    q = w[end-m-1:end-m]
    if containsVowel(p)
      a = ["at", "bl", "iz"]
      x = w[1:end-m]
      if in(q, a)
        return string(x,"e")
      elseif in(q, doubles)
        return p[1:end-1]
      elseif r1 == length(p)+1 && endsShortSyl(p)
        return string(p,"e")
      else
        return p
      end
    end
  elseif endswith(w, "ed") && !endswith(w, "eed")
    m = 2
    p = w[1:end-m]
    q = w[end-m-1:end-m]
    if containsVowel(p)
      a = ["at", "bl", "iz"]
      x = w[1:end-m]
      if in(q, a)
        return string(x,"e")
      elseif in(q, doubles)
        return p[1:end-1]
      elseif r1 == length(p)+1 && endsShortSyl(p)
        return string(p,"e")
      else
        return p
      end
    end
  elseif endswith(w, "eedly")
    if length(w) - 5 >= r1
      return w[1:end-3]
    end
  elseif endswith(w, "eed")
    if length(w) - 3 >= r1
      return w[1:end-1]
    end
  end
  return w
end

# Replace suffix y or Y by i if preceded by a non-vowel which is not the first
# letter of the word (so cry -> cri, by -> by, say -> say)

function step1c(w::AbstractString)
  l = length(w)
  if endswith(w, "y") || endswith(w, "Y")
    if l > 2
      if w[end-1] !='a' && w[end-1] !='e' && w[end-1] !='i' &&
        w[end-1] !='o' && w[end-1] !='u'
        return w[1:end-1]"i"
      end
    end
  end
  return w
end

step2_7Map = Dict(
"ization" => "ize",
"fulness" => "ful",
"ousness" => "ous",
"iveness" => "ive",
)

step2_6Map = Dict(
"lessli" => "less",
"biliti" => "ble"
)

step2_5Map = Dict(
"entli" => "ent",
"ousli" => "ous",
"fulli" => "ful",
"ation" => "ate",
"alism" => "al",
"aliti" => "al",
"iviti" => "ive"
)

step2_4Map = Dict(
"abli" => "able",
"alli" => "al",
"enci" => "ence",
"anci" => "ance",
"izer" => "ize",
"ator" => "ate"
)

#  If found and in R1, perform the action indicated.
#  tional:               replace by tion
#  enci:                 replace by ence
#  anci:                 replace by ance
#  abli:                 replace by able
#  entli:                replace by ent
#  izer, ization:        replace by ize
#  ational, ation, ator: replace by ate
#  alism, aliti, alli:   replace by al
#  fulness:              replace by ful
#  ousli, ousness:       replace by ous
#  iveness, iviti:       replace by ive
#  biliti, bli:          replace by ble
#  fulli:                replace by ful
#  lessli:               replace by less
#  ogi:                  replace by og if preceded by l
#  li:                   delete if preceded by a valid li-ending

function step2(w::AbstractString)
  l = length(w)
  r1 = parse(Int, string(getR1(w)))
  if endswith(w, "ization") || endswith(w, "fulness") || endswith(w, "ousness") || endswith(w, "iveness")
    s = w[end-6:end]
    v = get(step2_7Map, s, s)
    if l - 7 >= r1
      return string(w[1:end-7], v)
    end
  elseif endswith(w, "lessli") || endswith(w, "biliti")
    s = w[end-5:end]
    v = get(step2_6Map, s, s)
    if l - 6 >= r1
      return string(w[1:end-6], v)
    end
  elseif endswith(w, "entli") || endswith(w, "ousli") || endswith(w, "fulli") || endswith(w, "ation") || endswith(w, "alism") ||
    endswith(w, "aliti") || endswith(w, "iviti")
    s = w[end-4:end]
    v = get(step2_5Map, s, s)
    if l - 5 >= r1
      return string(w[1:end-5], v)
    end
  elseif endswith(w, "abli") || endswith(w, "alli") || endswith(w, "enci") || endswith(w, "anci") || endswith(w, "izer") ||
    endswith(w, "ator")
    s = w[end-3:end]
    v = get(step2_4Map, s, s)
    if l - 4 >= r1
      return string(w[1:end-4], v)
    end
  elseif endswith(w, "bli") && !endswith(w, "abli")
    if l - 3 >= r1
      return string(w[1:end-3], "ble")
    end
  elseif endswith(w, "ogi")
    if l - 3 >= r1
      if in(w[end-3], "l")
        return w[1:end-1]
      end
    end
  elseif endswith(w, "tional")
    if !endswith(w, "ational")
      if l - 6 >= r1
        return string(w[1:end-6], "tion")
      end
    elseif endswith(w, "ational")
      if l - 7 >= r1
        return string(w[1:end-7], "ate")
      end
    end
  elseif endswith(w, "li") && !endswith(w, "lessli") && !endswith(w, "entli") && !endswith(w, "ousli") && !endswith(w, "fulli") &&
    !endswith(w, "abli") && !endswith(w, "alli") && !endswith(w, "bli") && !endswith(w, "abli")
    if l - 2 >= r1
      c = string(w[end-2])
      if in(c, validLi)
        return w[1:end-2]
      end
    end
  end
  return w
end

step3_5Map = Dict(
"alize" => "al",
"icate" => "ic",
"iciti" => "ic"
)
step3_4Map = Dict(
"ical" => "ic",
"ness" => ""
)

#   If found and in R1, perform the action indicated.
#   ational:            replace by ate
#   tional:             replace by tion
#   alize:              replace by al
#   icate, iciti, ical: replace by ic
#   ful, ness:          delete
#   ative:              delete if in R2

function step3(w::AbstractString)
  l = length(w)
  r1 = parse(Int, string(getR1(w)))
  r2 = parse(Int, string(getR2(w)))
  if endswith(w, "alize") || endswith(w, "icate") || endswith(w, "iciti")
    s = w[end-4:end]
    v = get(step3_5Map, s, s)
    if l - 5 >= r1
      return string(w[1:end-5], v)
    end
  elseif endswith(w, "ical") || endswith(w, "ness")
    s = w[end-3:end]
    v = get(step3_4Map, s, s)
    if l - 4 >= r1
      return string(w[1:end-4], v)
    end
  elseif endswith(w, "ful")
    if l - 3 >= r1
      return string(w[1:end-3], "")
    end
  elseif endswith(w, "ative")
    if l - 5 >= r2
      return w[1:end-5]
    end
  elseif endswith(w, "tional")
    if !endswith(w, "ational")
      if l - 6 >= r1
        return string(w[1:end-6], "tion")
      end
    elseif endswith(w, "ational")
      if l - 7 >= r1
        return string(w[1:end-7], "ate")
      end
    end
  end
  return w
end

# If found and in R2, perform the action indicated.
#   al ance ence er ic able ible ant ement ment ent ism ate iti ous ive ize
#           delete
#   ion
#           delete if preceded by s or t

function step4(w::AbstractString)
  l = length(w)
  r2 = parse(Int, string(getR2(w)))
  if endswith(w, "ance") || endswith(w, "ence") || endswith(w, "able") || endswith(w, "ible")
    if l - 4 >= r2
      return string(w[1:end-4], "")
    end
  elseif endswith(w, "ant") || endswith(w, "ism") || endswith(w, "ate") || endswith(w, "iti") || endswith(w, "ous") ||
    endswith(w, "ive") || endswith(w, "ize")
    if l - 3 >= r2
      return string(w[1:end-3], "")
    end
  elseif endswith(w, "al") || endswith(w, "er") || endswith(w, "ic")
    if l - 2 >= r2
      return string(w[1:end-2], "")
    end
  elseif endswith(w,"ion")
    if l - 3 >= r2
      if is(w[end-3], "s")
        return w[1:end-3]
      elseif is(w[end-3], "t")
        return w[1:end-3]
      end
    end
  elseif endswith(w, "ent") && !endswith(w, "ment") && !endswith(w, "ement")
    if l - 3 >= r2
      return w[1:end-3]
    end
  elseif endswith(w, "ment") && !endswith(w, "ement")
    if l - 4 >= r2
      return w[1:end-4]
    end
  elseif endswith(w, "ement")
    if l - 5 >= r2
      return w[1:end-5]
    end
  end
  return w
end

# e     delete if in R2, or in R1 and not preceded by a short syllable
# l     delete if in R2 and preceded by l

function step5(w::AbstractString)
  l = length(w)
  r1 = parse(Int, string(getR1(w)))
  r2 = parse(Int, string(getR2(w)))
  p1 = w[1:end-r1]
  p2 = w[1:end-r2]
  if endswith(w, "l") && w[end-1] == "l"
    if l - 1 >= r2
      return w[1:end-1]
    end
  elseif endswith(w, "e")
    if l - 1 >= r1
      if !endsShortSyl(p1)
        return w[1:end-1]
      end
    elseif l - 1 >= r2
      if !endsShortSyl(p2)
        return w[1:end-1]
      end
    end
  end
  return w
end

# Return y to lowercase

function normalizeY(w::AbstractString)
  return replace(w, "Y", "y")
end

function stem(w::AbstractString)
  if length(w) <= 2
    return w
  elseif haskey(exception1, w)
    return get(exception1, w, w)
  else
    w = removeApostrophe(w)
    w = capitalizeY(w)
    w = step0(w)
    w = step1a(w)
    if in(w, exception2)
      w = normalizeY(w)
      return w
      exit()
    else
      w = step1b(w)
      w = step1c(w)
      w = step2(w)
      w = step3(w)
      w = step4(w)
      w = step5(w)
      w = normalizeY(w)
      return w
    end
  end
end
end
