(defproject event-api "current"
  :description "REST API for recording nucleotid.es benchmarking events."

  :dependencies [[org.clojure/clojure        "1.6.0"]
                 [org.clojure/data.json      "0.2.5"]
                 [ring/ring-jetty-adapter    "1.3.1"]
                 [ring-logger-timbre         "0.7.4"]
                 [com.taoensso/timbre        "4.1.4"]
                 [compojure                  "1.3.1"]
                 [com.cemerick/rummage       "1.0.1"]
                 [clj-time                   "0.9.0"]
                 [migratus                   "0.8.7"]
                 [com.amazonaws/aws-java-sdk "1.3.21.1"]]

  :plugins      [[lein-ring "0.9.0"]]

  :local-repo  "vendor/maven"

  :profiles {
    :dev        {:dependencies [[ring-mock "0.1.5"]]}
    :uberjar    {:aot :all}
    :api-server {:main event-api.core}})
