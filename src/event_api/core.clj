(ns event-api.core
  (:gen-class)
  (:require [compojure.core         :refer [GET POST routes]]
            [compojure.handler      :refer [site]]
            [ring.middleware.params :refer [wrap-params]]
            [ring.middleware.logger :refer [wrap-with-logger]]
            [ring.adapter.jetty     :refer [run-jetty]]
            [event-api.database     :as db]
            [event-api.server       :as server]))

(defn get-credentials []
  [(System/getenv "AWS_ACCESS_KEY")
   (System/getenv "AWS_SECRET_KEY")
   "https://sdb.us-west-1.amazonaws.com"])

(defn get-domain []
   (System/getenv "AWS_SDB_DOMAIN"))

(defn api [client domain]
  (let [route #(partial % client domain)]
    (-> (routes (GET  "/events/show.json"   [] (route server/show))
                (GET  "/events/lookup.json" [] (route server/lookup))
                (POST "/events"             [] (route server/update)))
        (wrap-with-logger)
        (wrap-params))))

(defn -main [& args]
  (let [client (apply db/create-client (get-credentials))
        domain (get-domain)]
    (run-jetty (site (api client domain)) {:port 80})))
