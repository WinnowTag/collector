# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# This should eventually be moved to the classifier plugin.
#
class TrainCountReport # :nodoc:
  BINS = [(1..1), (2..2), (3..3), (4..4), (5..7), (8..10), (11..14), (15..19), (20..25),
          (26..30), (31..40), (41..50), (51..75), (76..100), (101..150), (151..1000)]
  
  def initialize(result_dir, user)
    require 'pdf/writer'
    require 'pdf/simpletable'
    require 'pdf/charts/stddev'
    require 'ostruct'
    require 'statarray'
    @result_dir = result_dir
    @user = user
  end
  
  def generate
    summary = collect_summary
    results, tags_in_bins, results_by_tags = collect_results
    tp_graph_data, tn_graph_data = build_graph_data(results)
         
    pdf = PDF::Writer.new(:paper => 'A3')
        
    pdf.select_font 'Times-Roman'
    
    render_summary(summary, pdf)
    
    pdf.text "\nTest Results Categorized by Training Count\n", :font_size => 32    
    pdf.text "\n\nThese graphs display the cross validation test results for a classifier " +
             "arranged by the number of items a classifier was trained on for a given tag. " +
             "The X axis displays the number of training items, where there is a gap, the " +
             "label defines the lower bound of a range that extends to the next label. " +
             "The number in brackets is the number of tags that fall into that 'bin'. " +
             "The Y Axis is the mean true positive or true negative rate for the classifiers " +
             "that fall in the 'bin'.  Standard Deviation is shown as error bars on the chart.\n\n", :font_size => 16
             
    pdf.text "True Positive Results\n\n", :font_size => 24    
    render_chart(tp_graph_data, pdf)

    pdf.text "\n\n"
    pdf.select_font 'Times-Roman'
    pdf.text "True Negative Results\n\n", :font_size => 24
    render_chart(tn_graph_data, pdf)
    
    pdf.start_new_page
    pdf.text "\n\nTags in bins\n\n", :font_size => 24
    render_tag_bin_table(tags_in_bins, pdf)
    
    pdf.start_new_page
    pdf.text "\n\nIndividual Tag Scores\n\n", :font_size => 24
    render_tag_scores(results_by_tags, pdf)
    
    pdf.save_as("#{File.basename(@result_dir)}.pdf")
  end
  
  private
  def render_summary(summary, pdf)
    execution_details = summary[:execution_details]
    table_data = []
    table_data << {'Name' => 'ID', 'Value' => execution_details[:id]}
    table_data << {'Name' => 'Comment', 'Value' => execution_details[:comment]}
    table_data << {'Name' => 'Date', 'Value' => execution_details[:date]}
    table_data << {'Name' => 'SVN Version', 'Value' => "#{execution_details[:subversion_url]}?rev=#{execution_details[:subversion_revision]}"}
    table_data << {'Name' => 'Total Classifications', 'Value' => summary[:total_classifications]}
    table_data << {'Name' => 'True Positive', 'Value' => summary[:true_positive]}
    table_data << {'Name' => 'False Negatives', 'Value' => summary[:false_negative]}
    table_data << {'Name' => 'True Negative', 'Value' => summary[:true_negative]}
    table_data << {'Name' => 'False Positive', 'Value' => summary[:false_positive]}
    
    class_opts = (execution_details[:classifier_options] or {})
    table_data << {'Name' => 'Bias', 'Value' => class_opts[:bias]}
    table_data << {'Name' => 'Unknown Word Prob', 'Value' => class_opts[:unknown_word_prob]}
    table_data << {'Name' => 'Unknown Word Strength', 'Value' => class_opts[:unknown_word_strength]}
    table_data << {'Name' => 'Min Prob Strength', 'Value' => class_opts[:min_prob_strength]}
    table_data << {'Name' => 'Max Discriminators', 'Value' => class_opts[:max_discriminators]}
            
    PDF::SimpleTable.new do |table|
      table.font_size = 16
      table.split_rows = true
      table.column_order = ['Name', 'Value']
      table.data = table_data
      table.show_headings = false
      table.render_on(pdf)
    end
  end
  
  def render_tag_scores(tag_results, pdf)
      
    distinct_tokens_per_item_table_data = []
    distinct_token_count_table_data = []
    all_tps = StatArray.new
    all_tns = StatArray.new
    
    table_data = tag_results.inject([]) do |data, tag_result_entry|
      instance_count = 0
      distinct_tokens_per_item = StatArray.new
      distinct_token_counts = StatArray.new
      
      tag = tag_result_entry.first
      tag_result = tag_result_entry.last
      tp = tag_result[:results].inject(StatArray.new) do |arr, result|
        unless (result[:true_positive] + result[:false_negative]) == 0
          num_positives = (result[:true_positive] + result[:false_negative])
          instance_count += num_positives
          distinct_tokens_per_item << (result[:unique_token_count] / result[:train_count])
          distinct_token_counts << result[:unique_token_count]
          arr << result[:true_positive].to_f / num_positives
        end
        arr
      end
      
      tn = tag_result[:results].inject(StatArray.new) do |arr, result|
        unless (result[:true_negative] + result[:false_positive]) == 0        
          arr << result[:true_negative].to_f / (result[:true_negative] + result[:false_positive])
        end
        arr
      end
      
      all_tps << tp.mean unless tp.empty?
      all_tns << tn.mean unless tn.empty?
      
      distinct_tokens_per_item_table_data << PDF::Charts::StdDev::DataPoint.new("#{distinct_tokens_per_item.mean.round}", tp.mean, tp.stddev)
      distinct_token_count_table_data << PDF::Charts::StdDev::DataPoint.new("#{distinct_token_counts.mean.round}", tp.mean, tp.stddev)
      
      data << {'Tag' => tag, 'Instances' => instance_count, 
                  'TP' => '%.2f (%.2f)' % [tp.mean, tp.stddev], 
                  'TN' => '%.2f (%.2f)' % [tn.mean, tn.stddev],
                  'Ave Item Size (Distinct Tokens)' => '%d' % distinct_tokens_per_item.mean.round,
                  'Ave Distinct Tokens in Pool' => '%d' % distinct_token_counts.mean.round}
      data
    end
    
    table_data.sort! {|a, b| a['Instances'] <=> b['Instances']}
    
    table_data << {'Tag' => 'Average', 'TP' => '%.2f (%.2f)' % [all_tps.mean,all_tps.stddev], 'TN' => '%.2f (%.2f)' % [all_tns.mean, all_tns.stddev]}
    
    PDF::SimpleTable.new do |table|
      table.font_size = 16
      table.split_rows = true
      table.column_order = ['Tag', 'Instances', 'Ave Item Size (Distinct Tokens)', 'Ave Distinct Tokens in Pool', 'TP', 'TN']
      table.data = table_data
      table.render_on(pdf)
    end
    
    distinct_tokens_per_item_table_data.sort! {|a, b| a.label.to_i <=> b.label.to_i}
    distinct_token_count_table_data.sort! {|a, b| a.label.to_i <=> b.label.to_i}
    
    pdf.start_new_page
    pdf.text "\n\nTrue Positive Results by Average Distinct Tokens per Item\n\n", :font_size => 24 
    
    PDF::Charts::StdDev.new do |chart|
      chart.scale.range = (0..1)
      chart.scale.step = 0.2
      chart.scale.show_labels = true
      chart.datapoint_width = 45
      chart.maximum_width = 800
      chart.label.background_color = Color::RGB::White
      chart.label.text_color = Color::RGB::Black
      chart.leading_gap = -3
      
      distinct_tokens_per_item_table_data.each do |d|
        chart.data << d
      end
      
      chart.render_on(pdf)
    end
    
    pdf.text "\n\nTrue Positive Results by Average Distinct Token Count in Pool\n\n", :font_size => 24 
    
    PDF::Charts::StdDev.new do |chart|
      chart.scale.range = (0..1)
      chart.scale.step = 0.2
      chart.scale.show_labels = true
      chart.datapoint_width = 45
      chart.maximum_width = 800
      chart.label.background_color = Color::RGB::White
      chart.label.text_color = Color::RGB::Black
      chart.leading_gap = -3
      
      distinct_token_count_table_data.each do |d|
        chart.data << d
      end
      
      chart.render_on(pdf)
    end
  end
  
  def render_tag_bin_table(tags_in_bins, pdf)
    table_data = BINS.inject([]) do |data, bin|
      tags = ''
      tags_in_bins[bin].to_a.each_with_index do |tag, index|
        tags << tag
        if (index + 1) % 3 == 0
          tags << ",\n"
        else
          tags << ', '
        end
      end
      
      data << {'Bin' => bin.to_s, 'Tags' => tags}
      data
    end
    
    PDF::SimpleTable.new do |table|
      table.font_size = 16
      table.split_rows = true
      table.column_order = ['Bin', 'Tags']
      table.data = table_data
      table.render_on(pdf)
    end
  end
  
  def render_chart(data, pdf)
    PDF::Charts::StdDev.new do |chart|
      chart.scale.range = (0..1)
      chart.scale.step = 0.2
      chart.scale.show_labels = true
      chart.datapoint_width = 45
      chart.maximum_width = 800
      chart.label.background_color = Color::RGB::White
      chart.label.text_color = Color::RGB::Black
      
      data.each do  |tp|
        chart.data << tp
      end
      
      chart.render_on pdf
    end
  end
  
  def build_graph_data(results)
    tp_data = {}
    tn_data = {}
    
    results.each do |range, result_data|
      tp_data[range] = result_data.map do |result|
        next if (result.true_positive + result.false_negative) == 0
        result.true_positive.to_f / (result.true_positive + result.false_negative)
      end.compact
      
      tn_data[range] = result_data.map do |result|
        next if (result.true_negative + result.false_positive) == 0
        result.true_negative.to_f / (result.true_negative + result.false_positive)
      end.compact
    end
        
    tp_graph_data = []
    tn_graph_data = []
    
    BINS.each do |bin|
      tp_graph_data << build_graph_data_point(bin.begin, tp_data[bin])
      tn_graph_data << build_graph_data_point(bin.begin, tn_data[bin])
    end
    
    [tp_graph_data, tn_graph_data]
  end
  
  def build_graph_data_point(label, data)
    statarray = StatArray.new(data)
    PDF::Charts::StdDev::DataPoint.new("#{label.to_s}(#{data.size})", statarray.mean, statarray.stddev)
  end
  
  def collect_summary
    YAML.load(File.read(File.join(@result_dir, 'summary.yaml')))
  end
  
  def collect_results    
    result_files = Dir.glob(File.join(@result_dir, '*.yaml')).delete_if do |file_name|
      file_name =~ /summary.yaml/ or file_name =~ /unwanted.yaml/ or file_name =~ /duplicate.yaml/ or
        file_name =~ /seen.yaml/ or file_name =~ /seen/ or file_name !~ /#{@user}/
    end
    
    results = BINS.inject({}) do |results, bin|
      results[bin] = []
      results
    end
    
    tags_in_bins = BINS.inject({}) do |tags_in_bins, bin|
      tags_in_bins[bin] = Set.new
      tags_in_bins
    end
    
    results_by_tag = {}
    
    result_files.each do |result_file|
      tag_name = File.basename(result_file).sub(/\.yaml/, '').gsub(' ', '_')
      result_data = YAML.load(File.read(result_file))
      results_by_tag[tag_name] = result_data
      result_data[:results].each do |result|
        next if result[:train_count] == 0
        
        results.keys.each do |key|
          if key.include? result[:train_count]
            tags_in_bins[key] << tag_name
            results[key] << OpenStruct.new(result)
            break
          end
        end
      end
    end
    
    [results, tags_in_bins, results_by_tag]
  end
end
