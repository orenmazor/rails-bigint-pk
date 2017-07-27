require 'rails/railtie'

class BigintPk::Railtie < Rails::Railtie
  initializer 'bigint_pk.install' do
    ActiveSupport.on_load(:active_record) do
      config = configurations[Rails.env]
      BigintPk.enable!(config['adapter'])
    end
  end
end
