(ns nucleotides.api.core
  (:gen-class)
  (:require [compojure.core          :refer [GET POST routes]]
            [compojure.handler       :refer [site]]
            [ring.middleware.params  :refer [wrap-params]]
            [ring.logger.timbre      :refer [wrap-with-logger]]
            [ring.adapter.jetty      :refer [run-jetty]]

            [nucleotides.api.database  :as db]
            [nucleotides.api.server    :as server]
            [nucleotides.util          :as util]))

(def variable-names
  {:access-key "AWS_ACCESS_KEY"
   :secret-key "AWS_SECRET_KEY"
   :domain     "AWS_SDB_DOMAIN"
   :endpoint   "AWS_ENDPOINT"})

(defn api [client domain]
  (let [route #(partial % client domain)]
    (-> (routes (GET  "/events/show.json"   [] (route server/show))
                (GET  "/events/lookup.json" [] (route server/lookup))
                (POST "/events/update"      [] (route server/update)))
        (wrap-with-logger)
        (wrap-params))))

(defn create-database-client! [credentials]
  (apply db/create-client (map credentials [:access-key :secret-key :endpoint])))

(defn -main [& args]
  (let [credentials (util/fetch-variables! variable-names)
        client      (create-database-client! credentials)]
    (run-jetty (site (api client (:domain credentials))) {:port 80})))
