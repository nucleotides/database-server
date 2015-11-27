(ns nucleotides.api.core
  (:gen-class)
  (:require [compojure.core      :refer [GET POST routes]]
            [ring.adapter.jetty  :refer [run-jetty]]

            [nucleotides.database.connection  :as con]
            [nucleotides.api.middleware       :as md]
            [nucleotides.api.benchmarks       :as benchmarks]
            [nucleotides.api.events           :as events]))

(defn api [database-client]
  (-> (routes
        (GET  "/benchmarks/show.json" []   (partial benchmarks/show   database-client))
        (POST "/benchmarks/"          []   (partial events/create     database-client))
        (GET  "/benchmarks/:id"       [id] (partial benchmarks/lookup database-client id)))))

(defn -main [& args]
  (-> (con/create-connection)
      (api)
      (md/middleware)
      (run-jetty {:port 80})))
