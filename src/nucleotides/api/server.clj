(ns nucleotides.api.server
  (:require [clojure.string             :as st]
            [clojure.data.json         :as json]
            [nucleotides.api.database  :as db]))

(defn update
  "Process a post event request. Return 202 if
  valid otherwise return appropriate HTTP error
  code otherwise."
  [client domain request]
  (let [params (:params request)]
    (if (db/valid-event? params)
      {:status 202
       :body   (db/create-event client domain (db/create-event-map params))}
      {:status 422
       :body   (->> (db/missing-parameters params)
                    (st/join ", " )
                    (str "Missing parameters: "))})))

(defn show
  "Return event matching the given ID. Return
  200 if event exists in database otherwise
  return 404."
  [client domain request]
   (let [params (:params request)]
      {:status 200
       :body   (->> (:id params)
                    (db/read-event client domain)
                    (json/write-str))}))

(defn lookup
  "Return events as a JSON document for the
  given query. Return an empty JSON document if
  no events match query."
  [client domain request]
  {:status 200
   :body   (->> (:query-params request)
                (db/build-query domain)
                (db/query-event client)
                (json/write-str))})
