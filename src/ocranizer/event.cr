require "yaml"
require "colorize"

require "./ocra_time"
require "./collection"
require "./entity"

class Ocranizer::Event
  include Ocranizer::Entity

  YAML.mapping(
    id: String,
    user: String,
    name: String,
    place: String,
    desc: String,
    category: String,
    tags: Array(String),
    time_from: OcraTime,
    time_to: OcraTime
  )

  def initialize
    @id = Time.now.to_s("%Y%m%d%H%M%S%L")
    @user = String.new

    @time_from = OcraTime.new_time_from
    @time_to = OcraTime.new_time_to

    @name = String.new
    @place = String.new
    @desc = String.new

    @category = String.new
    @tags = Array(String).new
  end

  property :user, :time_from, :time_to, :name, :desc, :place, :category
end
