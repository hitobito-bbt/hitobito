#  Copyright (c) 2012-2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module MailingLists::MailsHelper
  def active_folder

  end

  def action_button_cancel_participation
    action_button(
      t('event.participations.cancel_application.caption'),
      group_event_participation_path(parent, entry, @user_participation),
      'times-circle',
      data: {
        confirm: t('event.participations.cancel_application.confirmation'),
        method: :delete
      }
    )
  end
end
