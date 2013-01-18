# Copyright (c) 2013 Sönke Rohde http://soenkerohde.com
# 
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the 'Software'), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

# L is a leightweight localization solution.
# The locales have to be provided in JSON format.
# Placeholders are supported using curly brackets like  
# `Hello {0}.`
class L

  # _private_ Default locale
  @_locale: "en"

  # `locales` Path the the locales JSON file.  
  # `callback` Callback function invoked when file is loaded.
  @initFile: (locales, callback) ->
    $.getJSON locales, (json) ->
      L.initJSON json
      callback json

  # `json` Locales in JSON format.
  @initJSON: (json) ->
    L._l = json

  # `locale` Locale identifier like "en" or "de"
  @changeLocale: (locale) ->
    L._locale = locale

  # `key` Key of the string to look up  
  # `args...` Placeholder values
  @get: (key, args...) ->
    keyValue = L._l[key]
    if keyValue?
      value = keyValue[L._locale]
      if args
        for arg, i in args
          value = value.replace "{#{i}}", args[i]
      return value
    return "#{key}???"

window?.L = L
module?.exports = L