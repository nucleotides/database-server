(ns nucleotides.api.core-test
  (:require [clojure.test       :refer :all]
            [ring.mock.request  :as mock]

            [helper.event          :refer :all]
            [helper.http-response  :refer :all]
            [helper.fixture        :refer :all]
            [helper.database       :refer :all]

            [nucleotides.database.connection  :as con]
            [nucleotides.database.load        :as db]
            [nucleotides.api.middleware       :as md]
            [nucleotides.api.core             :as app]
            ))


(defn request
  "Create a mock request to the API"
  ([method url params]
   (let [hnd (md/middleware (app/api {:connection (con/create-connection)}))]
     (hnd (mock/request method url params))))
  ([method url]
   (request method url {})))

(deftest app

  (testing "GET /tasks/show.json"
    (let [f (comp (partial request :get) (partial str "/tasks/show.json"))]

      (let [_   (load-fixture "a_single_incomplete_task")
            res (f)]
        (is-ok-response res)
        (is-not-empty-body res))))

  (testing "POST /events"
    (let [f (partial request :post "/events")]

      (let [_   (load-fixture "a_single_incomplete_task")
            res (f (mock-event :success))]
        (is-ok-response res)
        (has-header res "Location")
        (is (= 1 (table-length "event")))))))
