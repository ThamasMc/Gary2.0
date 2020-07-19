require "discordrb"
require_relative "command_library.rb"

bot = Discordrb::Commands::CommandBot.new token: ENV["BOT_TOKEN"], prefix: "!"

CommandLibrary.new(bot).add_commands

bot.run
