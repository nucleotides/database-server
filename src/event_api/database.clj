(ns event-api.database
  (:require [cemerick.rummage          :as sdb]
            [cemerick.rummage.encoding :as enc]
            [clj-time.core             :as ctime]
            [clj-time.coerce           :as coerce]
            [clj-time.format           :as fmt]
            [clojure.set               :refer [superset? union]]
            [clojure.walk              :refer [keywordize-keys]])
  (:import  [com.amazonaws.services.simpledb AmazonSimpleDBClient]
            [com.amazonaws.auth              BasicAWSCredentials]))

(def required-event-keys
  #{:benchmark_id
    :benchmark_type_code
    :status_code
    :event_type_code})

(def optional-event-keys
  #{:log_file_s3_url
    :log_file_digest
    :event_file_s3_url
    :event_file_digest
    :cgroup_file_s3_url
    :cgroup_file_digest})


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
  (let [event-time (ctime/now)]
    (-> (select-keys request-params (union required-event-keys optional-event-keys))
        (keywordize-keys)
        (assoc ::sdb/id    (str (coerce/to-long event-time)))
        (assoc :created_at (fmt/unparse (fmt/formatters :basic-date-time) event-time)))))

(defn normalise-query-params [params]
  (let [transform (fn [[k v]] (if (= :max_id k) (list '<= ::sdb/id v) (list '= k v)))]
  (->> (keywordize-keys params)
       (map transform))))

(defn build-query [domain params]
  (let [select-statment (merge {'select '* 'from (symbol domain)})]
    (if (not (empty? params))
      (merge select-statment {'where (cons 'and (normalise-query-params params))})
      select-statment)))

(defn create-event [client domain event]
  (do
    (sdb/put-attrs client domain event)
    (::sdb/id event)))

(defn read-event [client domain event-id]
  (sdb/get-attrs client domain event-id))

(defn query-event [client query]
  (sdb/query client query))


