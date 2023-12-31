# frozen_string_literal: true

module Vulnerabilities
  class OccurrencePresenter < Gitlab::View::Presenter::Delegated
    presents :occurrence

    def blob_path
      return '' unless respond_to?(:sha)
      return '' unless location.present? && location['file'].present?

      add_line_numbers(location['start_line'], location['end_line'])
    end

    private

    def add_line_numbers(start_line, end_line)
      return vulnerability_path unless start_line

      vulnerability_path.tap do |complete_path|
        complete_path << "#L#{start_line}"
        complete_path << "-#{end_line}" if end_line
      end
    end

    def vulnerability_path
      @vulnerability_path ||= project_blob_path(project, File.join(sha, location['file']))
    end
  end
end
