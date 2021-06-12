/*
	Copyright (C) 2021 The Sandpiper Authors. All rights reserved.

   	This document, part of the Sandpiper Framework software specification and package, is made available to you
   	under the terms of the Artistic License 2.0, which can be found at https://www.perlfoundation.org/artistic-license-20.html . For more information,
   	please feel free to visit us at https://www.sandpiperframework.org .

*/

-- Convenience for development
--- History logs
DROP TABLE IF EXISTS activity;

--- Local config entries
DROP TABLE IF EXISTS local_environment_variables;

--- Linking tables
DROP TABLE IF EXISTS node_multi_link_entries;
DROP TABLE IF EXISTS node_multi_links;
DROP TABLE IF EXISTS node_unique_links;

DROP TABLE IF EXISTS pool_multi_link_entries;
DROP TABLE IF EXISTS pool_multi_links;
DROP TABLE IF EXISTS pool_unique_links;

DROP TABLE IF EXISTS slice_multi_link_entries;
DROP TABLE IF EXISTS slice_multi_links;
DROP TABLE IF EXISTS slice_unique_links;

-- Core tables
DROP TABLE IF EXISTS grain_payloads;
DROP TABLE IF EXISTS slice_grains;

DROP TABLE IF EXISTS grains;

DROP TABLE IF EXISTS subscriptions;
DROP TABLE IF EXISTS plan_slices;
DROP TABLE IF EXISTS plans;

DROP TABLE IF EXISTS slices;
DROP TABLE IF EXISTS pools;
DROP TABLE IF EXISTS nodes;
DROP TABLE IF EXISTS instance_responders;
DROP TABLE IF EXISTS instances;
DROP TABLE IF EXISTS controllers;

--- Basic key values
DROP TABLE IF EXISTS slice_types;
DROP TABLE IF EXISTS unique_key_fields;
DROP TABLE IF EXISTS multi_key_fields;

-- Begin main structure
--- Locals
CREATE TABLE local_environment_variables (
		  local_environment_variable_id INTEGER PRIMARY KEY AUTOINCREMENT
		, variable_name TEXT UNIQUE
		, variable_value TEXT NULL
		, created_on DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
	);

--- Valid values
CREATE TABLE slice_types (
		  slice_type TEXT PRIMARY KEY NOT NULL
	);

CREATE TABLE unique_key_fields (
		  unique_key_field TEXT PRIMARY KEY NOT NULL
	);

CREATE TABLE multi_key_fields (
		  multi_key_field TEXT PRIMARY KEY NOT NULL
	);

--- Core Tables
CREATE TABLE controllers (
		  controller_uuid CHAR(36) PRIMARY KEY NOT NULL
		, controller_description TEXT 
		, admin_contact TEXT NOT NULL
		, admin_email TEXT NOT NULL
		, created_on DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
	);

CREATE TABLE instances (
		  instance_uuid CHAR(36) PRIMARY KEY NOT NULL
		, software_description TEXT NOT NULL
		, software_version TEXT NOT NULL
		, capability_level TEXT NOT NULL
		, created_on DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
	);

CREATE TABLE instance_responders (
		  instance_responder_id INTEGER PRIMARY KEY
		, instance_uuid CHAR(36) NOT NULL REFERENCES instances (instance_uuid)
		, capability_uri TEXT NOT NULL
		, capability_role TEXT NOT NULL
		, instance_responder_order INTEGER NOT NULL DEFAULT 0
		, created_on DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
		, UNIQUE (instance_uuid, capability_role)
	);

CREATE TABLE nodes (
		  node_uuid CHAR(36) PRIMARY KEY NOT NULL
		, controller_uuid CHAR(36) NOT NULL REFERENCES controllers (controller_uuid)
		, instance_uuid CHAR(36) NOT NULL REFERENCES instances (instance_uuid)
		, node_description TEXT NOT NULL
-- Allow one node to be flagged as this node, and only one
		, self_node TEXT NULL UNIQUE CHECK (self_node IS NULL OR self_node = 'yes')
		, created_on DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
		, UNIQUE (controller_uuid, instance_uuid)
	);

CREATE TABLE pools (
		  pool_uuid CHAR(36) PRIMARY KEY NOT NULL
		, node_uuid CHAR(36) NOT NULL REFERENCES nodes (node_uuid)
		, pool_description TEXT NOT NULL
		, pool_order INTEGER NOT NULL DEFAULT 0
		, created_on DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
		, UNIQUE (node_uuid, pool_order)
	);

