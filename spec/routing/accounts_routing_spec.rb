require 'rails_helper'

RSpec.describe AccountsController, type: :routing do
  describe 'routing' do
    it 'routes to #show' do
      expect(get: '/accounts/1').to route_to('accounts#show', id: '1', format: :json)
    end

    it 'routes to #create via POST' do
      expect(post: '/accounts').to route_to('accounts#create', format: :json)
    end

    it 'routes to #activate via GET' do
      expect(get: '/accounts/1/activate/token')
        .to route_to('accounts#activate', id: '1', token: 'token', format: :json)
    end

    it 'routes to #update via PUT' do
      expect(put: '/accounts/1').to route_to('accounts#update', id: '1', format: :json)
    end

    it 'routes to #unlock via GET' do
      expect(get: '/accounts/1/unlock/token')
        .to route_to('accounts#unlock', id: '1', token: 'token', format: :json)
    end

    it 'routes to #reset_password via PATCH' do
      expect(patch: '/accounts/1/reset_password/token')
        .to route_to('accounts#reset_password', id: '1', token: 'token', format: :json)
    end

    it 'routes to #destroy' do
      expect(delete: '/accounts/1').to route_to('accounts#destroy', id: '1', format: :json)
    end
  end
end
