(defproject event-api "current"
  :description "FIXME: write description"
  :url "http://example.com/FIXME"
  :license {:name "Eclipse Public License"
            :url "http://www.eclipse.org/legal/epl-v10.html"}
  :dependencies [[org.clojure/clojure     "1.6.0"]
                 [ring/ring-jetty-adapter "1.3.1"]
                 [compojure               "1.3.1"]]
  :plugins      [[lein-ring "0.8.13"]]
  :ring     {:handler event-api.core/events}
  :profiles {:dev     {}
             :uberjar {:aot :all}})
