# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        module Formatters
          class Dast
            def initialize(vulnerability)
              @vulnerability = vulnerability
            end

            def format(instance, hostname)
              {
                'category' => 'dast',
                'message' => vulnerability['name'],
                'description' => sanitize(vulnerability['desc']),
                'cve' => vulnerability['pluginid'],
                'severity' => severity(vulnerability['riskcode']),
                'solution' => sanitize(vulnerability['solution']),
                'confidence' => confidence(vulnerability['confidence']),
                'scanner' => { 'id' => 'zaproxy', 'name' => 'ZAProxy' },
                'identifiers' => [
                  {
                    'type' => 'ZAProxy_PluginId',
                    'name' => vulnerability['name'],
                    'value' => vulnerability['pluginid'],
                    'url' => "https://github.com/zaproxy/zaproxy/blob/w2019-01-14/docs/scanners.md"
                  },
                  {
                    'type' => 'CWE',
                    'name' => "CWE-#{vulnerability['cweid']}",
                    'value' => vulnerability['cweid'],
                    'url' => "https://cwe.mitre.org/data/definitions/#{vulnerability['cweid']}.html"
                  },
                  {
                    'type' => 'WASC',
                    'name' => "WASC-#{vulnerability['wascid']}",
                    'value' => vulnerability['wascid'],
                    'url' => "http://projects.webappsec.org/w/page/13246974/Threat%20Classification%20Reference%20Grid"
                  }
                ],
                'links' => links(vulnerability['reference']),
                'location' => {
                  'param' => instance['param'],
                  'method' => instance['method'],
                  'hostname' => hostname,
                  'path' => instance['uri'].sub(hostname, '')
                }
              }
            end

            private

            attr_reader :vulnerability

            SEVERITY_MAPPING = %w{info low medium high}.freeze
            CONFIDENCE_MAPPING = %w{ignore low medium high confirmed}.freeze

            # https://github.com/zaproxy/zaproxy/blob/cfb44f7e29f490d95b03830d90aadaca51a72a6a/src/scripts/templates/passive/Passive%20default%20template.js#L25
            # NOTE: ZAProxy levels: 0: info, 1: low, 2: medium, 3: high
            def severity(value)
              SEVERITY_MAPPING[Integer(value)] || 'unknown'
            rescue ArgumentError
              'unknown'
            end

            # NOTE: ZAProxy levels: 0: falsePositive, 1: low, 2: medium, 3: high, 4: confirmed
            def confidence(value)
              CONFIDENCE_MAPPING[Integer(value)] || 'unknown'
            rescue ArgumentError
              'unknown'
            end

            def links(reference)
              urls_from(reference).each_with_object([]) do |url, links|
                next if url.blank?

                links << { 'url' => url }
              end
            end

            def urls_from(reference)
              tags = reference.lines('</p>')
              tags.map { |tag| sanitize(tag) }
            end

            def sanitize(html_str)
              ActionView::Base.full_sanitizer.sanitize(html_str)
            end
          end
        end
      end
    end
  end
end
