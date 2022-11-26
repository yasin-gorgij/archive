# Cargo up and running

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `npm install` and `node node_modules/webpack/bin/webpack.js --mode development` inside the `assets` directory. If you want to use local node repository, use `verdaccio` container and `npm install --registry http://localhost:4873`
  * Start Phoenix endpoint with `iex -S mix phx.server`
  * Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
  * Add Farsi translation by `mix gettext.merge priv/gettext --locale fa`
  * Update translation by `mix gettext.extract --merge`
  
## Docker for development
> docker container run -it --rm --name verdaccio -p 4873:4873 -v ~/dev/local_node_modules/storage:/verdaccio/storage verdaccio/verdaccio:4.12.0

> docker container stop postgres; docker container run -p 5432:5432 --rm --name postgres -e POSTGRES_PASSWORD=postgres postgres:13.2-alpine

## Deploy to Fandogh Cloud
Run fandogh container in the project source directory

> `docker container run --rm -it --name fandogh -v "$PWD":/root/services fandogh-cli:latest`

then login to fandogh by `fandogh login` command and create image or publish image with newer version

> fandogh image init --name=fandogh-deldutt-cargo

> fandogh image publish --version 0.1.0

Deploy with manifest:

> fandogh service apply -f cargo.yml

> fandogh exec --service cargo 'cd bin && ./cargo eval "Cargo.Release.migrate"'

Deploy without manifest:
> fandogh service deploy --port 4000 --version 0.1.0 --name cargo

> fandogh exec --service cargo 'cd bin && ./cargo eval "Cargo.Release.migrate"'

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix

