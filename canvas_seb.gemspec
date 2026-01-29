# frozen_string_literal: true

require_relative "lib/canvas_seb/version"

Gem::Specification.new do |spec|
  spec.name          = "canvas_seb"
  spec.version       = CanvasSeb::VERSION
  spec.authors       = ["Instructure"]
  spec.email         = ["info@instructure.com"]
  spec.summary       = "Summary of Canvas SEB"
  spec.description   = "Detailed description of Canvas SEB"
  spec.homepage      = "http://www.instructure.com"

  spec.files         = Dir["{app,lib,config}/**/*"]

  spec.add_dependency "rails", ">= 3.2"
end
