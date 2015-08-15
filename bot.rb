#!/usr/local/bin/ruby
require "socket"

class Turdbot

    ####################
    #initializer
    ####################

    def initialize(server, port, nick, channel)
        @server = server
        @port = port
        @nick = nick
        @channel = channel
    end # function initialize

    ####################
    #send messages
    ####################

    def send(s)
        # Send a message to the irc server and print it to the screen
        puts "--> #{s}"
        @irc.send "#{s}\n", 0 
    end # function send

    ####################
    #format and send
    ####################

    def chat(s)
        send "PRIVMSG #{@nick} :#{s}"
    end # function chat

    ####################
    #establish connection
    ####################

    def connect()
        # Connect to the IRC server
        @irc = TCPSocket.open(@server, @port)
        send "USER turd bot 2.0 :the wreckening"
        send "NICK #{@nick}"
        send "JOIN #{@channel}"
    end # function connect

    ####################
    #interpret commands
    ####################

    def evaluate(s)
        # Make sure we have a valid expression (for security reasons), and
        # evaluate it if we do, otherwise return an error message
        if s =~ /^[-+*\/\d\s\eE.()]*$/ then
            begin
                s.untaint
                return eval(s).to_s
            rescue Exception => detail
                puts detail.message()
            end
        end
        return "...i took a dump"
    end # function evaluate

    ####################
    #handle server inputs
    ####################

    def handle_server_input(s)
        case s.strip
            when /^PING :(.+)$/i
                puts "[ Server ping ]"
                send "PONG :#{$1}"
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s.+\s:[\001]PING (.+)[\001]$/i
                puts "[ CTCP PING from #{$1}!#{$2}@#{$3} ]"
                send "NOTICE #{$1} :\001PING #{$4}\001"
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s.+\s:[\001]VERSION[\001]$/i
                puts "[ CTCP VERSION from #{$1}!#{$2}@#{$3} ]"
                send "NOTICE #{$1} :\001VERSION Ruby-irc v0.042\001"
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:EVAL (.+)$/i
                puts "[ EVAL #{$5} from #{$1}!#{$2}@#{$3} ]"
                send "PRIVMSG #{(($4==@nick)?$1:$4)} :#{evaluate($5)}"
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:COUNTDOWN (.+)$/i
                if $1 != @nick
                    puts "[ countdown #{$5} from #{$1}!#{$2}@#{$3} ]"
                    send "PRIVMSG #{(($4==@nick)?$1:$4)} :#{countdown($5)}"
                end
            else
                puts s
        end
    end # function handle_server_inputs

    ####################
    #countdown
    ####################

    def countdown(t)
        t = t.to_i
        if t.is_a?(Integer)
            chat "Countdown commencing..."
            for i in 0..(t-1)
                num = t - i
                count = sprintf("%d...",num)
                chat count
            end
            chat "BLAMMO!"
        else
            chat "Countdown postponed..."
        end

    end # function countdown

    ####################
    #do work
    ####################

    def main_loop()
        while true
            ready = select([@irc, $stdin], nil, nil, nil)

            if !ready
                next
            end

            for s in ready[0]
                if s == $stdin then
                    return if $stdin.eof
                    s = $stdin.gets
                    send s
                elsif s == @irc then
                    return if @irc.eof
                    s = @irc.gets
                    handle_server_input(s)
                end
            end
        end
    end # function main_loop

end # class Turdbot

####################
#start
####################

irc = Turdbot.new('irc.haxzor.ninja', 6667, 'turdbot', '#botwars')
irc.connect()
begin
    irc.main_loop()
rescue Interrupt
rescue Exception => detail
    puts detail.message()
    print detail.backtrace.join("\n")
    retry
end
