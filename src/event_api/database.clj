(ns event-api.database
  (:require [cemerick.rummage :as sdb])
  (:import  [com.amazonaws.services.simpledb AmazonSimpleDBClient]
            [com.amazonaws.auth              BasicAWSCredentials]))

(defn create-client [access-key secret-key endpoint]
  (let [client (new AmazonSimpleDBClient
                    (new BasicAWSCredentials access-key secret-key))]
    (.setEndpoint client endpoint)
    {:client client}))
