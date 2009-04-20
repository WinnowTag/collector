# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_collector_session',
  :secret      => '854b3b3072cb5276f24c41c81bef67d32ccea8308352125fd2db5df264420c92e175e34aad165fefdc99d21cf90079773815a010b177f391dbdb88a9a62b2295'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
