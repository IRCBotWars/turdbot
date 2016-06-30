#!/usr/local/bin/ruby
#
# turdbot
#
# Description: Toy IRC bot 
#
# Author: Geno Nullfree


require "socket"
require "htmlentities"

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
	@trumpsay = ["I will build a great wall – and nobody builds walls better than me, believe me – and I’ll build them very inexpensively. I will build a great, great wall on our southern border, and I will make Mexico pay for that wall. Mark my words.",\
		"When Mexico sends its people, they’re not sending the best. They’re not sending you, they’re sending people that have lots of problems and they’re bringing those problems with us. They’re bringing drugs. They’re bring crime. They’re rapists… And some, I assume, are good people.",\
		"All of the women on The Apprentice flirted with me – consciously or unconsciously. That’s to be expected.",\
		"One of they key problems today is that politics is such a disgrace. Good people don’t go into government.",\
		"The beauty of me is that I’m very rich.",\
		"It’s freezing and snowing in New York – we need global warming!",\
		"The point is, you can never be too greedy.",\
		"My Twitter has become so powerful that I can actually make my enemies tell the truth.",\
		"My IQ is one of the highest — and you all know it! Please don't feel so stupid or insecure; it's not your fault.",\
		"The other candidates — they went in, they didn’t know the air conditioning didn’t work. They sweated like dogs...How are they gonna beat ISIS? I don’t think it’s gonna happen.",\
		"Usually if I fire somebody who’s bad, I’ll tell them how great they are. Because I don’t want to hurt people’s feelings.",
		"I don’t wear a ‘rug’—it’s mine. And I promise not to talk about your massive plastic surgeries that didn’t work.",\
		"When I think I’m right, nothing bothers me.",\
		"You know, wealthy people don’t like me.",\
		"I have a great relationship with the blacks.",\
		"I will be so good at the military your head will spin.",\
		"I had some beautiful pictures taken in which I had a big smile on my face. I looked happy, I looked content, I looked like a very nice person, which in theory I am.",\
		"My net worth fluctuates, and it goes up and down with markets and with attitudes and with feelings—even my own feelings—but I try.",\
		"If I ever ran for office, I’d do better as a Democrat than as a Republican–and that’s not because I’d be more liberal, because I’m conservative. But the working guy would elect me. He likes me. When I walk down the street, those cabbies start yelling out their windows.",\
		"I don’t want the Presidency. I’m going to help a lot of people with my foundation–and for me, the grass isn’t always greener.",\
		"Perhaps I shouldn’t campaign at all, I’ll just, you know, I’ll ride it right into the White House.",\
		"The concept of global warming was created by and for the Chinese in order to make U.S. manufacturing non-competitive.",\
		"How do you define leadership? I mean, leadership is a very strange word because, you know, some people have it, some people don’t and nobody knows why.",\
		"I’ve won many club championships and I was always the best athlete. But I’ve won many a club championship. It’s something that people don’t know unless they are with me and have played with me",\
		"If you have the money, having children is great.",\
		"A young rapper named Mac Miller just did a song called ‘Donald Trump’ and I’ve just been told it hit over 54 million… 54 million people. I want some money, Mac. Give me some money. I’m entitled to 25% at least. Mac, I want money!",\
		"The concept of shaking hands is absolutely terrible, and statistically I’ve been proven right."]
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
    #clean html
    ####################

    def rem_spaces(s)
        chars = s.split(//)
        out = ""
        chars.each do |c|
            if c == " "
                out += "%20"
            else
                out += c
            end
        end
        out
    end # function clean

    ####################
    #clean commands
    ####################

    def clean(s)
        s.gsub!(/^[-]*/,'')
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
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:(.+)?SHOW ME (.+)$/i
                if $1 != @data[:nick]
                    puts "[ show me #{$6} from #{$1}!#{$2}@#{$3} ]"
                    showme($4,$6)
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
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:(.+)?TRUMP(.+)?$/i
                if $1 != @data[:nick]
                    puts "[ triggered tRUMPsay from #{$1}!#{$2}@#{$3} ]"
                    cowsay($4,"#{@trumpsay.sample} -- Le Don",$5)
                end
            else
                puts s
        end
    end # function handle_server_inputs

    ####################
    #showme
    ####################

    def showme(chan,query)
        encoder = HTMLEntities.new
        qu = encoder.encode(query, :basic, :hexadecimal)
        q = rem_spaces(qu)
        chat("https://en.wikipedia.org/wiki/#{q}",chan)
    end # function showme

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
        if 1 == 0
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
            chat("Countdown postponed...get back to work! ;)",chan)
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

irc = Turdbot.new('localhost', 6667, 'turdbot', '#botwars')
irc.connect()
irc.main_loop()
