ActiveSupport.on_load(:active_record) do
  ActiveRecord::Associations::Builder::BelongsTo.send(:prepend, ActiveRecord::BelongsToIf::BuilderExtension)
  if ::ActiveRecord::VERSION::STRING.to_f > 5.1
    ActiveRecord::Associations::Preloader::Association.send(:prepend, ActiveRecord::BelongsToIf::PreloaderExtension)
  else
    ActiveRecord::Associations::Preloader::BelongsTo.send(:prepend, ActiveRecord::BelongsToIf::PreloaderExtension)
  end
end
