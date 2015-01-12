(ns event-api.core
  (:require [compojure.core         :refer [GET POST routes]]
            [ring.middleware.params :refer [wrap-params]]
            [event-api.database     :as db]))

(defn post-event
  "Process a post event request. Return 202 if
  valid otherwise return appropriate HTTP error
  code otherwise."
  [request client domain]
  (let [eid    (db/generate-event-id)
        params (:params request)]
    (if (db/valid-event? params)
      (do
        ((db/create-event client domain eid params)
        {:status 202 :body eid})
      {:status 422}))))

(def api
  (wrap-params
    (routes
      (POST "/events" [] post-event))))