CREATE TABLE slices (
		  slice_uuid CHAR(36) PRIMARY KEY NOT NULL
		, pool_uuid CHAR(36) NOT NULL REFERENCES pools (pool_uuid)
		, slice_description TEXT NOT NULL
		, slice_type TEXT NOT NULL REFERENCES slice_types (slice_type)
		, file_name TEXT NULL
		, slice_meta_data TEXT NULL
		, slice_order INTEGER NOT NULL DEFAULT 0
		, slice_grainlist_hash TEXT NULL
		, created_on DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
		, unique (pool_uuid, slice_description)
	);

CREATE TABLE grains (
		  grain_uuid CHAR(36) PRIMARY KEY NOT NULL
		, grain_key TEXT NOT NULL
		, grain_reference TEXT NOT NULL
		, created_on DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
	);

-- Grain payloads are stored separately to allow their contents to be selectively removed but the
-- history of their existence to be retained
CREATE TABLE grain_payloads (
		  grain_payload_id INTEGER PRIMARY KEY
		, grain_uuid CHAR(36) NOT NULL UNIQUE REFERENCES grains (grain_uuid)
		, encoding TEXT NOT NULL
		, payload BLOB NULL
	);

CREATE TABLE slice_grains (
		  slice_grain_id INTEGER PRIMARY KEY
		, slice_uuid CHAR(36) NOT NULL REFERENCES slices (slice_uuid)
		, grain_uuid CHAR(36) NOT NULL REFERENCES grains (grain_uuid)
		, grain_order INTEGER NOT NULL DEFAULT 0
		, UNIQUE (slice_uuid, grain_uuid)
		, UNIQUE (slice_uuid, grain_order)
	);

--- Plans
CREATE TABLE plans (
		  plan_uuid CHAR(36) PRIMARY KEY
		, primary_node_uuid CHAR(36) NOT NULL REFERENCES nodes (node_uuid)
		, secondary_node_uuid CHAR(36) NULL REFERENCES nodes (node_uuid)
-- NULL secondary node means the plan was invoked but not assigned to a known node secondary
		, status TEXT NOT NULL
		, status_message TEXT NULL
		, local_description TEXT NULL
		, created_on DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
		, UNIQUE (primary_node_uuid, secondary_node_uuid)
		, CHECK (primary_node_uuid <> secondary_node_uuid)
		, CHECK (status IN ('Invoked', 'Proposed', 'Approved', 'On Hold', 'Rejected', 'Obsolete'))
		, CHECK (
				(status IN ('Proposed', 'Approved', 'On Hold', 'Rejected', 'Obsolete') AND secondary_node_uuid IS NOT NULL) OR
				(status = 'Invoked' AND secondary_node_uuid IS NULL)
			)
	);

CREATE TABLE plan_slices (
		  plan_slice_id INTEGER PRIMARY KEY AUTOINCREMENT
		, plan_uuid CHAR(36) NOT NULL REFERENCES plans (plan_uuid)
		, slice_uuid CHAR(36) NOT NULL REFERENCES slices (slice_uuid)
		, plan_slice_order INTEGER NOT NULL DEFAULT 0
		, UNIQUE (plan_uuid, slice_uuid)
		, UNIQUE (plan_uuid, plan_slice_order)
	);

CREATE TABLE subscriptions (
		  subscription_uuid CHAR(36) PRIMARY KEY
		, plan_slice_id INTEGER NOT NULL REFERENCES plan_slices (plan_slice_id)
		, subscription_order INTEGER NOT NULL DEFAULT 0
		, created_on DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
		, UNIQUE (plan_slice_id, subscription_order)
	);

--- Linking tables
CREATE TABLE node_unique_links (
		  node_unique_link_uuid CHAR(36) PRIMARY KEY
		, node_uuid CHAR(36) NOT NULL REFERENCES nodes (node_uuid)
		, key_field TEXT NOT NULL REFERENCES unique_key_fields (unique_key_field)
		, key_value TEXT NOT NULL
		, key_description TEXT NULL
		, link_order INTEGER NOT NULL DEFAULT 0
		, UNIQUE (node_uuid, key_field)
	);

CREATE TABLE node_multi_links (
		  node_multi_link_uuid CHAR(36) PRIMARY KEY
		, node_uuid CHAR(36) NOT NULL REFERENCES nodes (node_uuid)
		, key_field TEXT NOT NULL REFERENCES multi_key_fields (multi_key_field)
		, link_order INTEGER NOT NULL DEFAULT 0
	);
		
