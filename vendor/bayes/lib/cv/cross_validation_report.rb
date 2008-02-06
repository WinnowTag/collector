# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require 'ostruct'
require 'breakpoint'

# This should eventually be moved to the classifier plugin.
#
class CrossValidationReport # :nodoc:
  include ActionView::Helpers::NumberHelper
  
  def self.generate(result_folders, directory)
    results = result_folders.map do |result_number|
      summary_file = File.join(directory, result_number, 'summary.yaml')
      if File.exists? summary_file
        [result_number, OpenStruct.new(YAML.load(File.read(summary_file)))]      
      else
        nil
      end
    end.compact
  
    unwanted_results = result_folders.map do |result_number|
      unwanted_aggregate = Dir.glob(File.join(directory, result_number, '*-unwanted.yaml')).inject(Hash.new(0)) do |aggregate, result_file|
        result = YAML.load(File.read(result_file))
        result[:summary].each do |stat, value|
          aggregate[stat] = aggregate[stat] + value.to_i
        end
        aggregate
      end
      [result_number, OpenStruct.new(unwanted_aggregate)]
    end

    self.new(results, unwanted_results).print
  end
  
  attr_reader :results, :baseline, :unwanted_results
  
  def initialize(results, unwanted_results)    
    @results = results
    @unwanted_results = unwanted_results
    @baseline = results.first
  end
  
  def print
    ERB.new(@@template).result(binding)
  end
  
  def statistics
    [ :true_positive_rate, :true_negative_rate, :false_positive, :true_positive, :false_negative, 
      :true_negative, :precision, :accuracy, :recall]
  end
  
  def comparison_statistics
    [ :true_positive_rate, :false_positive_rate, :true_negative_rate, :false_negative_rate, :precision, :accuracy]
  end
  
  def trials
    results.select {|result| result != baseline}
  end
  
  def width_for(statistic, result)    
    max_for_stat = results.map {|full_result| full_result[1].send(statistic)}.max
    if approaches_one?(statistic)
      width = result[1].send(statistic) * 99
    elsif compare_to_total_count?(statistic)
      width = result[1].send(statistic).to_f / result[1].total_classifications * 99
    else
      width = result[1].send(statistic) / max_for_stat * 99
    end
    
    "#{width.round}%"
  end
  
  def color_for(run_number)
    colors = %w(#FFEC8B salmon #AAFF77 #FF99FF #FFFFDD #CCFFCC)
    colors[run_number % colors.size]
  end
  
  def compare_to_total_count?(statistic)
    [:total_negatives, :total_positives, :false_negative, :false_positive, :true_negative, :true_positive, :unknown, :true_unknown]
  end
  
  def approaches_one?(statistic)
    [:precision, :accuracy, :recall, :true_positive_rate, :true_negative_rate, :false_positive_rate, :false_negative_rate].include?(statistic)
  end
  
  def unwanted_stat(unwanted, stat)    
    if unwanted[1]
      self.send(stat, unwanted[1])
    else
      0
    end
  end
  
  def true_positive_rate(result)
    result.true_positive.to_f / (result.false_negative + result.true_positive)
  end
  
  def false_positive_rate(result)
    result.false_positive.to_f / (result.false_positive + result.true_negative)
  end
  
  def true_negative_rate(result)
    result.true_negative.to_f / (result.true_negative + result.false_positive)
  end
  
  def false_negative_rate(result)
    result.false_negative.to_f / (result.false_negative + result.true_positive)
  end
  
  def true_positive_rate_for_normal_tags(unwanted)
    result = results.detect {|r| r[0] == unwanted[0]}
    
    if result and unwanted[1].true_positive
      normal_tp = result[1].true_positive - unwanted[1].true_positive
      normal_fn = result[1].false_negative - unwanted[1].false_negative
      normal_tp.to_f / ( normal_fn + normal_tp )
    else
      0
    end
  end
  
  def false_positive_rate_for_normal_tags(unwanted)
    result = results.detect {|r| r[0] == unwanted[0]}
    
    if result and unwanted[1].false_positive
      normal_fp = result[1].false_positive - unwanted[1].false_positive
      normal_tn = result[1].true_negative - unwanted[1].true_negative
      normal_fp.to_f / ( normal_tn + normal_fp )
    else
      0
    end
  end
  
  def true_negative_rate_for_normal_tags(unwanted)
    result = results.detect {|r| r[0] == unwanted[0]}
    
    if result and unwanted[1].false_positive
      normal_fp = result[1].false_positive - unwanted[1].false_positive
      normal_tn = result[1].true_negative - unwanted[1].true_negative
      normal_tn.to_f / ( normal_tn + normal_fp )
    else
      0
    end
  end
  
  def false_negative_rate_for_normal_tags(unwanted)
    result = results.detect {|r| r[0] == unwanted[0]}
    
    if result and unwanted[1].true_positive
      normal_tp = result[1].true_positive - unwanted[1].true_positive
      normal_fn = result[1].false_negative - unwanted[1].false_negative
      normal_fn.to_f / ( normal_fn + normal_tp ) 
    else
      0
    end
  end
  
  def format(n)
    ('%.3f' % n).sub /\.0+$/, ''
  end
  
  def percentage_unwanted
    total_unwanteds = @unwanted_results.inject(0) do |total, unwanted_result|
      unwanted_summary = unwanted_result[1]
      total += unwanted_summary.true_positive
      total += unwanted_summary.true_negative
      total += unwanted_summary.false_positive
      total += unwanted_summary.false_negative
    end
    
    (total_unwanteds.to_f / (baseline[1].total_classifications * results.size) * 100).round
  end
  
  def percentage_normal
    100 - percentage_unwanted
  end
  
  @@template = %(
    <html>
      <head>
        <title>Cross Validation Result for Runs <%=results.map {|r| r[0]}.join(', ')%></title>
        <style>
        body {
          font-family: Verdana, Arial, Helvetica, sans-serif;
        	font-size: 12px;
        }
        
        table {
        	width: 100%;
        	background: #D0EEFF;
        	border: 1px solid #EEE;
        	margin-top: 10px;
        	clear:  both;
        }

        table th {
        	font-size: 12px;
        	text-align: left;
        	text-transform: capitalize;
        	vertical-align: top;
        	border-bottom: 1px solid white;
        }
        
        table th.number, table td.number {
          text-align: right;
        }
        table td {
        	background: white;
        	font-size: 12px;
        	padding-left: 2px;
        	padding-right: 5px;
        	vertical-align: top;
        }
        
        div.bar {
          overflow: visible;
          white-space: nowrap;
          border: 1px solid #999;
          margin: 2px 0px;
          padding: 2px -20px 2px 2px;
        }
        
        p.explanation {
          font-weight: normal;
          font-size: 90%;
          font-style: italics;
          width: 150px;
        }
        
        </style>
      </head>
      <body>
        <h1>Cross Validation Result for Runs <%=results.map {|r| r[0]}.join(', ')%></h1>
        <p>Generated at <%= Time.now %></p>
        <h2>Cross Validation Executions</p>
        <table>
          <tr>
            <th>Run Number</th>
            <th>Comment</th>
            <th>Total Classifications</th>
            <th>+ve cutoff</th>
            <th>-ve cutoff</th>
            <th>Folds</th>
          <tr>
        <% results.each_with_index do |result, index| %>
          <tr>
            <td width="100px" style="background-color: <%= color_for(index)%>"><%= result[0] %></td>
            <td><%= result[1].execution_details[:comment] %></td>
            <td><%= result[1].total_classifications %></td>
            <td><%= result[1].execution_details[:positive_cutoff] %></td>
            <td><%= result[1].execution_details[:negative_cutoff] %></td>
            <td><%= result[1].execution_details[:folds] %></td>
          </tr>
        <% end %>
        </table>
        
        <h2>Execution Results</h2>
        <table>
          <tr>
            <th colspan="2">Unwanted Tags - <%= percentage_unwanted %>%</th>
          </tr>
          <% [:true_positive_rate, :true_negative_rate].each do |stat| %>
          <tr>
            <td width="150px">&nbsp;&nbsp;<%= stat.to_s.humanize %></th>
            <td>
              <% unwanted_results.each_with_index do |unwanted, index| 
                  rate = unwanted_stat(unwanted, stat)%>
                <div class="bar" style="width: <%= (rate * 100).round %>%; background-color: <%= color_for(index)%>;">
                  Run <%= unwanted[0] %>: <%=format  rate %>
                </div>
              <% end %>
            </td>
          </tr>
          <% end %>
          <tr>
            <th colspan="2">Normal Tags - <%= percentage_normal %>%</th>
          </tr>
          <tr>
            <td width="150px">&nbsp;&nbsp;True positive rate</td>
            <td>
              <% unwanted_results.each_with_index do |unwanted, index| 
                  rate = true_positive_rate_for_normal_tags(unwanted)%>
                <div class="bar" style="width: <%=(rate * 100).round %>%; background-color: <%= color_for(index)%>;">
                  Run <%= unwanted[0] %>: <%=format rate %>
                </div>
              <% end %>
            </td>
          </tr>          
          <tr>
            <td width="150px">&nbsp;&nbsp;True negative rate</td>
            <td>
              <% unwanted_results.each_with_index do |unwanted, index| 
                  rate = true_negative_rate_for_normal_tags(unwanted)%>
                <div class="bar" style="width: <%=(rate * 100).round%>%; background-color: <%= color_for(index)%>;">
                  Run <%= unwanted[0] %>: <%=format  rate %>
                </div>
              <% end %>
            </td>
          </tr>
        </table>
        
        <% unless trials.empty? %>        
         <table>
          <tr><th colspan="2">Summary comparisons with baseline of execution <%= baseline[0] %></th></tr>
          <tr>
            <th>&nbsp;</th>
          <% for trial in trials %>
            <th class="number"><%= trial[0] %></th>
          <% end %>
          </tr>
          <% comparison_statistics.each do |statistic| %>
            <tr>
              <th width="150px"><%= statistic.to_s %></th>
              <% for trial in trials %>
              <td class="number"><%= '%+.1f' % ((trial[1].send(statistic).to_f - baseline[1].send(statistic).to_f) /  baseline[1].send(statistic).to_f * 100)%>%</td>
              <% end %>
            </tr>
          <% end %>
        </table>
        <% end %>
        
      <table>
        <tr>
          <th colspan="2">Details</th>
        </tr>
        <% statistics.each do |statistic| %>
          <tr>
            <td width="150px">&nbsp;&nbsp;<%= statistic.to_s.humanize %></td>
            <td>
            <% results.each_with_index do |result, index| %>
              <div class="bar" style="width: <%= width_for statistic, result %>; background-color: <%= color_for(index)%>">
                Run <%= result[0] %>: <%=format result[1].send(statistic) %>
              </div>
            <% end %>
            </td>
          </tr>
        <% end %>
      </table>
        <h2>Statistic Definitions</h2>
        <dl>
          <dt>true_positive (TP)</dt>
          <dd>The number of times a classifier applied a tag positively that coincided 
          with the human applied tag.</dd>
          <dt>true_negative (TN)</dt>
          <dd>The number of times a classifier applied a tag negatively that coincided 
          with the human applied tag.</dd>
          <dt>false_positive (FP)</dt>
          <dd>The number of times a classifier applied a tag positively when the human 
          applied it negatively.</dd>
          <dt>false_negative (FN)</dt>
          <dd>The number of times a classifier applied a tag negatively whern the human 
          applied it positively.</dd>
        </dl>
        <h3>Summary statistics</h3>
        <dl>
          <dt>total positives (P)</dt>
          <dd>FP + TN</dd>
          <dt>total negatives (N)</dt>
            <dd>TN + FP</dd>
          <dt>false positive rate</dt>
            <dd>FP / N (Lower is better)</dd>
          <dt>true positive rate</dt>
            <dd>TP / P (Higher is better)</dd>
          <dt>accuracy </dt>
            <dd>(TP + TN)/ (P + N)  (Higher is better, should approach 1)</dd>
          <dt>precision</dt>
            <dd>TP / (TP + FP) (Higher is better, should approach 1)</dd>
          <dt>recall</dt>
            <dd>TP/P (Same as true positive rate, why do we have this?)</dd>
        </dl>
      </body>
    </html>)
end
