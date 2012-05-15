# SpyBoy

To set up:

4. Sort Gems and push to GitHub:

  bundle install
  git init
  git add .
  git commit -m "Initial commit"
  gh create-from-local
  
5. Push to Heroku:

  heroku create
  heroku addons:add custom_domains
  heroku rename [YOUR APP NAME]
  git push heroku master
  heroku open

6. Start Work!

# To work

    rvm use 1.9.3
    rvm gemset use spyboy
    bundle install