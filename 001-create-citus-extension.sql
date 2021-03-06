-- wrap in transaction to ensure Docker flag always visible
BEGIN;
CREATE EXTENSION citus;

-- add Docker flag to node metadata
UPDATE pg_dist_node_metadata SET metadata=jsonb_insert(metadata, '{docker}', 'true');

--load pg_bigm into the database.
CREATE EXTENSION pg_bigm;
COMMIT;
