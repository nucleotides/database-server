(ns event-api.core-test
  (:require [clojure.test       :refer :all]
            [compojure.handler  :refer [site]]
            [clojure.data.json  :as json]
            [ring.mock.request  :as mock]
            [cemerick.rummage   :as sdb]
            [taoensso.timbre    :as log]
            [event-api.database :as db]
            [event-api.core     :as app]))

; Silence logging to STDOUT during testing
(log/set-config! [:appenders :standard-out :enabled? false])

(defn get-docker-host []
  (re-find #"\d+.\d+.\d+.\d+" (System/getenv "DOCKER_HOST")))

(def domain "dev")
(def host   (if (System/getenv "CI") "localhost" (get-docker-host)))
(def client (db/create-client "dummy" "dummy" (str "http://" host ":8081")))

(defn sdb-domain-fixture [f]
  (do
    (sdb/create-domain client domain)
    (f)
    (sdb/delete-domain client domain)))


(use-fixtures
  :once sdb-domain-fixture)

(defn request [method url params]
  (let [hnd (site (app/api client domain))]
    (hnd (mock/request method url params))))

(def valid-event-map
  {:benchmark_id        "abcd"
   :benchmark_type_code "0000"
   :status_code         "0000"
   :event_type_code     "0000"})

(deftest app

  (testing "POST /events"
    (let [f #(request :post "/events/update" %)]

      (testing "with invalid parameters"
        (is (= 422 (:status (f {}))))
        (is (= 422 (:status (f {:benchmark_id "abcd"})))))

      (testing "with valid paramters"
        (let [response (f valid-event-map)]
          (is (= 202 (:status response)))
          (is (re-matches #"^\d+$" (:body response)))
          (is (not (empty? (db/read-event client domain (:body response)))))))

      (testing "with log file parameters"
        (let [response (f (merge valid-event-map
                                 {:log_file_digest "ade5...", :log_file_s3_url "s3://url"}))]
          (is (= 202 (:status response)))
          (is (re-matches #"^\d+$" (:body response)))
          (let [db-entry (db/read-event client domain (:body response))]
            (is (not (empty? db-entry)))
            (is (contains? db-entry :log_file_digest))
            (is (contains? db-entry :log_file_s3_url)))))

      (testing "with event file parameters"
        (let [response (f (merge valid-event-map
                                 {:event_file_digest "ade5...", :event_file_s3_url "s3://url"}))]
          (is (= 202 (:status response)))
          (is (re-matches #"^\d+$" (:body response)))
          (let [db-entry (db/read-event client domain (:body response))]
            (is (not (empty? db-entry)))
            (is (contains? db-entry :event_file_digest))
            (is (contains? db-entry :event_file_s3_url)))))

      (testing "with cgroup file parameters"
        (let [response (f (merge valid-event-map
                                 {:cgroup_file_digest "ade5...", :cgroup_file_s3_url "s3://url"}))]
          (is (= 202 (:status response)))
          (is (re-matches #"^\d+$" (:body response)))
          (let [db-entry (db/read-event client domain (:body response))]
            (is (not (empty? db-entry)))
            (is (contains? db-entry :cgroup_file_digest))
            (is (contains? db-entry :cgroup_file_s3_url)))))))



  (testing "GET /events/show.json"
    (let [f #(request :get (str "/events/show.json?id=" %1) %2)]

      (testing "with a valid event ID"
        (let [eid (db/create-event client domain
                                   (db/create-event-map valid-event-map))]
          (is (= 200 (:status (f eid {}))))
          (is (contains? (json/read-str (:body (f eid {}))) "created_at"))
          (is (contains? (json/read-str (:body (f eid {}))) "benchmark_id"))))))



  (testing "GET /events/lookup.json"
    (let [f #(request :get (str "/events/lookup.json?" %) {})]

      (testing "with an benchmark_type_code matching one entry"
        (let [eid      (db/create-event client domain
                         (db/create-event-map valid-event-map))
              response (f "benchmark_type_code=0000")]

          (is (= 200 (:status response)))
          (is (contains? (->> (:body response) (json/read-str) (first)) "created_at"))
          (is (contains? (->> (:body response) (json/read-str) (first)) "benchmark_id"))))

      (testing "with two query parameters matching one entry"
        (let [eid      (db/create-event client domain
                         (db/create-event-map valid-event-map))
              response (f "benchmark_type_code=0000&status_code=0000")]

          (is (= 200 (:status response)))
          (is (contains? (->> (:body response) (json/read-str) (first)) "created_at"))
          (is (contains? (->> (:body response) (json/read-str) (first)) "benchmark_id")))))))
