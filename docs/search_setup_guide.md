# Search setup guide

## Setup search locally

The Whitehall app relies on
[Rummager](https://github.com/alphagov/rummager) for document
indexing, and the
[GOV.UK frontend application](https://github.com/alphagov/frontend) to
serve results.

## Rebuilding Whitehall search index

The easiest way to get a search index is to replicate it from the Integration
environment.  This will not contain local changes to your content, but will be
enough for many tests. To fetch the replica, use the `replicate-elasticsearch.sh`
script from `govuk-docker` (as documented in [its README](https://github.com/alphagov/govuk-docker#how-to-replicate-data-locally)).
If you need to have local changes in your dev environment copied into the
search index, you will actually need to rebuild the search index.

The whitehall search index is called 'government'. Rebuilding of the whitehall
search index can now be done with a bulk data dump. This also supports
construction of a new detached index and seamless switchover from the
existing to the new index. There are two parts to this process, a
`rummager_export.rb` script in whitehall which dumps the whitehall data to
STDOUT, and a `bulk_load` script in rummager which accepts that data on STDIN
and loads it into rummager.

The `bulk_load` script also takes care of constructing the new offline index,
locking the index for writes (so that index write workers queue up waiting for
the new index to come online during indexing, avoiding data loss during
reindex), and seamlessly switching to the new index on completion.

Steps:

1. Make sure you have created the search indices by running the
following task from the search-api repo:

    ```
    SEARCH_INDEX=government bundle exec rake search:migrate_schema
    ```

2. Run the bulk export and load:

    ```
    bundle exec ./script/rummager_export.rb > government.dump
    bundle exec ./script/rummager_export.rb --detailed > detailed.dump
    ```

    then

    ```
    (cd ../rummager && bundle exec ./bin/bulk_load government) < government.dump
    (cd ../rummager && bundle exec ./bin/bulk_load detailed) < detailed.dump
    ```

## Search indexing paths

There are currently two paths for whitehall searchable classes to be indexed.
For a list of searchable classes, please refer to `Whitehall.edition_classes`
(in [lib/whitehall.rb](../lib/whitehall.rb)).

Indexing for searchable classes that inherit from `Edition` is triggered via the
`ServiceListeners::SearchIndexer` listening to the `force_publish` and `publish`
events.

To trigger indexing for an instance of these classes in unit/integration tests,
create an instance in a valid publishing state ('submitted', 'rejected') and
call `EditionService.new(your_instance).perform!`.

To trigger indexing for an instance of these classes in unit/integration tests,
create an instance in a valid publishing state ('submitted', 'rejected') and
call `save!` on it.
