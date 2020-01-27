# Apps

This folder contains Geode client apps that demonstrate `geode-addon` components.

## List of Apps

1. [perf_test](perf_test/) - Performance analysis and troubleshooting test tools. Measure transaction latencies and monitor GC activities in conjunction with the Grafana app.
2. [Grafana](grafana/) - Out-of-the-box support for Grafana and Prometheus. Monitor the entire Geode cluster(s) in a single view.

## Running in `geode-addon` environment

All the apps have been preconfigured to run against the default Geode clusters created by the `create_cluster` command. If you change the cluster port numbers or have a multi-homed machine, then you may need to reflect the changes in apps configuration files for the apps to run properly. See each app's `README.md` file for instructions.

## Running against another cluster environment

If you wish to run against a cluster that has *not* been launched from the geode-addon environment, then you must include jars from both `lib/` and `test/` folders as follows:

Unix:
```
CLASSPATH=<geode-addon-dir>/lib/*:<geode-addon-dir>/plugins/*:$CLASSPATH
```

Windows:
```
CLASSPATH=<geode-addon-dir>\lib\*;<geode-addon-dir>\plugins\*;$CLASSPATH
```