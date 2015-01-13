(defproject event-api "current"
  :description "REST API for recording nucleotid.es benchmarking events."

  :dependencies [[org.clojure/clojure        "1.6.0"]
                 [org.clojure/data.json      "0.2.5"]
                 [ring/ring-jetty-adapter    "1.3.1"]
                 [compojure                  "1.3.1"]
                 [com.cemerick/rummage       "1.0.1"]
                 [clj-time                   "0.9.0"]
                 [com.amazonaws/aws-java-sdk "1.3.21.1"]]
  :plugins      [[lein-ring "0.9.0"]]


  :main event-api.core

  :profiles {
    :dev     {:dependencies [[ring-mock "0.1.5"]]}
    :uberjar {:aot :all}})

