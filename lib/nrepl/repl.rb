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
      new(port)
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
      result = send(op:"clone", session:session)
      result["new-session"]
    end
    
    def close_session(session=nil)
      result = send(op:"close", session:session)
    end
    
    def list_sessions
      result = send(op:"ls-sessions")
    end
    
    def eval(code)
      result = send(op:"eval", code:code)
    end
    
    def send(command)
      command = command.reverse_merge(session: @session).delete_blank
      
      sock = get_socket
      sock.print command.bencode
      
      if @debug
        puts ">>> #{command.inspect}"
      end
      
      responses = []
      done = false
      
      until done
        retriable timeout: 0.2, tries: 100 do
          raw = sock.recv(100000)
          
          if @debug
            puts "<<< #{raw.bdecode}"
          end
          
          responses << raw.bdecode
          
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