# kantox-cashier
Kantox' cashier challenge - top level directory

## Elixir server documentation
For the details of the implementation of this elixir challenge, see [cashier/README.md](https://github.com/dvadell/kantox-cashier/blob/main/cashier/README.md)

## How to check the project.
> [!NOTE]
> You can see it live in production [here](https://kantox.of.ardor.link/)!

1. Clone the project
```
git clone https://github.com/dvadell/kantox-cashier
```

2. Go to the just-created folder
```
cd kantox-cashier
```

3. Install the required version of elixir, erlang and node via asdf
```
asdf install
```

4. Run the docker container. This will run a postgresql container on port `15432`.
```
docker compose up -d
```

5. Run Phoenix.
```
mix deps.get
mix ecto.migrate
...
mix phx.server
```

> [!NOTE]
> These last instructions, "Run Phoenix", come from the top of my head. It's a normal phoenix project. Please be creative :)

6. Go to http://localhost:4000/

7. You can also run the development tools and tests
```
mix format
mix credo --strict
mix dialyzer
mix sobelow --config
MIX_ENV=test mix test
MIX_ENV=test mix coveralls.html
```

8. Work on your code, push it to a new branch and create a PR. Once the PR is merged to main, the CI/CD pipeline ( see [.github/workflows](https://github.com/dvadell/kantox-cashier/tree/main/.github/workflows) ) will run tests and check for security and formatting issues, and finally create a container image in github's registry.

## How to deploy
For the documentation on how to deploy this web app, see [deployment/README.md](https://github.com/dvadell/kantox-cashier/blob/main/deployment/README.md)

