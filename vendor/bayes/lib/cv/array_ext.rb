# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# We will need extend the Ruby Array class to do some of our partitioning

# Here we extend the array class to partition arrays based on values
# This method is from the Oreilly Ruby Cookbook
class Array #:nodoc:

  # Patch to Array to allow indexing by an attribute
  def hash_by(attribute)
    self.inject({}) do |hash, e|
      hash[e.send(attribute)] = e
      hash
    end
  end
  
  # Patch to Array to allow indexing by an attribute
  def non_unique_hash_by(attribute)
    self.inject({}) do |hash, e|
      hash[e.send(attribute)] ||= []
      hash[e.send(attribute)] << e
      hash
    end
  end
  
  # Extend the Array class with a method to get the size of the partition slices
  def getPartitionSize(num_partitions)
    @partition_num = num_partitions
    total = self.size
    base_size = total / @partition_num
    extended_size = base_size + 1
    mod_remainder = total % @partition_num

    partitionSizes = []
    for i in 1..num_partitions
      if i < mod_remainder  
        partitionSizes << extended_size
      else 
        partitionSizes << base_size
      end
    end
    partitionSizes
  end

  # Here we extend the Array class to have a "divides by" method to 
  # break up the array into approximately equal sized chunks. 
  # This method is specifically for k-fold cross validation partitions:

  def / len
    partitions=self.getPartitionSize(len)
    ary=[]
    partitions.each {|x| ary << self.slice!(0..x-1) }
    ary
  end

  # Here we extend the Array class to have a shuffle method:
  # (this method is from the Oreilly Ruby Cookbook)
  def shuffle!
    each_index do |i| 
      j = rand(length-i) + i
      self[j], self[i] = self[i], self[j]
    end
  end

  def shuffle
    dup.shuffle!
  end  

end
