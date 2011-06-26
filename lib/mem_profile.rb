# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.



class MemProfile
  attr_reader :curr, :prev, :delta
  
  def initialize
    @curr = Hash.new(0)
    @prev = Hash.new(0)
    @delta = Hash.new(0)
  end
  
  def profile(out, opt = {})
    GC.start
    curr.clear

    curr_strings = [] if opt[:string_debug]

    ObjectSpace.each_object do |o|
      curr[o.class] += 1 if o.class #Marshal.dump(o).size rescue 1
      if opt[:string_debug] and o.class == String
        curr_strings.push o
      end
    end

    if opt[:string_debug]
      File.open("log/memory_profiler_strings.log.#{Time.now.to_i}",'w') do |f|
        curr_strings.sort.each do |s|
          f.puts s
        end
      end
      curr_strings.clear
    end

    delta.clear
    (curr.keys + delta.keys).uniq.each do |k,v|
      delta[k] = curr[k]-prev[k]
    end

    out.puts "Top 20"
    delta.sort_by { |k,v| -v.abs }[0..19].sort_by { |k,v| -v}.each do |k,v|
      out.printf "%+5d: %s (%d)\n", v, k.name, curr[k] unless v == 0 || k.nil?
    end
    out.flush

    delta.clear
    prev.clear
    prev.update curr
    GC.start
  end
end