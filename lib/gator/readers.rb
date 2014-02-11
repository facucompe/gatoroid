# encoding: utf-8
module Mongoid  #:nodoc:
  module Gator
      module Readers

        HOUR = "HOUR"
        DAY = "DAY"
        MONTH = "MONTH"
        DEFAULT_GRAIN = DAY

        # Today - Gets total for today on DAY level
        def today(opts={})
          total_for(Time.zone.now, DEFAULT_GRAIN, opts).to_i
        end

        # Yesterday - Gets total for tomorrow on DAY level
        def yesterday(opts={})
          total_for(Time.zone.now - 1.day, DEFAULT_GRAIN,opts).to_i
        end

        # On - Gets total for a specified day on DAY level
        def on(date,opts={})
          total_for(date, DEFAULT_GRAIN,opts).to_i
        end
        
        def last(total_days = 7,opts={})
          total_for((Time.zone.now - total_days.days)..Time.zone.now, DEFAULT_GRAIN, opts).to_i
        end

        # Range - retuns a collection for a specified range on specified level
        def range(date, grain=DEFAULT_GRAIN, opts={})
            data = collection_for(date,grain,opts)
            #puts "RAW DATA"
            #puts data.inspect
            #puts ""
            # Add Zero values for dates missing
            # May want to look into a way to get mongo to do this
            if date.is_a?(Range)
              start_date = date.first
              end_date = date.last

              
              case grain
                when HOUR
                  start_date = start_date.change(:sec=>0).change(:min => 0)
                  end_date = end_date.change(:sec=>0).change(:min => 0) - 1.hour
                  #data = data.group_by {|d| (Time.zone.at(d["date"].to_i).change(:sec=>0).change(:min => 0)).to_i }
                when DAY
                  start_date = start_date.change(:hour=>0).change(:sec=>0).change(:min => 0)
                  end_date = end_date.change(:hour=>0).change(:sec=>0).change(:min => 0)
                  #data = data.group_by {|d| (Time.zone.at(d["date"].to_i).change(:hour=>0).change(:sec=>0).change(:min => 0)).to_i }
                when MONTH
                  start_date = start_date.change(:day=>1).change(:hour=>0).change(:sec=>0).change(:min => 0)
                  end_date = end_date.change(:day=>1).change(:hour=>0).change(:sec=>0).change(:min => 0)
                  #data = data.group_by {|d| (Time.zone.at(d["date"].to_i).change(:day=>1).change(:hour=>0).change(:sec=>0).change(:min => 0)).to_i }
              end

              # Initialize result set array
              result_set = []
              
              # Build Result Set by Time Zone
              data.each do | di |
                case grain
                  when HOUR
                    result_set << {"date" => Time.zone.parse("#{di["day"]}-#{di["month"]}-#{di["year"]} #{di["hour"] -1}:00:00").to_i, @for => di[@for.to_s].to_i}
                  when DAY
                    result_set << {"date" => Time.zone.parse("#{di["day"]}-#{di["month"]}-#{di["year"]} 0:00:00").to_i, @for => di[@for.to_s].to_i}
                  when MONTH
                    result_set << {"date" => Time.zone.parse("1-#{di["month"]}-#{di["year"]} 0:00:00").to_i, @for => di[@for.to_s].to_i}
                end
              end
              
            end

            return result_set.sort_by { |di| di["date"]}
        end
        
        
        # Group_by - retuns a collection for a specific key
        def group_by(date,grain,opts={})
            # Get Offset
            if date.is_a?(Range)
                off_set = date.last.utc_offset
            else
                off_set = date.utc_offset
            end
            data = collection_for_group(date,HOUR,0,opts)
            return data
        end
        
      end
  end
end
