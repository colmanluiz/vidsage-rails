class Api::V1::BaseController < ApplicationController
  # API-only base controller
  # No need to skip CSRF or set respond_to - we only do JSON
  
  private
  
  def render_success(data = nil, message = 'Success')
    render json: {
      success: true,
      message: message,
      data: data
    }
  end
  
  def render_error(message, status = :unprocessable_entity, errors = nil)
    render json: {
      success: false,
      message: message,
      errors: errors
    }, status: status
  end
  
  def render_not_found(message = 'Resource not found')
    render_error(message, :not_found)
  end
end 