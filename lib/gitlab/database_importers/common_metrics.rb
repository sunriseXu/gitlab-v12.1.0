# frozen_string_literal: true

module Gitlab
  module DatabaseImporters
    module CommonMetrics
    end
  end
end

Gitlab::DatabaseImporters::CommonMetrics.prepend(EE::Gitlab::DatabaseImporters::CommonMetrics)
