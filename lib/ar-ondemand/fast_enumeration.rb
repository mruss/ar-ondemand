module ActiveRecord
  module OnDemand
    class FastEnumeration

      def initialize(model, result_set)
        @result_set = result_set
        @column_models = model.columns.inject({}) { |h, c| h[c.name] = c; h }
        result_set.columns.each_with_index do |name, index|
          column_model = @column_models[name]
          self.define_singleton_method(name) do
            raise 'Not accessible outside of enumeration' if @row.nil?

            if column_model.respond_to?(:type)
              # Rails 5+
              t = column_model.type
              t.is_a?(::Symbol) ? @row[index] : t.cast(@row[index])
            elsif column_model.respond_to?(:type_cast)
              # TODO Remove this when dropping support for Rails 3
              column_model.type_cast @row[index]
            else
              # Rails 4.2 renamed type_cast into type_cast_from_database
              # This is not documented in their upgrade docs or release notes.
              # See https://github.com/rails/rails/commit/d24e640
              column_model.type_cast_from_database @row[index]
            end
          end
        end
      end

      def each
        @result_set.rows.each do |r|
          @row = r
          yield(self)
          nil
        end
      ensure
        @row = nil
      end

      def inject(inj)
        @result_set.rows.each do |r|
          @row = r
          inj = yield(inj, self)
        end
        inj
      ensure
        @row = nil
      end

      def size
        @result_set.rows.size
      end
    end
  end
end
