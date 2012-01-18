require 'cora'
require 'siri_objects'
require 'json'
require 'open-uri'
require 'timeout'
require 'pp'

class SiriProxy::Plugin::SiriHal < SiriProxy::Plugin
	attr_accessor :url

	def initialize(config = {})
	self.url = config["url"]
	end

	$status = nil

	#Group Commands on
	listen_for(/Turn on the group (.*)/i) do |qDevice|
		send_to_house("GROUP",qDevice,"ON")
	end
	listen_for(/Turn the group (.*) on/i) do |qDevice|
		send_to_house("GROUP",qDevice,"ON")
	end
	listen_for(/Turn on group (.*)/i) do |qDevice|
		send_to_house("GROUP",qDevice,"ON")
	end
	listen_for(/Turn group (.*) on/i) do |qDevice|
		send_to_house("GROUP",qDevice,"ON")
	end
	#Group Commands off
	listen_for(/Turn off the group (.*)/i) do |qDevice|
	   	send_to_house("GROUP",qDevice,"OFF")
	end
	listen_for(/Turn the group (.*) off/i) do |qDevice|
		send_to_house("GROUP",qDevice,"OFF")
	end
	listen_for(/Turn off group (.*)/i) do |qDevice|
		send_to_house("GROUP",qDevice,"OFF")
	end
	listen_for(/Turn group (.*) off/i) do |qDevice|
		send_to_house("GROUP",qDevice,"OFF")
	end
	#Device Commands on
	listen_for(/Turn on the (.*)/i) do |qDevice|
		send_to_house("DEVICE",qDevice,"ON")
	end
	listen_for(/Turn on (.*)/i) do |qDevice|
		send_to_house("DEVICE",qDevice,"ON")
	end
	listen_for(/Turn the (.*) on/i) do |qDevice|
		send_to_house("DEVICE",qDevice,"ON")
	end
	listen_for(/Turn (.*) on/i) do |qDevice|
		send_to_house("DEVICE",qDevice,"ON")
	end
	#Device Commands off
	listen_for(/Turn off the (.*)/i) do |qDevice|
		send_to_house("DEVICE",qDevice,"OFF")
	end
	listen_for(/Turn off (.*)/i) do |qDevice|
		send_to_house("DEVICE",qDevice,"OFF")
	end
	listen_for(/Turn the (.*) off/i) do |qDevice|
		send_to_house("DEVICE",qDevice,"OFF")
	end
	listen_for(/Turn (.*) off/i) do |qDevice|
		send_to_house("DEVICE",qDevice,"OFF")
	end
	#Device Commands status
	listen_for(/Is the (.*) on/i) do |qDevice|
		send_to_house("DEVICE",qDevice,"STATUS")
	end
	listen_for(/Is the (.*) off/i) do |qDevice|
		send_to_house("DEVICE",qDevice,"STATUS")
	end
	listen_for(/Is (.*) on/i) do |qDevice|
		send_to_house("DEVICE",qDevice,"STATUS")
	end
	listen_for(/Is (.*) off/i) do |qDevice|
		send_to_house("DEVICE",qDevice,"STATUS")
	end
	#Sensor Commands status
	listen_for(/What is the Status of the (.*) sensor/i) do |qDevice|
		send_to_house("SENSOR",qDevice,"STATUS")
	end
	listen_for(/What is the current state of the (.*) sensor/i) do |qDevice|
		send_to_house("SENSOR",qDevice,"STATUS")
	end
	#****This one is for the Garage door.
	listen_for(/Is the (.*) closed/i) do |qDevice|
		send_to_house("SENSOR",qDevice,"STATUS")
	end
	listen_for(/Is the (.*) open/i) do |qDevice|
		send_to_house("SENSOR",qDevice,"STATUS")
	end
	#Scene Commands set
	listen_for(/Set the scene to (.*)/i) do |qDevice|
		send_to_house("SCENE",qDevice,"SET")
	end
	listen_for(/Set the seen to (.*)/i) do |qDevice|
		send_to_house("SCENE",qDevice,"SET")
	end
	listen_for(/Set the (.*) scene/i) do |qDevice|
		send_to_house("SCENE",qDevice,"SET")
	end
	listen_for(/Set the (.*) seen/i) do |qDevice|
		send_to_house("SCENE",qDevice,"SET")
	end
	#Macro Commands Run
	listen_for(/Run the macro (.*)/i) do |qDevice|
		send_to_house("MACRO",qDevice,"RUN")
	end
	listen_for(/Start the macro (.*)/i) do |qDevice|
		send_to_house("MACRO",qDevice,"RUN")
	end
	#Shutdown Command
	listen_for(/Shutdown the Siri server/i) do
		response = ask "Are you sure you want to shut down the server?" #ask the user for something
		if(response =~ /yes/i) #process their response
			send_to_house("SHUTDOWN","NONE","SHUTDOWN")
		else
			say "I didn't think so!"
			request_completed
		end
	end
	listen_for(/Shut down the Siri server/i) do
		response = ask "Are you sure you want to shut down the server?" #ask the user for something
		if(response =~ /yes/i) #process their response
			send_to_house("SHUTDOWN","NONE","SHUTDOWN")
		else
			say "I didn't think so!"
			request_completed
		end
	end

	def send_to_house(send_type, send_device, send_action)
		$webDevice = send_device
		if($webDevice.include? " ")
			$webDevice = $webDevice.gsub(" ","%20")
    		end
		say "One moment while I connect to your house..."
		Thread.new {
			begin
				Timeout::timeout(20) do
				$status = JSON.parse(open(URI("#{self.url}?TYPE=#{send_type}&ITEM=#{$webDevice}&ACTION=#{send_action}")).read)
				end
			rescue Timeout::Error
				say "Sorry, I was unable to connect to your house"
				request_completed
			end
			if($status["Return"]["ResponseSummary"]["StatusCode"] == 0) #successful
				say "House Connection Successful"
				if(send_type == "DEVICE") #Lights, etc.
					if(send_action == "ON")
						say "The " + $status["Return"]["Results"]["Device"]["Device"] + " has been turned on!"
					elsif(send_action == "OFF")
						say "The " + $status["Return"]["Results"]["Device"]["Device"] + " has been turned off!"
					else
						say "The " + $status["Return"]["Results"]["Device"]["Device"] + " is currently " + $status["Return"]["Results"]["Device"]["Status"]
					end
				elsif(send_type == "SENSOR")
					say "The " + $status["Return"]["Results"]["Device"]["Device"] + "'s sensor state is currently " + $status["Return"]["Results"]["Device"]["Status"]
				elsif(send_type == "SCENE")
					say "The scene has been set to " + $status["Return"]["Results"]["Device"]["Device"]
				elsif(send_type == "GROUP")
					if(send_action == "ON")
						say "The group " + $status["Return"]["Results"]["Device"]["Device"] + " has been turned on"
					else
						say "The group " + $status["Return"]["Results"]["Device"]["Device"] + " has been turned off"
					end
				elsif(send_type == "MACRO")
					say "The " + $status["Return"]["Results"]["Device"]["Device"] + " macro has been run"
				else
					say "The Siri Hal Server has been Shutdown!"
				end
			else
				say "Sorry, there was an error, " + $status["Return"]["ResponseSummary"]["ErrorMessage"]
			end
			request_completed
		}
	end
end