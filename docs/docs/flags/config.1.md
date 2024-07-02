---
title: TRACKER-CONFIG
section: 1
header: Tracker Config Flag Manual
date: 2024/06
...

## NAME

tracker **\-\-config** - Define global configuration options for tracker

## SYNOPSIS

tracker **\-\-config** <file\>

## DESCRIPTION

The **\-\-config** flag allows you to define global configuration options (flags) for tracker. It expects a file in YAML or JSON format, among others (see [documentation](../install/config/kubernetes.md)).

All flags can be set in the config file, except for the following, which are reserved only for the CLI:

- **\-\-config**: This flag itself is reserved for the CLI and should not be set in the config file.
- **\-\-capture**
- **\-\-policy**
- **\-\-scope**
- **\-\-event**

Please refer to the [documentation](../install/config/kubernetes.md) for more information on the file format and available configuration options.
