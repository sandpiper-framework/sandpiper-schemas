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

DROP TABLE IF EXISTS plan_slice_multi_links;
DROP TABLE IF EXISTS plan_slice_multi_link_entries;
DROP TABLE IF EXISTS plan_slice_unique_links;

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
DROP TABLE IF EXISTS plan_status_flows;
DROP TABLE IF EXISTS plan_statuses;

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
		, capability_description TEXT NOT NULL
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
--		, slice_order INTEGER NOT NULL DEFAULT 0	-- REMOVED 2021-07-23, use plan_slices.plan_slice_order
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
CREATE TABLE plan_statuses (
		  plan_status TEXT PRIMARY KEY
		, plan_status_description TEXT NOT NULL
		, plan_status_order INTEGER NOT NULL UNIQUE
	);

CREATE TABLE plan_status_flows (
		  plan_status_rule_id INTEGER PRIMARY KEY AUTOINCREMENT
		, plan_status_from TEXT NOT NULL REFERENCES plan_statuses (plan_status)
		, plan_status_to TEXT NOT NULL REFERENCES plan_statuses (plan_status)
		, UNIQUE (plan_status_from, plan_status_to)
		, CHECK (plan_status_from <> plan_status_to)
	);

CREATE TABLE plans (
		  plan_uuid CHAR(36) PRIMARY KEY
		, replaces_plan_uuid char(36) NULL
-- Replaces indicates that this plan was intended to supersede an existing agreement
		, primary_node_uuid CHAR(36) NOT NULL REFERENCES nodes (node_uuid)
		, secondary_node_uuid CHAR(36) NOT NULL REFERENCES nodes (node_uuid)
-- NULL secondary node means the plan was invoked but not assigned to a known node secondary
		, status TEXT NOT NULL REFERENCES plan_statuses (plan_status)
		, status_message TEXT NULL
		, status_on DATETIME NOT NULL
		, primary_approved_on DATETIME
		, secondary_approved_on DATETIME
		, plan_description TEXT NOT NULL
		, local_description TEXT NULL
		, created_on DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
		, UNIQUE (primary_node_uuid, secondary_node_uuid)
		, CHECK (primary_node_uuid <> secondary_node_uuid)
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
		  node_multi_link_id INTEGER PRIMARY KEY AUTOINCREMENT
		, node_uuid CHAR(36) NOT NULL REFERENCES nodes (node_uuid)
		, key_field TEXT NOT NULL REFERENCES multi_key_fields (multi_key_field)
		, link_order INTEGER NOT NULL DEFAULT 0
	);

CREATE TABLE node_multi_link_entries (
		  node_multi_link_entry_uuid CHAR(36) PRIMARY KEY
		, node_multi_link_id INTEGER NOT NULL REFERENCES node_multi_links (node_multi_link_id)
		, key_value TEXT NOT NULL
		, key_description TEXT NULL
		, link_entry_order INTEGER NOT NULL DEFAULT 0
		, UNIQUE (node_multi_link_id, key_value)
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
		  pool_multi_link_id INTEGER PRIMARY KEY AUTOINCREMENT
		, pool_uuid CHAR(36) NOT NULL REFERENCES pools (pool_uuid)
		, key_field TEXT NOT NULL REFERENCES multi_key_fields (multi_key_field)
		, link_order INTEGER NOT NULL DEFAULT 0
	);

CREATE TABLE pool_multi_link_entries (
		  pool_multi_link_entry_uuid CHAR(36) PRIMARY KEY
		, pool_multi_link_id INTEGER NOT NULL REFERENCES pool_multi_links (pool_multi_link_id)
		, key_value TEXT NOT NULL
		, key_description TEXT NULL
		, link_entry_order INTEGER NOT NULL DEFAULT 0
		, UNIQUE (pool_multi_link_id, key_value)
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
		  slice_multi_link_id INTEGER PRIMARY KEY AUTOINCREMENT
		, slice_uuid CHAR(36) NOT NULL REFERENCES slices (slice_uuid)
		, key_field TEXT NOT NULL REFERENCES multi_key_fields (multi_key_field)
		, link_order INTEGER NOT NULL DEFAULT 0
	);

CREATE TABLE slice_multi_link_entries (
		  slice_multi_link_entry_uuid CHAR(36) PRIMARY KEY
		, slice_multi_link_id INTEGER NOT NULL REFERENCES slice_multi_links (slice_multi_link_id)
		, key_value TEXT NOT NULL
		, key_description TEXT NULL
		, link_entry_order INTEGER NOT NULL DEFAULT 0
		, UNIQUE (slice_multi_link_id, key_value)
	);

CREATE TABLE plan_slice_unique_links (
		  plan_slice_unique_link_uuid CHAR(36) PRIMARY KEY
		, plan_slice_id INTEGER NOT NULL REFERENCES plan_slices (plan_slice_id)
		, key_field TEXT NOT NULL REFERENCES unique_key_fields (unique_key_field)
		, key_value TEXT NOT NULL
		, key_description TEXT NULL
		, link_order INTEGER NOT NULL DEFAULT 0
		, UNIQUE (plan_slice_id, key_field)
	);

CREATE TABLE plan_slice_multi_links (
		  plan_slice_multi_link_id INTEGER PRIMARY KEY AUTOINCREMENT
		, plan_slice_id INTEGER NOT NULL REFERENCES plan_slices (plan_slice_id)
		, key_field TEXT NOT NULL REFERENCES multi_key_fields (multi_key_field)
		, link_order INTEGER NOT NULL DEFAULT 0
	);

CREATE TABLE plan_slice_multi_link_entries (
		  plan_slice_multi_link_entry_uuid CHAR(36) PRIMARY KEY
		, plan_slice_multi_link_id INTEGER NOT NULL REFERENCES plan_slice_multi_links (plan_slice_multi_link_id)
		, key_value TEXT NOT NULL
		, key_description TEXT NULL
		, link_entry_order INTEGER NOT NULL DEFAULT 0
		, UNIQUE (plan_slice_multi_link_id, key_value)
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

INSERT INTO plan_statuses (plan_status, plan_status_description, plan_status_order) VALUES
  ('Proposed', 'A full plan that contains both actors'' information but has not yet been approved by both.', 10)
, ('Approved', 'Both actors have approved this plan, either explicitly or by being the one to propose its new status.', 20)
, ('On Hold', 'One or both parties have disabled synchronization of data under this plan for the current time.', 30)
, ('Terminated', 'One or both parties have decided that this plan is not suitable for use -- not that it''s old or outmoded, but that it is flawed or unacceptable.', 40)
, ('Obsolete', 'One or both parties have decided that this plan holds no value for future use and should be permanently disabled.', 50);

INSERT INTO plan_status_flows (plan_status_from, plan_status_to) VALUES
-- Everything can be killed except the dead themselves, and nothing can be invoked anew once it has lived, but..
-- Proposed plans can also be approved or rejected, but not on hold because they were never approved
  ('Proposed', 'Approved')
, ('Proposed', 'Terminated')
, ('Proposed', 'Obsolete')
-- The only thing Approved plans can't do is go back to being Invoked or Proposed; they're already in play
, ('Approved', 'On Hold')
, ('Approved', 'Terminated')
-- On Hold plans can also be proposed or rejected; the only route to approved is through proposed
, ('On Hold', 'Proposed')
, ('On Hold', 'Terminated')
, ('On Hold', 'Obsolete')
-- Rejected plans can be moved back to a proposed state or killed
, ('Terminated', 'Proposed')
, ('Terminated', 'Obsolete')
-- Obsolete plans can only be proposed
, ('Obsolete', 'Proposed');

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
