

#this is a ruby irc bot
#beware

require 'socket'

class Turdbot
	#initializer
	def initializer(options)
		@server = options[:server]
		@port = options[:port]
		@nick = options[:nick]
		@channel = options[:channel]
	end # function initializer

	#send message
	def send(msg)
		puts "sent: #{msg}"
		@irc.send("#{msg}\n",0)
	end # function send

	#connect to the irc server
	def connect()
		@irc = TCPSocket.open(@server,@port)
		send("USER turdbot turdbot turdbot :turdbot turdbot")
		send("NICK #{@nick}")
		send("JOIN #{channel}")
	end

	















end # class Turdbot
