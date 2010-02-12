require 'ffi'

class Errno::ENOATTR < SystemCallError
  Errno = 93

  def initialize(msg=nil)
    super(msg)
  end
end

module Xtendr
  module FFI
    extend ::FFI::Library
    ffi_lib 'System'
    attach_function 'setxattr', [:string, :string, :pointer, :int, :int, :int], :int
    attach_function 'getxattr', [:string, :string, :pointer, :int, :int, :int], :int
    attach_function 'listxattr', [:string, :pointer, :int, :int], :int
    attach_function 'removexattr', [:string, :string, :int], :int
  end

  def get_xattr(attribute)
    get_xattr! attribute
  rescue Errno::ENOATTR
    nil
  end

  def get_xattr!(attribute)
    len = FFI.getxattr(self.to_s, attribute, nil, 0, 0, 0)
    raise_error(attribute, ::FFI::LastError::error) if len < 0
    buffer = ::FFI::Buffer.alloc_out(len)
    FFI.getxattr(self.to_s, attribute, buffer, buffer.size, 0, 0)
    buffer.get_string(0, buffer.size)
  end

  def set_xattr(attribute, value)
    FFI.setxattr(self.to_s, attribute, value, value.size, 0, 0)
  end

  def list_xattrs
    len = FFI.listxattr(self.to_s, nil, 0, 0)
    buffer = ::FFI::Buffer.alloc_out(len)
    FFI.listxattr(self.to_s, buffer, buffer.size, 0)
    buffer.get_bytes(0, buffer.size).split("\0")
  end

  def remove_xattr(attribute)
    FFI.removexattr(self.to_s, attribute, 0)
  end

  protected
    def raise_error(msg, code)
      if code == Errno::ENOATTR::Errno
        raise Errno::ENOATTR.new(msg)
      else
        raise SystemCallError.new(msg, code)
      end
    end
end

class XtendrProxy
  def initialize(file)
    @file = file
  end

  def to_s
    @file
  end

  include Xtendr
end

def Xtendr(file)
  XtendrProxy.new(file)
end

