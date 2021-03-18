# frozen_string_literal: true
require 'spec_helper'

describe CatchAllController do

  let(:top_leader) { people(:top_leader) }
  let(:params) { { uid: '20', mailbox_id: 'INBOX' } }
  let(:params_invalid) { { uid: '1', mailbox_id: 'INBOX' } }

  context 'admin' do

    before do
      sign_in(top_leader)
    end

    describe 'GET #index' do

      it 'can access' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'lists all mails' do
        get :index

        expect(assigns(:mails)).to be_instance_of(Hash)

        assigns(:mails).each do |_, mails|
          expect(mails).to be_instance_of(Array)

          unless mails.empty?
            expect(mails).to all(be_instance_of(CatchAllMail))
          end
        end

      end

    end

    describe 'GET #show' do

      it 'can access' do
        get :show, params: params
        expect(response).to have_http_status(:success)
      end

      it 'shows mail' do
        get :show, params: params
        expect(assigns(:mail)).to be_instance_of(CatchAllMail)
      end

      it 'redirects to index if invalid parameter' do
        get :show, params: params_invalid
        expect(response).to redirect_to mailbox_index_path
      end

    end

    describe 'PATCH #move' do

      it 'can access' do
        patch :move, params: params
        expect(response).to have_http_status(:success)
      end

      it 'redirects to index if invalid parameter' do
        patch :move, params: params_invalid
        expect(response).to redirect_to mailbox_index_path
      end

      xit 'redirects to index afterwards' do
        get :show, params: params
        expect(response).to redirect_to mailbox_index_path
      end

    end

    describe 'DELETE #destroy' do

      it 'can access' do
        delete :destroy, params: params
        expect(response).to have_http_status(:success)
      end

      it 'redirects to index if invalid parameters' do
        delete :destroy, params: params_invalid
        expect(response).to redirect_to mailbox_index_path
      end

      xit 'redirects to index afterwards' do
        delete :destroy, params: params
        expect(response).to redirect_to mailbox_index_path
      end

    end

  end

  context 'non-admin' do
    before { sign_in(people(:bottom_member)) }

    it 'can not access index' do
      expect do
        get :index
      end.to raise_error(CanCan::AccessDenied)
    end

    it 'can not access show' do
      expect do
        get :show, params: params
      end.to raise_error(CanCan::AccessDenied)
    end

    it 'can not access update' do
      params_more = params.merge( { move_to: 'INBOX' } )

      expect do
        patch :move, params: params_more
      end.to raise_error(CanCan::AccessDenied)
    end

    it 'can not access delete' do
      expect do
        delete :destroy, params: params
      end.to raise_error(CanCan::AccessDenied)
    end

  end

end
