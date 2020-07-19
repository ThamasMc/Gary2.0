require "http"

class CommandLibrary
  def initialize(bot)
    @bot = bot
    @gary = %w[G R Y]
    @base_uri = "https://www.dnd5eapi.co/api/"
  end

  def add_commands
    @bot.command :ping do |event|
      "Pong"
    end

    @bot.command :gary do |event|
      @gary.insert(1, "A")
      @gary.join ""
    end

    @bot.command :gary_chill do |event|
      @gary = %w[G R Y]

      "*gary...*"
    end

    @bot.command :spell do |event, *args|
      spell_name = sanitize_args args
      resp = HTTP.get "#{@base_uri}spells/#{spell_name}" 

      return failed_to_find(event, args) if resp.status.code == 404

      payload = resp.body.readpartial
      payload = JSON.parse payload

      spell = parse_spell payload

      prettify_spell event, spell
    end

    @bot.command :nice do |event|
      "(ง ͠° ͟ل͜ ͡°)ง"
    end
  end

  def failed_to_find(event, args)
    # Try to get a list of suggestions based a search term dropping the first name of the spell for something like "Leomund's Tiny Hut"
    new_args = args.count > 1 ? args.drop(1) : args
    finds_nothing_text = "Gary can't seem to find spell: _**#{args.map(&:capitalize).join(" ")}**_. \n Maybe try out something else." 

    new_search = new_args.join("+").downcase
    resp = HTTP.get("#{@base_uri}spells/?name=#{new_search}")
    payload = JSON.parse resp.body.readpartial
    return finds_nothing_text if payload["count"].zero?

    event << "Gary failed to find spell: _**#{args.map(&:capitalize).join(" ")}**_"
    event << "Gary's thoughts on what you may have meant: "
    event << "```"
    
    payload["results"].each do |result|
      event << "#{result["name"]}"
    end

    event << "```"
  end

  def prettify_spell(event, spell)
    event << "Found Spell: #{spell[:name]}"
    event << "Level #{spell[:level]} #{spell[:school_name]} Spell"
    event << "Range: #{spell[:range]} | Casting Time: #{spell[:casting_time]}"
    event << "Duration: #{spell[:duration]} | Concentration: #{spell[:concentration]}"
    event << "======================================="
    event << spell[:description]
    event << "======================================="
    event << spell[:higher_level] unless spell[:higher_level].nil?
  end

  def parse_spell(payload)
    default_value = "N/A"
    {
      name: payload["name"] || default_value,
      level: payload["level"] || default_value,
      school_name: payload["school"]["name"] || default_value,
      range: payload["range"] || default_value,
      casting_time: payload["casting_time"] || default_value,
      duration: payload["duration"] || default_value,
      concentration: payload["concentration"] ? "Yes" : "No",
      description: payload["desc"][0] || default_value,
      higher_level: payload["higher_level"] ? payload["higher_level"][0] : nil
    }
  end

  def sanitize_args(arg_arr)
    arg_arr.join("-").gsub("'", "").strip.downcase
  end
end
