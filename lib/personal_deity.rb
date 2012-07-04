require "personal_diety/version"

module PersonalDeity
  class Skel
    def self.root
      Pathname(File.expand_path('../../skel', __FILE__))
    end

    def self.method_missing(method)
      root.join(method.to_s)
    end
  end

  def self.skel ; Skel ; end
end

