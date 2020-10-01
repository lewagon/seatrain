module Seatrain
  class ConfigPrompter < Thor::Shell::Basic
    def prompt(setting, secure: false)
      existing = Seatrain.config.send(setting.to_sym)
      return existing if existing
      value = ask("Please, provide #{setting.titleize}", echo: !secure)
      Seatrain.config.send("#{setting}=".to_sym, value)
      $stdout.puts "\n Got it! 👌"
      value
    end
  end

  class SecretsPrompter < Thor::Shell::Basic
    def prompt(secret_name, secure: true)
      existing = Seatrain.config.secrets.dig(secret_name)
      return existing if existing
      value = ask("Please, provide value for secret #{secret_name.upcase}", echo: !secure)
      Seatrain.config.secrets[secret_name] = value
      $stdout.puts "\n Got it! 👌"
      value
    end

    def secrets_to_helm_flags
      Seatrain.config.required_secrets.map { |name|
        value = prompt(name.downcase, secure: true)
        ["--set-string", "global.commonSecrets.#{name.upcase}=#{value}"]
      }.flatten
    end
  end
end
