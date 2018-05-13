class DayCalculation
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::History::Trackable

  track_history :on => [:locked],       # track title and body fields only, default is :all
                :modifier_field => :modifier, # adds "belongs_to :modifier" to track who made the change, default is :modifier
                :modifier_field_inverse_of => :nil, # adds an ":inverse_of" option to the "belongs_to :modifier" relation, default is not set
                :version_field => :version,   # adds "field :version, :type => Integer" to track current version, default is :version
                :track_create   =>  false,    # track document creation, default is false
                :track_update   =>  true,     # track document updates, default is true
                :track_destroy  =>  false     # track document destruction, default is false

  has_many :calculations
  belongs_to :restaurant

  field :pos_day_total, type: Float
  field :date, type: Date
  field :locked, type: Boolean, default: false

  validates :date, presence: true

  def toggle_lock_status(data)
    if data[:locked] == 'true'
      unlock(data[:modifier])
    else
      lock(data[:modifier])
    end
  end

  def lock(person)
    self.update_attributes(locked: true, modifier: person)
    save
  end

  def unlock(person)
    self.update_attributes(locked: false, modifier: person)
    save
  end
end