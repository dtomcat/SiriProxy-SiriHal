require 'cora'
require 'siri_objects'
require 'json'
require 'open-uri'
require 'timeout'
require 'pp'

class SiriProxy::Plugin::SiriHal < SiriProxy::Plugin
	attr_accessor :url
        attr_accessor :therm
        
	def initialize(config = {})
	self.url = config["url"]
	self.therm = config["therm"]
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
	#HVAC Commands
	listen_for(/What is the(?:current )? temperature in the house/i) do
		send_temp_house("STAT",self.therm,"GetTemp","0")
	end
	listen_for(/What is the(?:current )? temperature of(?:the )? (.*)/i) do |qDevice|
		send_temp_house("STAT",qDevice,"GetTemp","0")
	end
	listen_for(/What is the(?:current )? mode of(?:the )? (.*)/i) do |qDevice|
		send_temp_house("STAT",qDevice,"GetMode","0")
	end
	listen_for(/Set(?:the )? mode of(?:the )? (.*) to (.*) mode/i) do |qDevice,qMode|
		send_temp_house("STAT",qDevice,"SetMode",qMode)
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
		$webDevice = send_device.rstrip
		if($webDevice.include? " ")
			$webDevice = $webDevice.gsub(" ","%20")
    		end
		Thread.new {
			begin
				Timeout::timeout(20) do
				$status = JSON.parse(open(URI("#{self.url}?TYPE=#{send_type}&ITEM=#{$webDevice}&ACTION=#{send_action}")).read)
				end
			rescue Timeout::Error
				puts "[Warning - HAL2000] Unable to connect to the Siri Hal Server."
				say "Sorry, I was unable to connect to your house"
				request_completed
			end
			if($status["Return"]["ResponseSummary"]["StatusCode"] == 0) #successful
				if(send_type == "DEVICE") #Lights, etc.
					if(send_action == "ON")
						puts "[Info - HAL2000] #{$status["Return"]["Results"]["Device"]["Device"]} has been turned on"
						say "The " + $status["Return"]["Results"]["Device"]["Device"] + " has been turned on!"
						request_completed
					elsif(send_action == "OFF")
						puts "[Info - HAL2000] #{$status["Return"]["Results"]["Device"]["Device"]} has been turned off"
						say "The " + $status["Return"]["Results"]["Device"]["Device"] + " has been turned off!"
						request_completed
					else
						puts "[Info - HAL2000] Device status request: #{$status["Return"]["Results"]["Device"]["Device"]} - #{$status["Return"]["Results"]["Device"]["Status"]}"
						say "The " + $status["Return"]["Results"]["Device"]["Device"] + " is currently " + $status["Return"]["Results"]["Device"]["Status"]
						request_completed
					end
				elsif(send_type == "SENSOR")
					puts "[Info - HAL2000] Sensor status request: #{$status["Return"]["Results"]["Device"]["Device"]}, #{$status["Return"]["Results"]["Device"]["Status"]}"
					say "The " + $status["Return"]["Results"]["Device"]["Device"] + "'s sensor state is currently " + $status["Return"]["Results"]["Device"]["Status"]
					request_completed
				elsif(send_type == "SCENE")
					puts "[Info - HAL2000] #{$status["Return"]["Results"]["Device"]["Device"]} scene has been set"
					say "The scene has been set to " + $status["Return"]["Results"]["Device"]["Device"]
					request_completed
				elsif(send_type == "GROUP")
					if(send_action == "ON")
						puts "[Info - HAL2000] #{$status["Return"]["Results"]["Device"]["Device"]} has been turned on"
						say "The group " + $status["Return"]["Results"]["Device"]["Device"] + " has been turned on"
						request_completed
					else
						puts "[Info - HAL2000] Sensor status request: #{$status["Return"]["Results"]["Device"]["Device"]} has been turned off"
						say "The group " + $status["Return"]["Results"]["Device"]["Device"] + " has been turned off"
						request_completed
					end
				elsif(send_type == "MACRO")
					puts "[Info - HAL2000] #{$status["Return"]["Results"]["Device"]["Device"]} macro has been run"
					say "The " + $status["Return"]["Results"]["Device"]["Device"] + " macro has been run"
					request_completed
				else
					puts "[WARNING - HAL2000] The Siri Hal Server has been Shutdown.  Restart Siri Hal Server to use this plugin"
					say "The Siri Hal Server has been Shutdown!"
					request_completed
				end
			else
				puts "[WARNING - HAL2000] Error occured: #{$status["Return"]["ResponseSummary"]["ErrorMessage"]}"
				say "Sorry, there was an error, " + $status["Return"]["ResponseSummary"]["ErrorMessage"]
				request_completed
			end
			
		}
	end
	def send_temp_house(send_type, send_device, send_action, extra_action)
		$webDevice = send_device.rstrip
		if($webDevice.include? " ")
			$webDevice = $webDevice.gsub(" ","%20")
    		end
    		$extraAction = extra_action.rstrip
		if($extraAction.include? " ")
			$ExtraAction = $extraAction.gsub(" ","%20")
    		end
		Thread.new {
			begin
				if(send_action == "SetMode")
					Timeout::timeout(20) do
					$status = JSON.parse(open(URI("#{self.url}?TYPE=#{send_type}&ITEM=#{$webDevice}&ACTION=#{send_action}&Mode=#{$extraAction}")).read)
					end
				else
					Timeout::timeout(20) do
					$status = JSON.parse(open(URI("#{self.url}?TYPE=#{send_type}&ITEM=#{$webDevice}&ACTION=#{send_action}&Temp=#{$extraAction}")).read)
					end
				end
			rescue Timeout::Error
				puts "[Warning - HAL2000] Unable to connect to the Siri Hal Server."
				say "Sorry, I was unable to connect to your house"
				request_completed
			end
			if($status["Return"]["ResponseSummary"]["StatusCode"] == 0) #successful
				if(send_type == "STAT") #Lights, etc.
					if(send_action == "GetTemp")
						puts "[Info - HAL2000] #{$status["Return"]["Results"]["Device"]["Device"]} current temp: #{$status["Return"]["Results"]["Device"]["Status"]}"
						say "The " + $status["Return"]["Results"]["Device"]["Device"] + " shows a temperature of " + $status["Return"]["Results"]["Device"]["Status"] + " Degrees Fahrenheit!"
						request_completed
					elsif(send_action == "GetMode")
						puts "[Info - HAL2000] #{$status["Return"]["Results"]["Device"]["Device"]} Mode: #{$status["Return"]["Results"]["Device"]["Status"]}"
						say "The " + $status["Return"]["Results"]["Device"]["Device"] + " has been turned off!"
						request_completed
					elsif(send_action == "SetMode")
						puts "[Info - HAL2000] #{$status["Return"]["Results"]["Device"]["Device"]} mode set to #{$status["Return"]["Results"]["Device"]["Status"]}"
						say "The " + $status["Return"]["Results"]["Device"]["Device"] + " mode has been set to " + $status["Return"]["Results"]["Device"]["Status"]
						request_completed
					elsif(send_action == "SetHeatTemp")
						puts "[Info - HAL2000] #{$status["Return"]["Results"]["Device"]["Device"]} Heat Setpoint set to #{$status["Return"]["Results"]["Device"]["Status"]}"
						say "The " + $status["Return"]["Results"]["Device"]["Device"] + " heating set point has been set to " + $status["Return"]["Results"]["Device"]["Status"] + " degrees fahrenheit!"
						request_completed
					elsif(send_action == "SetCoolTemp")
						puts "[Info - HAL2000] #{$status["Return"]["Results"]["Device"]["Device"]} Cool Setpoint set to #{$status["Return"]["Results"]["Device"]["Status"]}"
						say "The " + $status["Return"]["Results"]["Device"]["Device"] + " cooling set point has been set to " + $status["Return"]["Results"]["Device"]["Status"] + " degrees fahrenheit!"
						request_completed
					elsif(send_action == "GetHeatTemp")
						puts "[Info - HAL2000] #{$status["Return"]["Results"]["Device"]["Device"]} Heat Setpoint is: #{$status["Return"]["Results"]["Device"]["Status"]}"
						say "The " + $status["Return"]["Results"]["Device"]["Device"] + " heating set point is " + $status["Return"]["Results"]["Device"]["Status"] + " degrees fahrenheit!"
						request_completed
					elsif(send_action == "SetCoolTemp")
						puts "[Info - HAL2000] #{$status["Return"]["Results"]["Device"]["Device"]} Cool Setpoint is: #{$status["Return"]["Results"]["Device"]["Status"]}"
						say "The " + $status["Return"]["Results"]["Device"]["Device"] + " cooling set point is " + $status["Return"]["Results"]["Device"]["Status"] + " degrees fahrenheit!"
						request_completed
					end
				end
			else
				puts "[WARNING - HAL2000] Error occured: #{$status["Return"]["ResponseSummary"]["ErrorMessage"]}"
				say "Sorry, there was an error, " + $status["Return"]["ResponseSummary"]["ErrorMessage"]
				request_completed
			end


		}
	end
end
