class User < ActiveRecord::Base
  has_many :trips
  has_many :user_trips, :foreign_key => :attendee_id
  has_many :attended_trips, :through => :user_trips
  has_many :comments
  has_many :favorites
  has_many :favorited_trips, through: :favorites, source: :trip
  has_many :requests
  has_many :requested_trips, through: :requests, source: :trip
  has_many :flags
  has_many :active_relationships, class_name: :Relationship, foreign_key: 'follower_id', dependent: :destroy

  validates :first_name, :last_name, presence: true

  acts_as_messageable

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :omniauth_providers => [ :facebook ]

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0,20]
      user.first_name = auth.info.name.split()[0]   # assuming the user model has a name
      user.last_name = auth.info.name.split()[-1]
      user.picture_url = "#{ auth.info.image }?type=large" # assuming the user model has an image
    end
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end

  def mailboxer_name
    self.name
  end

  def mailboxer_email(object)
    self.email
  end

  def formatted_name
    self.first_name + " " + self.last_name[0] + "."
  end

  def attending?(trip)
    trip.attendees.include?(self)
  end

  def attend!(trip)
    self.user_trips.create!(attended_trip_id: trip.id)
  end

  def cancel!(trip)
    self.user_trips.find_by(attended_trip_id: trip.id).destroy
  end

  def favorite?(trip)
    self.favorited_trips.include?(trip)
  end

  def total_trip_attendees
    self.trips.map { |trip| trip.attendees.count }.reduce(:+)
  end
end
