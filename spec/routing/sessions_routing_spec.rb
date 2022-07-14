require 'rails_helper'

RSpec.describe SessionsController, type: :routing do
  describe 'routing' do
    it 'routes to #sign_in' do
      expect(post: '/sign_in').to route_to('sessions#sign_in', format: :json)
    end

    it 'routes to #sign_out' do
      expect(delete: '/sign_out').to route_to('sessions#sign_out', format: :json)
    end

    it 'routes to #forgot_password' do
      expect(post: '/forgot_password').to route_to('sessions#forgot_password', format: :json)
    end
  end
end
