require 'socket'
require 'retriable'
require 'bencode'


module Nrepl
  class Repl
    attr_accessor :session
    attr_accessor :debug
    
    ##
    # Connects to an already running nrepl server
    # 
    # @param [Fixnum] port The port the server is running on
    # @return [Nrepl::Repl] a repl instance
    def self.connect(port)
      new(port)
    end
    
    ##
    # Starts a new clojure process at the current working directory
    # 
    # @param [Fixnum,nil] port An optional port number, otherwise leiningen
    #  will pick the port
    # @return [Nrepl::Repl] a repl instance
    def self.start(port=nil)
      raise "not working yet"
    end
    
    def initialize(port)
      @port = port
      @session = nil
      @debug = false
    end
    
    def debug!
      @debug = true
      self
    end
    
    ##
    # Returns true if we can get a socket connection to this repl
    # 
    # @return [Boolean] true if running, false if not
    def running?
      !!get_socket(0)
    end
    
    def clone_session(session=nil)
      response = send(op:"clone", session:session).first
      @session = response["new-session"]
      @session
    end
    
    def close_session(session=nil)
      result = send(op:"close", session:session)
    end
    
    def list_sessions
      response = send(op:"ls-sessions").first
      response["sessions"]
    end
    
    def eval(code, &block)
      result = send(op:"eval", code:code, &block)
    end
    
    def send(command)
      command = command.reverse_merge(session: @session).delete_blank
      
      sock = get_socket
      
      sock.print command.bencode
      
      puts ">>> #{command.inspect}" if @debug
      
      responses = []
      done = false
      
      until done
        retriable timeout: 0.2, tries: 100 do
          raw = sock.recv(100000) #TODO: figure out better way to ensure we've drained the receive buffer besides large magic number
          decoded = raw.bdecode
          
          puts "<<< #{decoded}" if @debug
          responses << decoded
          yield decoded if block_given?
          
          status = responses.last["status"]
          done = status.include?("done") || status.include?("error")
        end
      end
      
      responses
    end
    
    
    
    def get_socket(tries = 3)
      retriable on: [Errno::ECONNREFUSED], tries: tries, interval: 3 do
        TCPSocket.new("localhost", @port)
      end
    rescue Errno::ECONNREFUSED
      nil
    end
  end
end