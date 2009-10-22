# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.


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