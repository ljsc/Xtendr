require 'ffi'

module Xtendr
  # Module to contain attached foreign functions.
  # @private
  module FFI
    extend ::FFI::Library
    ffi_lib 'System'
    attach_function 'setxattr', [:string, :string, :pointer, :int, :int, :int], :int
    attach_function 'getxattr', [:string, :string, :pointer, :int, :int, :int], :int
    attach_function 'listxattr', [:string, :pointer, :int, :int], :int
    attach_function 'removexattr', [:string, :string, :int], :int
  end

  # Get the value of an extended attribute for the current object.  Calls
  # `#to_s` on self to get the path to the file the attribute is set on.
  #
  # @param [String] attribute The extended attribute to retrieve.
  # @return [String, nil] The value of the attribute, or nil if it is not set
  #                       and no block is passed.
  # @yield Block is run when the attribute is not found.
  def getx(attribute, *opts)
    getx! attribute, *opts
  rescue Errno::ENOATTR
    block_given? ? yield : nil
  end

  # Get the value of an extended attribute, raising an error if the attribute is
  # not found.
  #
  # The bang version of getx works the the same way as `getx`, exept that when
  # the attribute is not found. In that case, rather than returning `nil`, an
  # ENOATTR error is raised.
  # @raise [Errno::ENOATTR] Describes the attribute that couldn't be located.
  # @param [String] attribute The extended attribute to retrieve.
  # @return [String] The value of the requested attribute.
  #
  def getx!(attribute, *opts)
    options = opts.include?(:no_follow) ? 1 : 0
    len = FFI.getxattr(self.to_s, attribute, nil, 0, 0, options)
    raise_error(attribute, ::FFI::LastError::error) if len < 0
    buffer = ::FFI::Buffer.alloc_out(len)
    FFI.getxattr(self.to_s, attribute, buffer, buffer.size, 0, options)
    buffer.get_string(0, buffer.size)
  end

  # Set an extended attribute on a filesystem object.
  # @param [String] attribute The extended attribute to retrieve.
  # @param [String] value The value to set the extended attribute to.
  # @param [Array<:create, :replace, :no_follow>] opts Optional flags which
  #   influence how setting is done.
  # @return [nil]
  #
  # *:create*:: Raises an error if the attribute already exists.
  #
  def setx(attribute, value, *opts)
    retval = FFI.setxattr(self.to_s, attribute, value, value.size, 0, setx_options(*opts))
    raise_error(nil, ::FFI::LastError::error) if retval < 0
  end

  private
    # Set the correct bitfields on the options flag for setting operations
    # @param [Array<:replace, :create, :no_follow>] syms
    # @private
    def setx_options(*syms)
      options = 0x00
      options |= 0x04 if syms.include?(:replace)
      options |= 0x02 if syms.include?(:create)
      options |= 0x01 if syms.include?(:no_follow)
      options
    end

  public

  # List all of the extended attribute for the object.
  # @return [Array<String>] the list of all keys which have extended attributes
  #   set.
  def listx
    len = FFI.listxattr(self.to_s, nil, 0, 0)
    buffer = ::FFI::Buffer.alloc_out(len)
    FFI.listxattr(self.to_s, buffer, buffer.size, 0)
    buffer.get_bytes(0, buffer.size).split("\0")
  end

  # Removes the given extended attribute from the filesystem object.
  # @param [String] attribute The attribute to remove the extended attribute
  #   for.
  # @return [nil]
  def removex(attribute)
    FFI.removexattr(self.to_s, attribute, 0)
  end

  # Remove all extended file attributes from the object
  def remove_allx
    listx.each do |attribute|
      removex(attribute)
    end
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

class Errno::ENOATTR < SystemCallError
  # FIXME: This works on Mac OS X (Snow Leopard), but this really shouldn't be
  # hardcoded. Unfortunatly, we probably can't get the error number symbolically
  # without a C extension, which defeats the purpose of using ffi.
  Errno = 93

  def initialize(msg=nil)
    super(msg)
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

