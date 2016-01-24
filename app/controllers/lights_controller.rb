class LightsController < ApplicationController
  def read
    render json: {success: true, on: REDIS.get('lights_on') == 'true'}
  end

  def edit
    @checked = $redis.get('lights_on') == 'true'
  end

  def update
    $redis.set('lights_on', params[:on])

    render json: {success: true}
  end
end
