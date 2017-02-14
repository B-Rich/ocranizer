require "yaml"

# tiny hack to operator work
struct Time
  def +(span : Ocranizer::OcraTimeSpan) : Time
    return span + self
  end
end

struct Ocranizer::OcraTimeSpan
  REGEXP = /(next|prev)?\s*(\d*)\s*(\w+)/

  ZERO_SPAN    = Time::Span.new(0)
  TEN_MIN_SPAN = Time::Span.new(0, 10, 0)
  HOUR_SPAN    = Time::Span.new(1, 0, 0)
  DAY_SPAN     = HOUR_SPAN * 24
  WEEK_SPAN    = DAY_SPAN * 7
  # above will require some hacks
  MONTH_SPAN = DAY_SPAN * 30
  YEAR_SPAN  = DAY_SPAN * 365

  def initialize(@string : String)
    @chunks = Array(NamedTuple(prefix: String, quantity: Int32, unit: String)).new
    scan_chunks
  end

  YAML.mapping(
    string: String,
    chunks: Array(NamedTuple(prefix: String, quantity: Int32, unit: String))
  )

  JSON.mapping(
    string: String,
    chunks: Array(NamedTuple(prefix: String, quantity: Int32, unit: String))
  )

  def scan_chunks
    @chunks.clear

    result = @string.scan(REGEXP)
    result.each do |r|
      @chunks << {
        prefix:   r[1].to_s.downcase,
        quantity: r[2].to_s != "" ? r[2].to_s.to_i : 1,
        unit:     r[3].to_s.downcase,
      }
    end
  end

  def +(time : Time) : Time
    @chunks.each do |c|
      unit = c[:unit]
      quantity = c[:quantity]
      prefix = c[:prefix]
      coeff = 1
      coeff = -1 if prefix == "prev"

      case unit
      when "now"
        # no change
      when "hour", "hours"
        time = add(time: time, span: HOUR_SPAN, coeff: coeff, quantity: quantity)
      when "day", "days"
        time = add(time: time, span: DAY_SPAN, coeff: coeff, quantity: quantity)
      when "week", "weeks"
        time = add(time: time, span: WEEK_SPAN, coeff: coeff, quantity: quantity)
      when "month", "months"
        time = add(time: time, span: MONTH_SPAN, coeff: coeff, quantity: quantity)
      when "year", "years"
        time = add(time: time, span: YEAR_SPAN, coeff: coeff, quantity: quantity)
      end
    end

    return time
  end

  def add(time : Time, span : Time::Span, coeff : Int32 = 1, quantity : Int32 = 1)
    return case span
    when YEAR_SPAN
      modify_years(time, coeff * quantity)
    when MONTH_SPAN
      modify_months(time, coeff * quantity)
    when WEEK_SPAN
      modify_weeks(time, coeff * quantity)
    when DAY_SPAN
      modify_days(time, coeff * quantity)
    else
      time + (span * coeff * quantity)
    end
  end

  def modify_years(time : Time, quantity : Int32)
    return Time.new(
      time.year + quantity,
      time.month,
      time.day,
      time.hour,
      time.minute
    )
  end


  def modify_months(time : Time, quantity : Int32)
    new_year = time.year
    new_month = time.month
    months_count = quantity.abs
    coeff = 1
    coeff = -1 if quantity < 0

    months_count.times do
      new_month += coeff

      if new_month > 12
        new_year += 1
        new_month = 1
      elsif new_month < 1
        new_year -= 1
        new_month = 12
      end
    end

    return Time.new(
      new_year,
      new_month,
      time.day,
      time.hour,
      time.minute
    )
  end

  def modify_weeks(time : Time, quantity : Int32)
    return modify_days(time: time, quantity: quantity * 7)
  end

  def modify_days(time : Time, quantity : Int32)
    new_time = time + (DAY_SPAN * quantity)

    return Time.new(
      new_time.year,
      new_time.month,
      new_time.day,
      time.hour,
      time.minute
    )
  end

end
