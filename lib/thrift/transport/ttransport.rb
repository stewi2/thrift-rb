class TTransport
  def isOpen(); nil; end
  
  def open(); nil; end
  
  def close(); nil; end
  
  def read(sz); nil; end
  
  def readAll(sz)
    buff = ''
    have = 0
    while (have < sz)
      chunk = read(sz - have)
      have += chunk.length
      buff += chunk
    end
    return buff
  end

  def write(buf); nil; end

  def flush(); nil; end
  
end

class TServerTransport
  def listen(); nil; end
  
  def accept(); nil; end

  def close(); nil; end

end

class TTransportFactory
  def getTransport(trans)
    return trans
  end
end

    
