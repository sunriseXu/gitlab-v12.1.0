# frozen_string_literal: true

module EE
  module LegacyDiffNote
    extend ActiveSupport::Concern

    prepended do
      include Elastic::NotesSearch
    end
  end
end
