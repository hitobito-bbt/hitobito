# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Imap do

  let(:dummy_class) { Class.new(ApplicationController) { include Imap; public :attributes } }
  let(:dummy_object) { dummy_class.new }
  let(:imap) { double('imap') }

  let(:uid) { 1 }
  let(:mailbox) { 'INBOX' }
  let(:mailbox_to) { 'SPAM' }

  describe 'connects' do
    it 'to mail server', skip_before: true do
      allow(dummy_object).to receive(:connect)
      expect(dummy_object).to receive(:connect)

      dummy_object.send(:imap)
    end
  end

  describe do

    before do
      allow(dummy_object).to receive(:imap).and_return(imap)

      allow(imap).to receive(:select)
      allow(imap).to receive(:fetch) { [:something, :something_else] }
      allow(imap).to receive(:uid_fetch) { [:something] }
      allow(imap).to receive(:uid_move)
      allow(imap).to receive(:uid_store)
      allow(imap).to receive(:expunge)
      allow(imap).to receive(:login)
      allow(imap).to receive(:close)
      allow(imap).to receive(:disconnect)
      allow(imap).to receive(:status).and_return({ 'MESSAGES' => 2 })
    end

    context 'fetch' do
      it 'fetches mail' do
        expect(imap).to receive(:select).with(mailbox)
        expect(imap).to receive(:uid_fetch).with(uid, dummy_object.attributes)

        dummy_object.send(:fetch_by_uid, uid, mailbox)
      end

      it 'returns nil if invalid uid' do
        allow(imap).to receive(:uid_fetch).with(uid, anything) { nil }

        mail = dummy_object.send(:fetch_by_uid, uid, mailbox)

        expect(mail).to be_nil
      end
    end

    context 'move' do
      it 'moves mail' do
        expect(imap).to receive(:select).with(mailbox)
        expect(imap).to receive(:uid_move).with(uid, mailbox_to)

        dummy_object.send(:move_by_uid, uid, mailbox, mailbox_to)
      end

      it 'does nothing if uid invalid' do
        expect(imap).to receive(:select).with(mailbox)
        expect(imap).to receive(:uid_move).with(uid, mailbox_to)

        dummy_object.send(:move_by_uid, uid, mailbox, mailbox_to)
      end
    end


    it 'deletes mail' do
      expect(imap).to receive(:select).with(mailbox)
      expect(imap).to receive(:uid_store).with(uid, '+FLAGS', [:Deleted])
      # expect(imap).to receive(:uid_copy).with(uid, 'TRASH')
      expect(imap).to receive(:expunge)

      dummy_object.send(:delete_by_uid, uid, mailbox)
    end

    it 'fetches all from mailbox' do
      expect(imap).to receive(:select).with(mailbox)
      expect(imap).to receive(:status).with(mailbox, ['MESSAGES'])

      expect(dummy_object.send(:fetch_all_from_mailbox, mailbox)).to be_an_instance_of(Array)
    end

    it 'disconnects' do
      expect(imap).to receive(:close)
      expect(imap).to receive(:disconnect)

      dummy_object.send(:disconnect)
    end

  end

end
