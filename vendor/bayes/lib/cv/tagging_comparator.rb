# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

gem 'statarray'
require 'statarray'

class TaggingComparator
  def initialize(set1, set2)
    @set1, @set2 = set1, set2
  end
  
  def build_comparisons
    set2_index = @set2.inject({}) do |h, tagging|
      h[tagging.taggable_id] ||= {}
      h[tagging.taggable_id][tagging.tag] = tagging
      h
    end
    
    @set1.map do |tagging|
      TaggingComparison.new(tagging, (set2_index[tagging.taggable_id] and set2_index[tagging.taggable_id][tagging.tag]))
    end
  end
  
  def print(out)
    comparisons = build_comparisons
    num_large_changes = comparisons.select{|c| (c.delta and c.delta.abs > 0.2) }.size
    display_comparisons = comparisons.select{|c| c.css_class =~ /^became/ or (c.delta and c.delta.abs > 0.2) }.sort
    
    out << <<-END
    <html>
    <head>
      <style>
        table {
          width: 90%;
        }
        
        th {
          
        }
        
        tr.odd td { background-color: #ccc }
        td.number { text-align: right; }
        tr.became_positive td, div.became_positive { background-color: pink; }
        tr.became_negative td, div.became_negative { background-color: cyan; }
        div.became_positive, div.became_negative {
          width: 25px;
          height: 0.9em;
        }
        
        dt {float: left; clear: left; font-weight: bold}
        dd {margin: 0.5em 120px;}
      </style>
    </head>
    <body>
      <h1>Classifier Results Comparison</h1>
      <dl>
        <dt><div class="became_positive"></div></dt>
        <dd>Items that shifted from negative to positive.</dd>
        <dt><div class="became_negative"></div></dt>
        <dd>Items that shifted from positive to negative.</dd>
        <dt>RMSE</dt>
        <dd>#{f get_rmse(comparisons)}</dd>
        <dt>% abs(&#916;) > 0.2</dt>
        <dd>#{f(num_large_changes.to_f / comparisons.size * 100)}%</dd>
        <dt>Total taggings</dt>
        <dd>#{comparisons.size}</dd>
        <dt>>= 0.9 for 1</dt>
        <dd>#{f positives(comparisons, :first_score)}</dd>
        <dt>>= 0.9 for 2</dt>
        <dd>#{f positives(comparisons, :second_score)}</dd>
      </dl>
      
      <p>Items with abs(&#916;) less than 0.2 have been omitted unless they crossed
         the positive cutoff boundary of 0.9.</p>
      <table>
        <tr>
          <th>Tag</th>
          <th>Item</th>
          <th width="100px">First Score</th>
          <th width="100px">Second Score</th>
          <th width="100px">Delta (&#916;)</th>
        </tr>        
    END
    
    display_comparisons.each do |c|
      out << <<-END
        <tr class="#{c.css_class} #{cycle}">
          <td>#{c.tag}</td>
          <td style="text-align: center">
            <a href="http://trunk.wizztag.org/feed_items/#{c.item}">#{c.item}</a>
          </td>
          <td class="number">#{f c.first_score}</td>
          <td class="number">#{f c.second_score}</td>
          <td class="number">#{f c.delta}</td>
        </tr>
      END
    end
    
    out << <<-END
      </table>
    </body>
    </html>
    END
  end
  
  private
  def get_rmse(comparisons)
    mse = comparisons.map do|c| 
      c.delta
    end.compact.map do |c|
      c ** 2
    end.to_statarray.mean
    
    Math.sqrt(mse)
  end
  
  def f(n)
    ('%.3f' % n).sub /\.0+$/, '' if n
  end
  
  def cycle
    if @cycle != "odd"
      @cycle = "odd"
    else
      @cycle = "even"
    end
  end
  
  def positives(comparisons, score)
    comparisons.select {|c| c.send(score) && c.send(score) >= 0.9 }.size
  end
end

class TaggingComparison
  attr_reader :tagging1, :tagging2
  def initialize(tagging1, tagging2)
    @tagging1, @tagging2 = tagging1, tagging2
  end
  
  def tag;  tagging1.tag; end  
  def item; tagging1.taggable_id; end  
  def first_score;  tagging1.strength; end  
  def second_score; tagging2.strength if tagging2; end
  def css_class
    if tagging1 and tagging2
      if tagging1.strength < 0.9 and tagging2.strength >= 0.9
        "became_positive"
      elsif tagging1.strength >= 0.9 and tagging2.strength < 0.9
        "became_negative"
      end
    else
      "missing"
    end
  end
  
  def delta
    tagging2.strength - tagging1.strength if tagging2
  end
  
  def <=>(other)
    (other.delta or 0).abs <=> (self.delta or 0).abs
  end
end