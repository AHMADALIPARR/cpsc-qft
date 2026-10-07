# *******************************************************************************
# Copyright (c) 2026 Ahmad Ali Parr and others.
#
# This program and the accompanying materials are made available under the
# terms of the CPSC Eclipse Strict Copyleft License, Version 1.0, which is
# available in LICENSES/CPSC-ESCL-1.0.txt, or, at your option, under the
# GNU Affero General Public License, Version 3 only, which is available in
# LICENSES/AGPL-3.0.txt. Both options are strict copyleft. There is no
# classpath exception and no permissive relicensing.
#
# SPDX-License-Identifier: LicenseRef-CPSC-ESCL-1.0 OR AGPL-3.0-only
# *******************************************************************************

# Minimal JSON parser/generator covering exactly what the Mercury web
# bridge needs (objects, arrays, strings, numbers, booleans, null).
# Pure Ruby, no dependencies — safe inside Ruby WASM.
module Mercury
  module MiniJSON
    class ParseError < StandardError; end

    def self.parse(str)
      @src = str
      @pos = 0
      skip_ws
      val = parse_value
      skip_ws
      raise ParseError, "trailing data at #{@pos}" unless @pos == @src.length
      val
    end

    def self.generate(obj)
      case obj
      when Hash
        "{" + obj.map { |k, v| "#{generate(k.to_s)}:#{generate(v)}" }.join(",") + "}"
      when Array
        "[" + obj.map { |v| generate(v) }.join(",") + "]"
      when String
        '"' + obj.gsub(/["\\\b\f\n\r\t]/) { |m| { '"' => '\\"', '\\' => '\\\\', "\b" => '\\b', "\f" => '\\f', "\n" => '\\n', "\r" => '\\r', "\t" => '\\t' }[m] } + '"'
      when Integer, Float
        raise ParseError, "non-finite number" if obj.is_a?(Float) && !obj.finite?
        obj.to_s
      when true then "true"
      when false then "false"
      when nil then "null"
      else
        raise ParseError, "cannot serialize #{obj.class}"
      end
    end

    def self.skip_ws
      @pos += 1 while @pos < @src.length && @src[@pos] =~ /\s/
    end

    def self.parse_value
      case @src[@pos]
      when '"' then parse_string
      when "{" then parse_object
      when "[" then parse_array
      when "t" then literal("true", true)
      when "f" then literal("false", false)
      when "n" then literal("null", nil)
      else parse_number
      end
    end

    def self.literal(word, val)
      raise ParseError, "bad literal at #{@pos}" unless @src[@pos, word.length] == word
      @pos += word.length
      val
    end

    def self.parse_string
      @pos += 1 # opening quote
      out = +""
      while @pos < @src.length
        ch = @src[@pos]
        case ch
        when '"'
          @pos += 1
          return out
        when "\\"
          @pos += 1
          esc = @src[@pos]
          out << case esc
                 when '"' then '"'
                 when "\\" then "\\"
                 when "/" then "/"
                 when "b" then "\b"
                 when "f" then "\f"
                 when "n" then "\n"
                 when "r" then "\r"
                 when "t" then "\t"
                 when "u"
                   hex = @src[@pos + 1, 4]
                   @pos += 4
                   [hex.to_i(16)].pack("U")
                 else raise ParseError, "bad escape at #{@pos}"
                 end
          @pos += 1
        else
          out << ch
          @pos += 1
        end
      end
      raise ParseError, "unterminated string"
    end

    def self.parse_object
      @pos += 1
      obj = {}
      skip_ws
      if @src[@pos] == "}"
        @pos += 1
        return obj
      end
      loop do
        skip_ws
        raise ParseError, "expected string key at #{@pos}" unless @src[@pos] == '"'
        key = parse_string
        skip_ws
        raise ParseError, "expected : at #{@pos}" unless @src[@pos] == ":"
        @pos += 1
        skip_ws
        obj[key] = parse_value
        skip_ws
        case @src[@pos]
        when "," then @pos += 1
        when "}" then @pos += 1; break
        else raise ParseError, "expected , or } at #{@pos}"
        end
      end
      obj
    end

    def self.parse_array
      @pos += 1
      arr = []
      skip_ws
      if @src[@pos] == "]"
        @pos += 1
        return arr
      end
      loop do
        skip_ws
        arr << parse_value
        skip_ws
        case @src[@pos]
        when "," then @pos += 1
        when "]" then @pos += 1; break
        else raise ParseError, "expected , or ] at #{@pos}"
        end
      end
      arr
    end

    def self.parse_number
      m = @src[@pos..].match(/\A-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?/)
      raise ParseError, "bad number at #{@pos}" unless m
      @pos += m[0].length
      s = m[0]
      (s.include?(".") || s =~ /[eE]/) ? s.to_f : s.to_i
    end
  end
end
