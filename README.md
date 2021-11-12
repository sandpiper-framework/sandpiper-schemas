# sandpiper-schemas

Sandpiper Framework API documentation and schemas

## About

These are the core specs for the Sandpiper Framework. More documentation and information will be added as we move this from being a behind-the-scenes effort to a fully integrated one.

Please feel free to visit us at https://sandpiperframework.net

## Overview

Four eventual specifications will live here.

1. [API specification](#api-specification)
1. [Plan Document schema](#plan-document)
1. [Database schema](#database-schema)
1. [Framework documentation](#framework-documentation)

### API Specification

The full Sandpiper API specification is provided as an OpenAPI 3 YAML schema. It is entirely contained in sandpiper_api.yaml.

We do our proving and much of the editing in the [Swagger Editor](https://github.com/swagger-api/swagger-editor). For an offline copy, you can just download the source code of the latest release, unzip it to a local folder somewhere, and use a web browser to open the index.html file that sits in the root directory. You can also use the editor online at [editor.swagger.io](https://editor.swagger.io/).

### Plan Document

The Plan Document is an XML file that codifies the agreement between two partners, and cannot be modified without both partners approving the change. The structure of this file is governed by an XML Schema Definition (XSD), found in sandpiper_plan.xsd.

There are a handful good graphical XSD editors like [Eclipse](https://www.eclipse.org) (Open Source; look for the Java and DSL Developer package), [oXygen XML](https://www.oxygenxml.com) (proprietary), and [XMLSpy](https://www.altova.com/xmlspy-xml-editor) (proprietary). We do all the editing at a text/source code level, to avoid artifacts, so if no graphical tool works for you, most good editors include an XSD plugin or mode.

### Database Schema

The Database Schema is a single SQL file that contains all the data and tables for a reference database implementation in SQLite 3. To use it, you can run this file inside an SQLite .db file, and it will drop/create tables and their relationships, as well as insert valid values for things like plan status and grain type.

Many tools exist to interact with SQLite, from raw Python (natively supported) to database clients like [dBeaver](https://dbeaver.io/) (open source) and the dedicated [SQLite Browser](https://sqlitebrowser.org/) (open source).

### Framework Documentation

The Framework Documentation is a markdown file containing a Sandpiper technical overview, reasoning, concepts, and implementation details. A PDF copy of the last version is available [here](https://sandpiperframework.net/wp-content/uploads/2021/04/Sandpiper_0.9.0.pdf), and the source markdown file is in the unstable branch of this repository. We created this before our API work had completed, so it is missing some critical details, but the overview, reasoning, and model are all still correct.
