# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe GroupSetting do

  let(:group) { groups(:top_layer) }
  let(:setting) do
    GroupSetting.new(var: 'text_message_provider')
  end

  it 'returns all possible group settings' do
    settings = GroupSetting.settings
    expect(settings.size).to eq(1)
    expect(settings.keys).to include('text_message_provider')
  end

  it 'encrypts username, password' do
    setting.username = 'david.hasselhoff'
    setting.password = 'knightrider'
    setting.provider = 'aspsms'
    value = setting.value

    expect(value).not_to include('username')
    expect(value).to include('encrypted_username')

    expect(value).not_to include('password')
    expect(value).to include('encrypted_password')

    expect(value).not_to include('encrypted_provider')
    expect(value).to include('provider')

    encrypted_password = value['encrypted_password']
    expect(encrypted_password[:encrypted_value]).to be_present
    expect(encrypted_password[:iv]).to be_present

    encrypted_username = value['encrypted_username']
    expect(encrypted_username[:encrypted_value]).to be_present
    expect(encrypted_username[:iv]).to be_present
  end
end