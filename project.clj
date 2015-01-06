(defproject event-api "current"
  :description "REST API for recording nucleotid.es benchmarking events."

  :dependencies [[org.clojure/clojure     "1.6.0"]
                 [ring/ring-jetty-adapter "1.3.1"]
                 [compojure               "1.3.1"]]
  :plugins      [[lein-ring "0.8.13"]]

  :ring     {:handler event-api.core/api}

  :profiles {
    :dev     {:dependencies [[ring-mock "0.1.5"]]}
    :uberjar {:aot :all}})
