(ns event-api.core-test
  (:require [clojure.test       :refer :all]
            [compojure.handler  :refer [site]]
            [ring.mock.request  :as mock]
            [cemerick.rummage   :as sdb]
            [event-api.database :as db]
            [event-api.core     :as app]))

(def domain "dev")
(def client (db/create-client "dummy" "dummy" "http://192.168.59.103:8081"))

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
    (let [f #(request :post "/events" %)]

      (testing "with invalid parameters"
        (is (= 422 (:status (f {}))))
        (is (= 422 (:status (f {:benchmark_id "abcd"})))))

      (testing "with valid paramters"
        (is (= 202 (:status (f valid-event-map))))))))