CREATE TABLE node_multi_link_entries (
		  node_multi_link_entry_uuid CHAR(36) PRIMARY KEY
		, node_multi_link_uuid CHAR(36) NOT NULL REFERENCES node_multi_links (node_multi_link_uuid)
		, key_value TEXT NOT NULL
		, key_description TEXT NULL
		, link_entry_order INTEGER NOT NULL DEFAULT 0
		, UNIQUE (node_multi_link_uuid, key_value)
	);

CREATE TABLE pool_unique_links (
		  pool_unique_link_uuid CHAR(36) PRIMARY KEY
		, pool_uuid CHAR(36) NOT NULL REFERENCES pools (pool_uuid)
		, key_field TEXT NOT NULL REFERENCES unique_key_fields (unique_key_field)
		, key_value TEXT NOT NULL
		, key_description TEXT NULL
		, link_order INTEGER NOT NULL DEFAULT 0
		, UNIQUE (pool_uuid, key_field)
	);

CREATE TABLE pool_multi_links (
		  pool_multi_link_uuid CHAR(36) PRIMARY KEY
		, pool_uuid CHAR(36) NOT NULL REFERENCES pools (pool_uuid)
		, key_field TEXT NOT NULL REFERENCES multi_key_fields (multi_key_field)
		, link_order INTEGER NOT NULL DEFAULT 0
	);
		
CREATE TABLE pool_multi_link_entries (
		  pool_multi_link_entry_uuid CHAR(36) PRIMARY KEY
		, pool_multi_link_uuid CHAR(36) NOT NULL REFERENCES pool_multi_links (pool_multi_link_uuid)
		, key_value TEXT NOT NULL
		, key_description TEXT NULL
		, link_entry_order INTEGER NOT NULL DEFAULT 0
		, UNIQUE (pool_multi_link_uuid, key_value)
	);

CREATE TABLE slice_unique_links (
		  slice_unique_link_uuid CHAR(36) PRIMARY KEY
		, slice_uuid CHAR(36) NOT NULL REFERENCES slices (slice_uuid)
		, key_field TEXT NOT NULL REFERENCES unique_key_fields (unique_key_field)
		, key_value TEXT NOT NULL
		, key_description TEXT NULL
		, link_order INTEGER NOT NULL DEFAULT 0
		, UNIQUE (slice_uuid, key_field)
	);

CREATE TABLE slice_multi_links (
		  slice_multi_link_uuid CHAR(36) PRIMARY KEY
		, slice_uuid CHAR(36) NOT NULL REFERENCES slices (slice_uuid)
		, key_field TEXT NOT NULL REFERENCES multi_key_fields (multi_key_field)
		, link_order INTEGER NOT NULL DEFAULT 0
	);
		
CREATE TABLE slice_multi_link_entries (
		  slice_multi_link_entry_uuid CHAR(36) PRIMARY KEY
		, slice_multi_link_uuid CHAR(36) NOT NULL REFERENCES slice_multi_links (slice_multi_link_uuid)
		, key_value TEXT NOT NULL
		, key_description TEXT NULL
		, link_entry_order INTEGER NOT NULL DEFAULT 0
		, UNIQUE (slice_multi_link_uuid, key_value)
	);

-- Key value table data
INSERT INTO slice_types (slice_type) VALUES
	  ('aces-file'), ('aces-apps')
	, ('partspro-file'), ('napa-interchange-file')
	, ('pies-file'), ('pies-items'), ('pies-pricesheets')
	, ('asset-file'), ('asset-archive'), ('asset-files')
	, ('binary-blob'), ('xml-file'), ('text-file');

INSERT INTO unique_key_fields (unique_key_field) VALUES
	  ('autocare-vcdb-version'), ('autocare-pcdb-version'), ('autocare-qdb-version'), ('autocare-padb-version')
	, ('napa-validvehicles-version'), ('napa-translation-version')
	, ('primary-reference'), ('secondary-reference')
	, ('master-slice');

INSERT INTO multi_key_fields (multi_key_field) VALUES
	  ('autocare-branding-brand'), ('autocare-branding-brandowner'), ('autocare-branding-parent'), ('autocare-branding-subbrand')
	, ('autocare-pcdb-parttype'), ('autocare-vcdb-make')
	, ('dunbradstreet-duns')
	, ('model-year')
	, ('napa-branding-mfr'), ('napa-line-code'), ('napa-translation-pcc')
	, ('swift-bic')
	, ('tmc-vmrs-code');

-- Activity tables
--- General purpose -- could do with normalization but works for now
CREATE TABLE activity (
		  activity_id INTEGER PRIMARY KEY AUTOINCREMENT
		, activity_description varchar(255)
		, plan_uuid CHAR(36)
		, slice_uuid CHAR(36)
		, grain_uuid CHAR(36)
		, activity_timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
	);
