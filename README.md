# sandpiper-schemas

Schema specifications for the Sandpiper Framework API, database, and documents

## About

These are the core specs for the Sandpiper Framework. More documentation and information will be added as we move this from being a behind-the-scenes effort to a fully integrated one.

Please feel free to visit us at https://sandpiperframework.net

## Overview

Four eventual deliverables will live here.

1. [API specification](#api_specification)
1. [Plan Document schema](#plan_document)
1. [Database schema](#database_schema)
1. [Framework documentation](#framework_documention)

Currently we have the API spec, plan document schema, and database schema relatively stable and present in the repository. An out-of-date version of the documentation can be found on the Sandpiper Framework website, and will be merged here with caveats in a separate branch while we update it.

### API Specification

The full Sandpiper API specification is provided as an OpenAPI 3 YAML schema. It is entirely contained in sandpiper_api.yaml.

We do our proving and much of the editing in the [Swagger Editor](https://github.com/swagger-api/swagger-editor). For an offline copy, you can just download the source code of the latest release, unzip it to a local folder somewhere, and use a web browser to open the index.html file that sits in the root directory. You can also use the editor online at [editor.swagger.io](https://editor.swagger.io/).

### Plan Document

The Plan Document is an XML file that codifies the agreement between two partners, and cannot be modified without both partners approving the change. The structure of this file is governed by an XML Schema Definition (XSD), found in sandpiper_plan.xsd.

There are a handful good graphical XSD editors like [Eclipse](https://www.eclipse.org) (Open Source; look for the Java and DSL Developer package), [oXygen XML](https://www.oxygenxml.com) (proprietary), and [XMLSpy](https://www.altova.com/xmlspy-xml-editor) (proprietary). We do all the editing at a text/source code level, to avoid artifacts, so if no graphical tool works for you, most good editors include an XSD plugin or mode.

### Database Schema

### Framework Documentation