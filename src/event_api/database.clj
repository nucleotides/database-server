(ns event-api.database
  (:require [cemerick.rummage          :as sdb]
            [cemerick.rummage.encoding :as enc]
            [clojure.set               :refer [superset?]]
            [clojure.walk              :refer [keywordize-keys]])
  (:import  [com.amazonaws.services.simpledb AmazonSimpleDBClient]
            [com.amazonaws.auth              BasicAWSCredentials]))

(def required-event-keys
  #{:benchmark_id
    :benchmark_type_code
    :status_code
    :event_type_code})

(defn create-client [access-key secret-key endpoint]
  (let [client (new AmazonSimpleDBClient
                    (new BasicAWSCredentials access-key secret-key))]
    (.setEndpoint client endpoint)
    (assoc enc/keyword-strings :client client)))

(defn missing-parameters [request]
  (set (filter #(not (contains? request %)) required-event-keys)))

(defn valid-event? [request]
  (empty? (missing-parameters request)))

(defn create-event-map [request-params]
  (let [event (select-keys request-params required-event-keys)]
    (assoc (keywordize-keys event) ::sdb/id (str (System/nanoTime)))))


(defn create-event [client domain event]
  (do
    (sdb/put-attrs client domain event)
    (::sdb/id event)))

(defn read-event [client domain event-id]
  (sdb/get-attrs client domain event-id))
