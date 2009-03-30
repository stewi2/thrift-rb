#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements. See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership. The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied. See the License for the
# specific language governing permissions and limitations
# under the License.
#

require File.dirname(__FILE__) + '/spec_helper'

shared_examples_for 'a binary protocol' do
  before(:each) do
    @trans = Thrift::MemoryBuffer.new
    @prot = protocol_class.new(@trans)
  end

  it "should define the proper VERSION_1, VERSION_MASK AND TYPE_MASK" do
    protocol_class.const_get(:VERSION_MASK).should == 0xffff0000
    protocol_class.const_get(:VERSION_1).should == 0x80010000
    protocol_class.const_get(:TYPE_MASK).should == 0x000000ff
  end

  it "should make strict_read readable" do
    @prot.strict_read.should eql(true)
  end

  it "should make strict_write readable" do
    @prot.strict_write.should eql(true)
  end    

  it "should write the message header" do
    @prot.write_message_begin('testMessage', Thrift::MessageTypes::CALL, 17)
    @trans.read(1000).should == [protocol_class.const_get(:VERSION_1) | Thrift::MessageTypes::CALL, "testMessage".size, "testMessage", 17].pack("NNa11N")
  end
  
  it "should write the message header without version when writes are not strict" do
    @prot = protocol_class.new(@trans, true, false) # no strict write
    @prot.write_message_begin('testMessage', Thrift::MessageTypes::CALL, 17)
    @trans.read(1000).should == "\000\000\000\vtestMessage\001\000\000\000\021"
  end
  
  it "should write the message header with a version when writes are strict" do
    @prot = protocol_class.new(@trans) # strict write
    @prot.write_message_begin('testMessage', Thrift::MessageTypes::CALL, 17)
    @trans.read(1000).should == "\200\001\000\001\000\000\000\vtestMessage\000\000\000\021"
  end
  

  # message footer is a noop

  it "should write the field header" do
    @prot.write_field_begin('foo', Thrift::Types::DOUBLE, 3)
    @trans.read(1000).should == [Thrift::Types::DOUBLE, 3].pack("cn")
  end
  
  # field footer is a noop
  
  it "should write the STOP field" do
    @prot.write_field_stop
    @trans.read(1).should == "\000"
  end
  
  it "should write the map header" do
    @prot.write_map_begin(Thrift::Types::STRING, Thrift::Types::LIST, 17)
    @trans.read(1000).should == [Thrift::Types::STRING, Thrift::Types::LIST, 17].pack("ccN");
  end
   
  # map footer is a noop
  
  it "should write the list header" do
    @prot.write_list_begin(Thrift::Types::I16, 42)
    @trans.read(1000).should == [Thrift::Types::I16, 42].pack("cN")
  end
  
  # list footer is a noop
  
  it "should write the set header" do
    @prot.write_set_begin(Thrift::Types::I16, 42)
    @trans.read(1000).should == [Thrift::Types::I16, 42].pack("cN")
  end
  
  it "should write a bool" do
    @prot.write_bool(true)
    @prot.write_bool(false)
    @trans.read(1000).should == "\001\000"
  end
  
  it "should treat a nil bool as false" do
    @prot.write_bool(nil)
    @trans.read(1).should == "\000"
  end
  
  it "should write a byte" do
    # byte is small enough, let's check -128..127
    (-128..127).each do |i|
      @prot.write_byte(i)
      @trans.read(1).should == [i].pack('c')
    end
    # handing it numbers out of signed range should clip
    @trans.rspec_verify
    (128..255).each do |i|
      @prot.write_byte(i)
      @trans.read(1).should == [i].pack('c')
    end
    # and lastly, a Bignum is going to error out
    lambda { @prot.write_byte(2**65) }.should raise_error(RangeError)
  end
  
  it "should error gracefully when trying to write a nil byte" do
    lambda { @prot.write_byte(nil) }.should raise_error
  end
  
  it "should write an i16" do
    # try a random scattering of values
    # include the signed i16 minimum/maximum
    [-2**15, -1024, 17, 0, -10000, 1723, 2**15-1].each do |i|
      @prot.write_i16(i)
    end
    # and try something out of signed range, it should clip
    @prot.write_i16(2**15 + 5)
    
    @trans.read(1000).should == "\200\000\374\000\000\021\000\000\330\360\006\273\177\377\200\005"
    
    # a Bignum should error
    # lambda { @prot.write_i16(2**65) }.should raise_error(RangeError)
  end
  
  it "should error gracefully when trying to write a nil i16" do
    lambda { @prot.write_i16(nil) }.should raise_error
  end
  
  it "should write an i32" do
    # try a random scattering of values
    # include the signed i32 minimum/maximum
    [-2**31, -123123, -2532, -3, 0, 2351235, 12331, 2**31-1].each do |i|
      @prot.write_i32(i)
    end
    # try something out of signed range, it should clip
    @trans.read(1000).should == "\200\000\000\000" + "\377\376\037\r" + "\377\377\366\034" + "\377\377\377\375" + "\000\000\000\000" + "\000#\340\203" + "\000\0000+" + "\177\377\377\377"
    [2 ** 31 + 5, 2 ** 65 + 5].each do |i|
      lambda { @prot.write_i32(i) }.should raise_error(RangeError)  
    end
  end
  
  it "should error gracefully when trying to write a nil i32" do
    lambda { @prot.write_i32(nil) }.should raise_error
  end
  
  it "should write an i64" do
    # try a random scattering of values
    # try the signed i64 minimum/maximum
    [-2**63, -12356123612323, -23512351, -234, 0, 1231, 2351236, 12361236213, 2**63-1].each do |i|
      @prot.write_i64(i)
    end
    # try something out of signed range, it should clip
    @trans.read(1000).should == ["\200\000\000\000\000\000\000\000",
      "\377\377\364\303\035\244+]",
      "\377\377\377\377\376\231:\341",
      "\377\377\377\377\377\377\377\026",
      "\000\000\000\000\000\000\000\000",
      "\000\000\000\000\000\000\004\317",
      "\000\000\000\000\000#\340\204",
      "\000\000\000\002\340\311~\365",
      "\177\377\377\377\377\377\377\377"].join("")
    lambda { @prot.write_i64(2 ** 65 + 5) }.should raise_error(RangeError)
  end
  
  it "should error gracefully when trying to write a nil i64" do
    lambda { @prot.write_i64(nil) }.should raise_error
  end
  
  it "should write a double" do
    # try a random scattering of values, including min/max
    values = [Float::MIN,-1231.15325, -123123.23, -23.23515123, 0, 12351.1325, 523.23, Float::MAX]
    values.each do |f|
      @prot.write_double(f)
      @trans.read(1000).should == [f].pack("G")
    end
  end
  
  it "should error gracefully when trying to write a nil double" do
    lambda { @prot.write_double(nil) }.should raise_error
  end
  
  it "should write a string" do
    str = "hello world"
    @prot.write_string(str)
    @trans.read(1000).should == [str.size].pack("N") + str
  end
  
  it "should error gracefully when trying to write a nil string" do
    lambda { @prot.write_string(nil) }.should raise_error
  end
  
  # message footer is a noop
  
  it "should read a field header" do
    @trans.write([Thrift::Types::STRING, 3].pack("cn"))
    @prot.read_field_begin.should == [nil, Thrift::Types::STRING, 3]
  end
  
  # field footer is a noop
  
  it "should read a stop field" do
    @trans.write([Thrift::Types::STOP].pack("c"));
    @prot.read_field_begin.should == [nil, Thrift::Types::STOP, 0]
  end

  it "should read a map header" do
    @trans.write([Thrift::Types::DOUBLE, Thrift::Types::I64, 42].pack("ccN"))
    @prot.read_map_begin.should == [Thrift::Types::DOUBLE, Thrift::Types::I64, 42]
  end
  
  # map footer is a noop
  
  it "should read a list header" do
    @trans.write([Thrift::Types::STRING, 17].pack("cN"))
    @prot.read_list_begin.should == [Thrift::Types::STRING, 17]
  end
  
  # list footer is a noop
  
  it "should read a set header" do
    @trans.write([Thrift::Types::STRING, 17].pack("cN"))
    @prot.read_set_begin.should == [Thrift::Types::STRING, 17]
  end
  
  # set footer is a noop
  
  it "should read a bool" do
    @trans.write("\001\000");
    @prot.read_bool.should == true
    @prot.read_bool.should == false
  end
  
  it "should read a byte" do
    [-128, -57, -3, 0, 17, 24, 127].each do |i|
      @trans.write([i].pack("c"))
      @prot.read_byte.should == i
    end
  end
  
  it "should read an i16" do
    # try a scattering of values, including min/max
    [-2**15, -5237, -353, 0, 1527, 2234, 2**15-1].each do |i|
      @trans.write([i].pack("n"));
      @prot.read_i16.should == i
    end
  end
  
  it "should read an i32" do
    # try a scattering of values, including min/max
    [-2**31, -235125, -6236, 0, 2351, 123123, 2**31-1].each do |i|
      @trans.write([i].pack("N"))
      @prot.read_i32.should == i
    end
  end
  
  it "should read an i64" do
    # try a scattering of values, including min/max
    [-2**63, -123512312, -6346, 0, 32, 2346322323, 2**63-1].each do |i|
      @trans.write([i >> 32, i & 0xFFFFFFFF].pack("NN"))
      @prot.read_i64.should == i
    end
  end
  
  it "should read a double" do
    # try a random scattering of values, including min/max
    [Float::MIN, -231231.12351, -323.233513, 0, 123.2351235, 2351235.12351235, Float::MAX].each do |f|
      @trans.write([f].pack("G"));
      @prot.read_double.should == f
    end
  end
  
  it "should read a string" do
    str = "hello world"
    @trans.write([str.size].pack("N") + str)
    @prot.read_string.should == str
  end
end
