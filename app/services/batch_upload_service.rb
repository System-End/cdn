# frozen_string_literal: true

class BatchUploadService
  MAX_FILES_PER_BATCH = 40

  Result = Data.define(:uploads, :failed)
  FailedUpload = Data.define(:filename, :reason)

  def initialize(user:, provenance:)
    @user = user
    @provenance = provenance
    @quota_service = QuotaService.new(user)
    @policy = @quota_service.current_policy
  end

  # Process batch
  def process_files(files)
    uploads = []
    failed = []

    # Track storage used in  batch
    batch_bytes_used = 0
    current_storage = @user.total_storage_bytes
    max_storage = @policy.max_total_storage

    files.each do |file|
      filename = file.original_filename
      file_size = file.size

      # Check per-file size
      if file_size > @policy.max_file_size
        failed << FailedUpload[
          filename,
          "File size (#{human_size(file_size)}) exceeds limit of #{human_size(@policy.max_file_size)}"
        ]
        next
      end

      # Check if file exceed total quota
      projected_total = current_storage + batch_bytes_used + file_size
      if projected_total > max_storage
        remaining = max_storage - current_storage - batch_bytes_used
        failed << FailedUpload[
          filename,
          "Would exceed storage quota (#{human_size(remaining)} remaining)"
        ]
        next
      end

      # Upload file
      begin
        upload = create_upload(file)
        uploads << upload
        batch_bytes_used += file_size
      rescue StandardError => e
        failed << FailedUpload[filename, "Upload error: #{e.message}"]
      end
    end

    Result[uploads, failed]
  end

  private

  def create_upload(file)
    content_type = Marcel::MimeType.for(file.tempfile, name: file.original_filename) ||
                   file.content_type ||
                   "application/octet-stream"

    upload_id = SecureRandom.uuid_v7
    sanitized_filename = ActiveStorage::Filename.new(file.original_filename).sanitized
    storage_key = "#{upload_id}/#{sanitized_filename}"

    blob = ActiveStorage::Blob.create_and_upload!(
      io: file.tempfile,
      filename: file.original_filename,
      content_type: content_type,
      key: storage_key
    )

    @user.uploads.create!(
      id: upload_id,
      blob: blob,
      provenance: @provenance
    )
  end

  def human_size(bytes)
    ActiveSupport::NumberHelper.number_to_human_size(bytes)
  end
end
