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

(def environment-vars
   ["AWS_ACCESS_KEY" "AWS_SECRET_KEY" "AWS_SDB_DOMAIN" "AWS_REGION"])


(defn get-env-var [v]
  (let [value (System/getenv v)]
    (if (nil? value)
      (do
        (log/fatal (str "Unbound environment variable: " v))
        (System/exit 1))
      (do
        (log/info (str "Using environment variable: " v "=" value))
        value))))

(defn get-region-endpoint [v]
  (str "https://sdb." v ".amazonaws.com"))


(defn api [client domain]
  (let [route #(partial % client domain)]
    (-> (routes (GET  "/events/show.json"   [] (route server/show))
                (GET  "/events/lookup.json" [] (route server/lookup))
                (POST "/events/update"      [] (route server/update)))
        (wrap-with-logger)
        (wrap-params))))

(defn -main [& args]
  (let [[access-key secret-key domain region] (map get-env-var environment-vars)
        client (db/create-client access-key secret-key (get-region-endpoint region))]
    (run-jetty (site (api client domain)) {:port 80})))
