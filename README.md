# comments

Super basic naive ruby sinatra rest API that writes and reads json to disk. Can be used as unauthenticated comment system backend.

```
git clone git@github.com:ChillerDragon/comments.git
cd comments
bundle
ruby app.rb
```

```
curl -X POST http://localhost:4567/comments --data '{"author": "foo", "message": "bar"}'
curl 'http://localhost:4567/comments?from=0&count=1'
```

Checkout the index.html example. This is how you can get a comment system free of charge for you static html site.
No backend or database required. No signup or tokens.

