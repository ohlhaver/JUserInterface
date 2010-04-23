class UserFeedback < ActiveRecord::Base
  
  apply_simple_captcha
  
  # Tableless Record Hack Starts
  def self.columns() @columns ||= []; end
  def self.column(name, sql_type = nil, default = nil, null = true)  
    columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)  
  end
  # Tabless Record Hack Finishes
  
  column :email, :string 
  column :message, :text
  
  attr_accessor :user
  
  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
  validates_presence_of :message
  
  def deliver_support_email!
    Notifier.deliver_feedback!( :email => email, :message => message, :user => user )
  end
  
end