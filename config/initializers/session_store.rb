# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_JUserInterface_session',
  :secret      => 'fadf299c400886d135372dcfce0c4ce0d9605ed35e14af84871d2e0947b0bbe5784ad07ce272c46624239a1fa0efbae033b98d1f6c835044c10ab1b1580348ee'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
