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
      read, write = IO.pipe
      
      pid = fork do
        read.close
        Process.setsid
        STDOUT.reopen write
        STDERR.reopen write
        STDIN.reopen  "/dev/null", "r"
        exec "bash -c 'lein repl :headless :port #{port}'"
      end
      
      write.close
      line = read.gets
      case line
      when /Address already in use/ ;
        # no-op, just connect to existing repl
      when /nREPL server started on port (\d+)/
        port = $~[1].to_i
      else
        raise "Unknown error launching repl: #{line}"
        Process.kill(pid)
        Process.waitpid(pid)
      end
      read.close

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
    
    ##
    # Clones the bindings for the provided session and sets the new session to
    # current
    # 
    # @param [String,nil] session The optional prototype session to clone from
    # @return [String] the new session id
    def clone_session(session=nil)
      response = send(op:"clone", session:session).first
      @session = response["new-session"]
      @session
    end
    
    ##
    # Closes the provided sessions
    # 
    # @param [String,nil] session An optional session identifier, otherwise the
    #   current session will be closed
    def close_session(session=nil)
      result = send(op:"close", session:session)
    end
    
    ##
    # Returns a list of sessions known to the repl
    # 
    # @return [<String>] An array of session ids
    def list_sessions
      response = send(op:"ls-sessions").first
      response["sessions"]
    end
    
    ##
    # Evaluates code on the repl, returning an array of responses
    # 
    # @param [String] code The code to run
    def eval(code, &block)
      result = send(op:"eval", code:code, &block)
    end
    
    ##
    # Sends a raw command to the repl, returning an array of responses
    # 
    def send(command)
      command = command.reverse_merge(session: @session).delete_blank
      
      sock = get_socket
      
      sock.print command.bencode
      
      puts ">>> #{command.inspect}" if @debug
      
      responses = []
      done = false
      
      begin
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
      rescue BEncode::DecodeError
        # TODO
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