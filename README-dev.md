

## Dev setup

The [project documentation](http://dai-softsource.uni-koeln.de/projects/thesaurus/wiki) advises to use __ruby 2.3.1__ as in production.

As that version is no longer available in recent (19.04+, due to a missing libssl01-dev) ubuntu, I used __ruby 2.6.3__. The basic setup seems to work with that version as well.


1. create `config/database.yml` with:

```
development:
  adapter: postgresql
  encoding: unicode
  database: iqvoc_skosxl_development
  pool: 5
  username: iqvoc
  password: iqvoc
```

You might have to adjust the 'pg'-line in the Gemfile setting version 0.15:

```ruby
platforms :ruby do
  gem 'pg', '~> 0.15'
end
```

2. Create the database user:

```bash
sudo -u postgres psql
```

And in the postgres shell:

```sql
CREATE user iqvoc WITH PASSWORD 'iqvoc';
CREATE DATABASE iqvoc_skosxl_development;
GRANT ALL PRIVILEGES ON DATABASE iqvoc_skosxl_development TO iqvoc;
```

Allow local access with passwords by changing in `/etc/postgresql/11/main/pg_hba.conf` the line:

```
local all all peer
```

to

```
local all all md5
```

You might need to restart postgres, e.g. with `sudo service postgresql restart`

3. Run migrations

```
rake db:migrate
rake iqvoc:db:seed_all
```

4. Start dev server

```
rails s
```

The application is available on localhost:3000
