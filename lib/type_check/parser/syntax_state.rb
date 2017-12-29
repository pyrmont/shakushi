module TypeCheck
  module Parser
    class SyntaxState
      def initialize(state_names, counter_names_and_closers = nil)
        @status = Hash[state_names.map { |s| [s, :prohibited] }]
        if counter_names_and_closers.nil?
          @counter = Array.new
          @closers = Array.new
        else
          @counter = Hash[counter_names_and_closers[0].map { |c| [c, 0] }]
          @closers = counter_names_and_closers[1]
        end
      end

      def active?(key)
        @counter[key] > 0
      end

      def allow(key)
        @status[key] = :allowed
      end

      def allow_all(except: [])
        set_all :allowed, except: { exceptions: except, status: :prohibited }
      end

      def allowed?(status)
        @status[status] == :allowed
      end

      def count(key)
        @counter[key]
      end

      def decrement(key)
        msg = 'Trying to reduce count below zero.'
        raise RangeError, msg if @counter[key] == 0
        @counter[key] -= 1
      end

      def increment(key)
        @counter[key] += 1
      end

      def inside?(key)
        @counter[key] > 0
      end

      def outside?(key)
        @counter[key] == 0
      end

      def prohibit(key)
        @status[key] = :prohibited
      end

      def prohibit_all(except: [])
        set_all :prohibited, except: { exceptions: except, status: :allowed }
      end

      def prohibited?(status)
        @status[status] == :prohibited
      end

      def set_all(status, except: {})
        @status.transform_values! { |v| v = status }
        except[:exceptions].each { |k| @status[k] = except[:status] }
      end

      def unbalanced()
        @counter.reduce(Array.new) do |memo, c|
          (c[1] == 0) ? memo : memo.push(@closers[c[0]])
        end
      end
    end
  end
end