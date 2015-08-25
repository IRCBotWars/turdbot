#!/usr/local/bin/ruby
require "socket"

class Turdbot

    ####################
    #initializer
    ####################

    def initialize(server, port, nick, channel)
        @data = {}
        @data[:server] = server
        @data[:port] = port
        @data[:nick] = nick
        @data[:channel] = channel
        @data[:passwd] = "500ner"
        @data[:continue] = true
        @data[:id] = false
        @cowlist = ["beavis.zen","bong","bud-frogs","bunny","cheese","cower","daemon",\
            "default","dragon","dragon-and-cow","elephant","elephant-in-snake","eyes",\
            "flaming-sheep","ghostbusters","head-in","hellokitty","kiss","kitty","koala",\
            "kosh","luke-koala","meow","milk","moofasa","moose","mutilated","ren",\
            "satanic","sheep","skeleton","small","sodomized","stegosaurus","stimpy",\
            "supermilker","surgery","telebears","three-eyes","turkey","turtle","tux",\
            "udder","vader","vader-koala","www"]
    end # function initialize

    ####################
    #send messages
    ####################

    def send(s)
        puts "--> #{s}"
        @irc.send "#{s}\n", 0 
    end # function send

    ####################
    #randomize nick
    ####################

    def rand_nick
        new = (0...13).map { (65 + rand(26)).chr }.join
        @irc.send("NICK #{new}\n",0)

    end # function rand_nick

    ####################
    #format and send
    ####################

    def chat(s,target=@data[:channel])
        send "PRIVMSG #{target} :#{s}"
    end # function chat

    ####################
    #identify nick
    ####################

    def identify()
        if !@data[:id]
            send "PRIVMSG NickServ IDENTIFY #{@data[:passwd]}"
            send "JOIN #{@data[:channel]}"
            @data[:id] = true
        end

    end # function identify

    ####################
    #establish connection
    ####################

    def connect()
        @irc = TCPSocket.open(@data[:server], @data[:port])
        send "USER turd bot 2.0 :the wreckening"
        send "NICK #{@data[:nick]}"
    end # function connect

    ####################
    #clean commands
    ####################

    def clean(s)
        chars = s.split(//)
        out = ""
        chars.each do |c|
            if c == "\\"
                next
            end

            out += "\\"
            out += c
        end
        out
    end # function clean

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
            when /^:(.+?)!(.+?)@(.+?)\sNOTICE\s(.+)\s:please choose a different nick.$/i
                if $1 != @data[:nick]
                    puts "[ identify request from #{$1}!#{$2}@#{$3} ]"
                    identify
                end
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:FORTUNE$/i
                if $1 != @data[:nick]
                    puts "[ fortune request from #{$1}!#{$2}@#{$3} ]"
                    cowsay($4)
                end
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:NEW NICK$/i
                if $1 != @data[:nick]
                    puts "[ new nick request from #{$1}!#{$2}@#{$3} ]"
                    rand_nick()
                end
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:COUNTDOWN (.+)$/i
                if $1 != @data[:nick]
                    puts "[ countdown #{s} from #{$1}!#{$2}@#{$3} ]"
                    countdown($5,$4)
                end
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:(.+)?TELL(.+)?EM (.+)$/i
                if $1 != @data[:nick]
                    puts "[ tellem #{$7} as #{$5} from #{$1}!#{$2}@#{$3} ]"
                    cowsay($4,"#{$7} -- #{$1}",$5)
                end
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:STOP(.+)?$/i
            puts "[ #{s} ]"
                if $1 != @data[:nick]
                    puts "[ stop request from #{$1}!#{$2}@#{$3} ]"
                    @data[:continue] = false
                end
            else
                puts s
        end
    end # function handle_server_inputs

    ####################
    #cowsay
    ####################

    def cowsay(chan,say="$(fortune)",form="default")
        if say != "$(fortune)"
            say = clean(say)
        end
        if form == nil or (!@cowlist.index(form[0..-2]))
            form = "default"
        end
        form.chomp
        output = `cowsay -f #{form} #{say}`
        output.split("\n").each { |line|
            chat(line,chan)
        }

    end # function cowsay

    ####################
    #countdown
    ####################

    def countdown(t,chan)
        t = t.to_i
        if t.is_a?(Integer) and chan.is_a?(String)
            chat("Countdown commencing...",chan)
            for i in 0..(t-1)
                if ! @data[:continue]
                    chat("Cancelling countdown!",chan)
                    @data[:continue] = true
                    return -1
                end 
                num = t - i
                count = sprintf("%d...",num)
                chat(count,chan)
                sleep(1)
            end
            cowsay(chan)
        else
            chat("Countdown postponed...",chan)
        end

    end # function countdown

    ####################
    #do work
    ####################

    def main_loop()
        begin
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
                    Thread.new{handle_server_input(s)}.pass
                end
            end
            
        end
        rescue Interrupt
        rescue Exception => detail
            #puts detail.message()
            #print detail.backtrace.join("\n")
            retry
        end
    end # function main_loop

end # class Turdbot

####################
#start
####################

irc = Turdbot.new('irc.haxzor.ninja', 6667, 'turdbot', '#botwars')
irc.connect()
irc.main_loop()
