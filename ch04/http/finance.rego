package httpapi.authz

subordinates = {"alice": [], "charlie": [], "bob": ["alice"], "betty": ["charlie"]}

import input as http_api

default allow = false

# Allow users to get their own salaries.
allow = true {
  http_api.method = "GET"
  http_api.path = ["finance", "salary", username]
  username = http_api.user
}

# Allow managers to get their subordinates' salaries.
allow = true {
  http_api.method = "GET"
  http_api.path = ["finance", "salary", username]
  subordinates[http_api.user][_] = username
}

# Allow managers to edit their subordinates' salaries only if the request came
# from user agent cURL and address 127.0.0.1.
allow = true {
  http_api.method = "POST"
  http_api.path = ["finance", "salary", username]
  subordinates[http_api.user][_] = username
  http_api.remote_addr = "127.0.0.1"
  http_api.user_agent = "curl/7.47.0"
}
