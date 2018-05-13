if defined?(Rails::Console)
    def show_mongo
        if Moped.logger == Rails.logger
            Moped.logger = Logger.new($stdout)
            true
        else
            Moped.logger = Rails.logger
            false
        end
    end
    alias :show_moped :show_mongo
end