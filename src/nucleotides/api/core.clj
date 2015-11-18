(ns nucleotides.api.core
  (:gen-class)
  (:require [compojure.core                  :refer [GET POST routes]]
            [compojure.handler               :refer [site]]
            [ring.middleware.keyword-params  :refer [wrap-keyword-params]]
            [ring.middleware.params          :refer [wrap-params]]
            [ring.logger.timbre              :refer [wrap-with-logger]]
            [ring.adapter.jetty              :refer [run-jetty]]

            [nucleotides.database.connection  :as con]
            [nucleotides.api.database         :as db]
            [nucleotides.api.benchmarks       :as benchmarks]
            [nucleotides.util                 :as util]))

(defn api [database-client]
  (-> (routes (GET "/benchmarks/show.json" [] (partial benchmarks/show database-client)))
      (wrap-with-logger)
      (wrap-keyword-params)
      (wrap-params)))

(defn -main [& args]
  (-> (con/create-connection)
      (api)
      (site)
      (run-jetty {:port 80})))
