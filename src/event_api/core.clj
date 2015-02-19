(ns event-api.core
  (:gen-class)
  (:require [compojure.core         :refer [GET POST routes]]
            [compojure.handler      :refer [site]]
            [ring.middleware.params :refer [wrap-params]]
            [ring.middleware.logger :refer [wrap-with-logger]]
            [ring.adapter.jetty     :refer [run-jetty]]
            [clojure.tools.logging  :as log]
            [event-api.database     :as db]
            [event-api.server       :as server]))

(def credential-variable-names
  {:access-key "AWS_ACCESS_KEY"
   :secret-key "AWS_SECRET_KEY"
   :domain     "AWS_SDB_DOMAIN"
   :endpoint   "AWS_ENDPOINT"})

(defn get-env-var [v]
  (let [value (System/getenv v)]
    (if (nil? value)
      (do
        (log/fatal (str "Unbound environment variable: " v))
        (System/exit 1))
      (do
        (log/info (str "Using environment variable: " v "=" value))
        value))))

(defn api [client domain]
  (let [route #(partial % client domain)]
    (-> (routes (GET  "/events/show.json"   [] (route server/show))
                (GET  "/events/lookup.json" [] (route server/lookup))
                (POST "/events/update"      [] (route server/update)))
        (wrap-with-logger)
        (wrap-params))))

(defn fetch-credentials! []
  (->> credential-variable-names
       (map (fn [[k v]] [k (get-env-var v)]))
       (into {})))

(defn create-database-client! [credentials]
  (apply db/create-client (map credentials [:access-key :secret-key :endpoint])))

(defn -main [& args]
  (let [credentials (fetch-credentials!)
        client      (create-database-client! credentials)]
    (run-jetty (site (api client (:domain credentials))) {:port 80})))
