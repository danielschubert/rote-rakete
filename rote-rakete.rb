#!/usr/bin/env ruby
#
# Funny Ruby-Bot for the programming contest from Linux-Magazin 09/10
# THX an Ofr für das RubyBot-Scaffold.
# Ruby Version 1.8.7
#
#
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation; either version 3 of the License, or (at your 
# option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
# for more details.
# You should have received a copy of the GNU General Public License along with this program; if not, see <http://www.gnu.org/licenses/>.
#
require "socket"
######################
#  - WICHTIG -  
#  Default runden = 1 . Im Wettbewerb sollen 100 Runden gespielt werden. 
#  Das kann hier eingestellt werden:
#
runden = 1
######################
#
# globale Variablen
$server = "wettbewerb.linux-magazin.de"
$port = '3333'
$name= 'RoteRakete'
$connectString = 'Give Gas'
#
#
def geh_ins_netz  # TCP-Verbindung
  begin
    $sock = TCPSocket.new($server, $port)    
  # exception handling  
  rescue Errno::ETIMEDOUT
    $sock.close
    puts "Connection timed out:  #{$server}:#{$port} \n"
  rescue Errno::ECONNREFUSED
    puts "Connection refused:  #{$server}:#{$port} \n"
    $sock.close
    sleep(10)
  rescue Errno::EADDRNOTAVAIL
    puts "Could not conect to #{$server}:#{$port} \n"
    $sock.close
    exit(1)
  end
#  
  puts "Connected to #{$server}...\n"
end
#
def send(msg)  # sendet nachrichten an den $server
  $sock.print(msg + "\n")
end
#
# Strategie 
def strategie(meinepkt, anderepkt, count)
  #  wirf mind. 5 mal
  #  ausser mind. einmal wurde schon geworfen und der zufall sagt nein mit 1:6
  #  mach auf jeden fall weiter wenn ich schon 42 pkte habe oder der böse 36 
  #  oder die differenz > 7 pkt beträgt
  #  seeeehr simpel.. kein Siegertyp - ich erwarte irgendwas um die 50%.. mal sehen
#
  wuerfel = true
  if count >= 5 or (count != 0 and rand(6) == 2) 
    wuerfel = false
  end
  if meinepkt.to_i > 41 or anderepkt.to_i > 35 or (anderepkt.to_i - meinepkt.to_i > 7) or count < 2
    wuerfel = true
  end
  return wuerfel
end
#
# Spielschleife
def spiel
  count = 0  # Zähler für Würfe
  aktiv = 0  # 0 gegner am zug, 1 ich am zug
#
  loop do
    begin
      antw = $sock.gets
      command, arg1, arg2, arg3  = antw.split(' ', 4)      
      # exception handling
      rescue Errno::ECONNRESET
	puts "Connection reset by peer\n"
	sleep(10)
	break
      rescue NoMethodError  # fängt leere server-antwort ab. nötig seit neuer server version
        puts "Leere Server Antwort. Reconnect."
        $sock.close
	break
    end
#
    case command
      when "HELO"
	send "AUTH #{$name} #{$connectString}"
	puts "AUTH #{$name} #{$connectString}\n"
#      
      when "DENY"
	puts "DENY Verbindung abgelehnt wegen #{arg1}"
	break
#	 
      when "TURN"
	print antw
	if strategie(arg1, arg2, count)
	  aktiv = 1
	  count += 1
	  send "ROLL"
	  next
	end
	aktiv = 0
	count = 0
	send "SAVE"
#
      when "THRW"
	print antw
	if arg1.to_i == 6
	  if aktiv == 0
	    aktiv = 1
	    count = 0
	  elsif aktiv == 1
	    count = 0
	    aktiv = 0
	  end
	end
#
      when "DEF", "WIN"
	print antw
        $sock.close
	break
    end
  end
end
#
runden.times{
  geh_ins_netz
  spiel
}
# FIN

