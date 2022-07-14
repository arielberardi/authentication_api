# AUTHENTICATION API TEMPLATE

This is a example implementation of an authentication services to work for a microservice arquitecture.

Principal differences with other services:
* Use Redis to store and use token validations
* Use Sidekiq for mailer services

## Current functionalities

* Sessions:
  * Sign In
  * Sign Out
  * Forgot Password
* Account Management:
  * Sign Up / Create
  * Activate account
  * Unlock acocunt
  * Reset password
  * Show account
  * Update account
  * Destroy acocunt

## How to run

1. Clone this repository
2. Install redis and set the config on `redis.yml`
3. From root folder run `bundle install`
4. Launch sidekiq in another terminal: `bundle exec sidekiq`
5. Config credentials for database and keys (see credentials.yml.sample for details)
6. Set the database `rails db:create db:migrate`
7. Run the application `rails s`

## Disclaimer

This is a educational example and should not be considered for production use.
