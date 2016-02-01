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
            [nucleotides.api.core             :as app]))


(use-fixtures :once (fn [f]
                      (empty-database)
                      (load-fixture :metadata :input-data-source :input-data-file-set
                                    :input-data-file :image-instance :benchmarks :tasks)
                      (f)))

(defn request
  "Create a mock request to the API"
  ([method url params]
   (let [hnd (md/middleware (app/api {:connection (con/create-connection)}))]
     (hnd (mock/request method url params))))
  ([method url]
   (request method url {})))

(deftest app

  (testing "GET /tasks/:id"
    (let [f #(request :get (str "/tasks/" %))]

      (let [res (f 1)]
        (is-ok-response res)
        (is-not-empty-body res)
        (has-body-entry res "id"))))

  (comment (testing "GET /tasks/show.json"
    (let [f (comp (partial request :get) (partial str "/tasks/show.json"))]

      (let [_   (load-fixture "a_single_incomplete_task")
            res (f)]
        (is-ok-response res)
        (is-not-empty-body res)))))


  (comment (testing "POST /events"
    (let [f (partial request :post "/events")]

      (testing "with a successful produce event"
        (let [_   (load-fixture "a_single_incomplete_task")
              res (f (event-as-http-params (mock-event :produce :success)))]
          (is-ok-response res)
          (has-header res "Location")
          (is (= 1 (table-length "event")))))

      (testing "with a successful evaluate event"
        (let [_   (load-fixture "a_single_incomplete_task")
              res (f (event-as-http-params (mock-event :evaluate :success)))]
          (is-ok-response res)
          (has-header res "Location")
          (is (= 1 (table-length "event")))
          (is (= 2 (table-length "metric_instance"))))))))

  (comment (testing "GET /events/:id"
    (let [f #(request :get (str "/events/" %))]

      (let [_   (load-fixture "a_single_incomplete_task" "a_successful_product_event")
            res (f 1)]
        (is-ok-response res)
        (is-not-empty-body res)
        (has-body-entry res "id"))))))
