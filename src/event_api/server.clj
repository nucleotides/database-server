(ns event-api.server
  (:require [clojure.string     :as st]
            [clojure.data.json  :as json]
            [event-api.database :as db]))

(defn post-event
  "Process a post event request. Return 202 if
  valid otherwise return appropriate HTTP error
  code otherwise."
  [client domain request]
  (let [params (:params request)]
    (if (db/valid-event? params)
      {:status 202
       :body   (db/create-event client domain (db/create-event-map params))}
      {:status 422
       :body   (str "Missing parameters: " (st/join ", " (db/missing-parameters params)))})))

(defn get-event
  "Return event matching the given ID. Return
  200 if event exists in database otherwise
  return 404."
  [client domain request]
   (let [params (:params request)]
      {:status 200
       :body   (json/write-str (db/read-event client domain (:id params)))}))
