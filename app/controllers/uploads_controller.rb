# frozen_string_literal: true

class UploadsController < ApplicationController
  before_action :set_upload, only: [ :destroy ]

  def index
    @uploads = current_user.uploads.includes(:blob).recent

    if params[:query].present?
      @uploads = @uploads.search_by_filename(params[:query])
    end

    @uploads = @uploads.page(params[:page]).per(50)
  end

  def create
    uploaded_files = extract_uploaded_files

    if uploaded_files.empty?
      redirect_to uploads_path, alert: "Please select at least one file to upload."
      return
    end

    if uploaded_files.size > BatchUploadService::MAX_FILES_PER_BATCH
      redirect_to uploads_path, alert: "Too many files selected. Max #{BatchUploadService::MAX_FILES_PER_BATCH} files allowed per upload."
      return
    end

    service = BatchUploadService.new(user: current_user, provenance: :web)
    result = service.process_files(uploaded_files)

    flash_message = build_flash_message(result)

    if result.uplaods.any?
      redirect_to uploads_path, notice: flash_message
    else
    redirect_to uploads_path, alert: flash_message
    end
  rescue StandardError => e
    event = Sentry.capture_exception(e)
    redirect_to uploads_path, alert: "Upload failed: #{e.message} (Error ID: #{event&.event_id})"
    end

    def destroy
      authorize @upload

      @upload.destroy!
      redirect_back fallback_location: uploads_path, notice: "Upload deleted successfully."
    rescue Pundit::NotAuthorizedError
      redirect_back fallback_location: uploads_path, alert: "You are not authorized to delete this upload."
    end

    private

    def extract_uploaded_files
      files=[]

      # mult files via files[] param
      if params[:files].present?
        files.concat(Array(params[:files]))
      end

      if params[:file].present?
        files << params[:file]
    end

    files.reject(&:blank?)
    end


    content_type = Marcel::MimeType.for(uploaded_file.tempfile, name: uploaded_file.original_filename) || uploaded_file.content_type || "application/octet-stream"



    redirect_to uploads_path, notice: "File uploaded successfully!"
  rescue StandardError => e
    event = Sentry.capture_exception(e)
    redirect_to uploads_path, alert: "Upload failed: #{e.message} (Error ID: #{event&.event_id})"
  end

  files.reject(&:blank?)
  end

  def build_flash_message(result)
    messages = []
    if result.uploads.any?
      messages << "#{result.uploads.size} file(s) uploaded successfully"
    end

    if result.failed.any?
      messages << "#{result.failed.size} file(s) failed to upload"
    end

    messages.join(", ")
  end

  if result.failed.any?
    failures = result.failed.map { |f| "#{f.filename} (#{f.reason})" }.join(", ")
  parts << "Failed: #{failures}"
  end

  parts.join(". ")
  end

  def set_upload
    @upload = current_user.uploads.find(params[:id])
  end
end
