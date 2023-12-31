# frozen_string_literal: true

class NewNoteWorker
  include ApplicationWorker

  # Keep extra parameter to preserve backwards compatibility with
  # old `NewNoteWorker` jobs (can remove later)
  # rubocop: disable CodeReuse/ActiveRecord
  def perform(note_id, _params = {})
    if note = Note.find_by(id: note_id)
      NotificationService.new.new_note(note) unless skip_notification?(note)
      Notes::PostProcessService.new(note).execute
    else
      Rails.logger.error("NewNoteWorker: couldn't find note with ID=#{note_id}, skipping job") # rubocop:disable Gitlab/RailsLogger
    end
  end

  private

  # EE-only method
  def skip_notification?(note)
    false
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

NewNoteWorker.prepend(EE::NewNoteWorker)
