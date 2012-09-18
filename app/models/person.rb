# == Schema Information
#
# Table name: people
#
#  id                     :integer          not null, primary key
#  first_name             :string(255)
#  last_name              :string(255)
#  company_name           :string(255)
#  nickname               :string(255)
#  company                :boolean          default(FALSE), not null
#  email                  :string(255)
#  address                :string(1024)
#  zip_code               :integer
#  town                   :string(255)
#  country                :string(255)
#  gender                 :string(1)
#  birthday               :date
#  additional_information :text
#  contact_data_visible   :boolean          default(FALSE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  encrypted_password     :string(255)
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  name_mother            :string(255)
#  name_father            :string(255)
#  nationality            :string(255)
#  profession             :string(255)
#  bank_account           :string(255)
#  ahv_number             :string(255)
#  ahv_number_old         :string(255)
#  j_s_number             :string(255)
#  insurance_company      :string(255)
#  insurance_number       :string(255)
#

class Person < ActiveRecord::Base
  
  # Setup accessible (or protected) attributes for your model
  PUBLIC_ATTRS = [:id, :first_name, :last_name, :nickname, :company_name, :company, 
                  :email, :address, :zip_code, :town, :country]
  
  attr_accessible :first_name, :last_name, :company_name, :nickname, 
                  :email, :address, :zip_code, :town, :country,
                  :gender, :birthday, :additional_information,
                  :password, :password_confirmation, :remember_me
  
  include Contactable
  
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable
  
  ### ASSOCIATIONS
  
  has_many :roles, dependent: :destroy
  has_many :groups, through: :roles
  
  
  ### VALIDATIONS
  
  validates :email, uniqueness: true, allow_nil: true
  validates :gender, inclusion: %w(m w), allow_nil: true
 
 
  ### SCOPES

  scope :only_public_data, select(PUBLIC_ATTRS.collect {|a| "people.#{a}" })
  scope :contact_data_visible, where(:contact_data_visible => true)
  scope :preload_groups, scoped.extending(Person::PreloadGroups)
  scope :order_by_name, order('people.last_name, people.first_name')
  
  
  class << self
    # scope listing only people that have roles that are visible from above.
    # if group is given, only visible roles from this group are considered.
    def visible_from_above(group = nil)
      role_types = group ? group.role_types.select(&:visible_from_above) : Role.visible_types
      where(roles: {type: role_types.collect(&:sti_name)})
    end
    
    # scope listing all people with a role in the given layer.
    def in_layer(*groups)
      joins(roles: :group).where(groups: {layer_group_id: groups.collect(&:layer_group_id) }).uniq
    end
    
    # scope listing all people with a role in or below the given group.
    def in_or_below(group)
      joins(roles: :group).
      where("groups.lft >= :lft AND groups.rgt <= :rgt", lft: group.lft, rgt: group.rgt).uniq
    end
    
    # load people with/out external roles
    def external(ext = true)
      external_types = Role.all_types.select(&:external).collect(&:sti_name)
      if ext
        where(roles: {type: external_types})
      else
        where("roles.type NOT IN (?)", external_types)
      end
    end

    # devise api used when authenticating user
    def find_first_by_auth_conditions(conditions)
      select([:id, :first_name, :last_name, :nickname, :email, 
              :encrypted_password, :remember_created_at, :sign_in_count, 
              :current_sign_in_at, :current_sign_in_ip, 
              :last_sign_in_at, :last_sign_in_ip,
              :reset_password_token, :reset_password_sent_at]).
      where(email: conditions[:email]).
      preload_groups.
      first
    end
  end
  
  
  def to_s
    if company?
      company_name
    else
      name = "#{first_name} #{last_name}".strip
      name << " / #{nickname}" if nickname?
      name
    end
  end

  
  # All layers this person belongs to
  def layer_groups
    groups.collect(&:layer_group).uniq
  end
  
  # All groups where this person has the given permission(s)
  def groups_with_permission(permission)
    @groups_with_permission ||= {}
    @groups_with_permission[permission] ||= begin
      role_types = Role.types_with_permission(permission)
      roles.select {|r| role_types.include?(r.class) }.collect(&:group).uniq
    end
  end
  
  # Does this person have the given permission(s) in any group
  def permission?(permissions)
    groups_with_permission(permissions).present?
  end
  
  # All groups where this person has a role that is visible from above 
  def groups_where_visible_from_above
    role_types = Role.visible_types
    roles.select {|r| role_types.include?(r.class) }.collect(&:group).uniq
  end
  
  # All above groups where this person is visible from
  def above_groups_visible_from
    groups_where_visible_from_above.collect(&:hierarchy).flatten.uniq
  end
  
end
