module Seatrain
  class ConfigPrompter < Thor::Shell::Basic
    def initialize
      @prompt = TTY::Prompt.new
    end

    def prompt(setting, secure: false)
      existing = Seatrain.config.send(setting.to_sym)
      return existing if existing
      value = if secure
        @prompt.mask("Please, provide #{setting.titleize}:", required: true)
      else
        @prompt.ask("Please, provide #{setting.titleize}:", required: true)
      end
      Seatrain.config.send("#{setting}=".to_sym, value) if value.present?
      @prompt.ok "Got it! 👌"
      value
    end
  end

  class SecretsPrompter < Thor::Shell::Basic
    def initialize
      @prompt = TTY::Prompt.new
    end

    def prompt(secret_name)
      existing = Seatrain.config.secrets.dig(secret_name)
      return existing if existing
      value = @prompt.mask("Please, provide value for secret #{secret_name.upcase}:", required: true)
      Seatrain.config.secrets[secret_name] = value if value.present?
      @prompt.ok "Got it! 👌"
      value
    end

    def secrets_to_helm_flags
      Seatrain.config.required_secrets.map { |name|
        value = prompt(name.downcase)
        ["--set-string", "global.commonSecrets.#{name.upcase}=#{value}"]
      }.flatten
    end
  end
end
