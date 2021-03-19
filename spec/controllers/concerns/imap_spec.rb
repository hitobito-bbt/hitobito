# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Imap do

  let(:imap) { double('imap') }
  let(:dummy_class) { Class.new(ApplicationController) { include Imap; public :attributes, :host, :email, :password } }
  let(:dummy_object) { dummy_class.new }

  let(:uid) { 1 }
  let(:mailbox) { 'INBOX' }
  let(:mailbox_to) { 'SPAM' }

  describe 'connects' do
    it 'to mail server', skip_before: true do
      args = dummy_object.host, dummy_object.email, dummy_object.password
      expect(dummy_object).to receive(:connect).once.with(*args)

      dummy_object.send(:imap)
    end
  end

  describe do

    before do
      allow(dummy_object).to receive(:imap).and_return(imap)
    end

    context 'fetch' do
      it 'fetches mail' do
        expect_select(mailbox)
        expect_fetch(uid, [imap_mail_data(uid)])

        mail = dummy_object.send(:fetch_by_uid, uid, mailbox)

        expect(mail).to be_instance_of(Hash)
        expect(mail.keys).to eq(dummy_object.attributes)
        expect(mail['UID']).to eq(uid)
      end

      it 'returns nil if invalid uid' do
        expect_select(mailbox)
        expect_fetch(uid, nil)

        mail = dummy_object.send(:fetch_by_uid, uid, mailbox)
        expect(mail).to be_nil
      end
    end

    it 'moves mail' do
      expect_select(mailbox)
      expect(imap).to receive(:uid_move).once.with(uid, mailbox_to)

      dummy_object.send(:move_by_uid, uid, mailbox, mailbox_to)
    end

    it 'deletes mail' do
      expect_select(mailbox)
      expect(imap).to receive(:uid_store).once.with(uid, '+FLAGS', [:Deleted])
      # expect(imap).to receive(:uid_copy).once.with(uid, 'TRASH')
      expect(imap).to receive(:expunge).once.with(no_args)

      dummy_object.send(:delete_by_uid, uid, mailbox)
    end


    it 'fetches all from mailbox' do
      expect_select(mailbox)
      expect(imap).to receive(:status).once.with(mailbox, ['MESSAGES']).and_return({'MESSAGES' => 2})
      mails_to_return = [imap_mail_data(1), imap_mail_data(2)]
      expect(imap).to receive(:fetch).once.with(1..2, dummy_object.attributes) { mails_to_return }

      mails = dummy_object.send(:fetch_all_from_mailbox, mailbox)

      expect(mails).to be_an_instance_of(Array)

      expect(mails).to all(be_instance_of(Hash))

      keys = mails.map { |x| x.keys }
      uids = mails.map { |x| x['UID'] }

      expect(keys).to all(eq(dummy_object.attributes))
      expect(uids).to eq([1, 2])
    end

    it 'disconnects' do
      expect(imap).to receive(:close).once.with(no_args)
      expect(imap).to receive(:disconnect).once.with(no_args)

      dummy_object.send(:disconnect)
    end

  end

  def expect_select(mailbox)
    expect(imap).to receive(:select).once.with(mailbox)
  end

  def expect_fetch(uid, result)
    expect(imap).to receive(:uid_fetch).once.with(uid, dummy_object.attributes) { result }
  end

  class FetchData
    attr_reader :attr
    def initialize(uid=0)
      @attr = { 'ENVELOPE' => 'test', 'UID' => uid, 'BODYSTRUCTURE' => '', 'BODY[TEXT]' => '' }
    end
  end

  def imap_mail_data(uid=0)
    FetchData.new(uid)
  end

end
