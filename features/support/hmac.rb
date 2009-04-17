# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
def hmac_headers(access_id, secret_key, headers = {})
  canonical_string = [headers.delete(:method), "application/x-www-form-urlencoded", nil, headers["DATE"], headers.delete(:path)].join("\n")
  puts canonical_string
  digest = OpenSSL::Digest::Digest.new('sha1')
  secret = Base64.encode64(OpenSSL::HMAC.digest(digest, secret_key, canonical_string)).strip
  header = headers.merge('Authorization' => "AuthHMAC #{access_id}:#{secret}")
  puts "#hmac_header: #{header}"
  header
end