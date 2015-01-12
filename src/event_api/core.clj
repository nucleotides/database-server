(ns event-api.core
  (:require [compojure.core         :refer [GET POST routes]]
            [ring.middleware.params :refer [wrap-params]]
            [event-api.database     :as db]))

(defn post-event
  "Process a post event request. Return 202 if
  valid otherwise return appropriate HTTP error
  code otherwise."
  [request client domain]
  (let [params (:params request)]
    (if (db/valid-event? params)
      {:status 202
       :body (db/create-event client domain (db/create-event-map params))}
      {:status 422})))


(defn client []
  (db/create-client
    (System/getenv "AWS_ACCESS_KEY")
    (System/getenv "AWS_SECRET_KEY")
    "https://sdb.us-west-1.amazonaws.com"))

(def api
  (wrap-params
    (routes
      (POST "/events" [] post-event))))
