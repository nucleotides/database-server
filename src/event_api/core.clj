(ns event-api.core
  (:gen-class)
  (:require [compojure.core         :refer [GET POST routes]]
            [compojure.handler      :refer [site]]
            [ring.middleware.params :refer [wrap-params]]
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
  (wrap-params
    (routes
      (GET  "/events/show.json" [] (partial server/get-event  client domain))
      (POST "/events"           [] (partial server/post-event client domain)))))

(defn -main [& args]
  (let [client (apply db/create-client (get-credentials))
        domain (get-domain)]
    (run-jetty (site (api client domain)) {:port 8080})))
