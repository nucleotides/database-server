(ns event-api.database
  (:require [cemerick.rummage          :as sdb]
            [cemerick.rummage.encoding :as enc]
            [clojure.set               :refer [superset?]])
  (:import  [com.amazonaws.services.simpledb AmazonSimpleDBClient]
            [com.amazonaws.auth              BasicAWSCredentials]))

(def required-event-keys
  #{"benchmark_id"
    "benchmark_type_code"
    "status_code"
    "event_type_code"})

(defn create-client [access-key secret-key endpoint]
  (let [client (new AmazonSimpleDBClient
                    (new BasicAWSCredentials access-key secret-key))]
    (.setEndpoint client endpoint)
    (assoc enc/keyword-strings :client client)))

(defn valid-event? [request]
  (let [request-keys (set (keys request))]
    (superset? request-keys required-event-keys)))

(defn generate-event-id []
  (str (System/nanoTime)))

(defn create-event [client domain event-id request-params]
  (let [event (select-keys required-event-keys request-params)]
    (sdb/put-attrs client domain (assoc event ::sdb/id event-id))))
