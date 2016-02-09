(ns nucleotides.api.core-test
  (:require [clojure.test       :refer :all]
            [ring.mock.request  :as mock]
            [clojure.data.json  :as json]

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
                      (apply load-fixture base-fixtures)
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
        (does-http-body-contain
          ["id" "benchmark" "task_type" "image_name" "image_sha256" "image_task" "image_type"] res))))

  (testing "GET /tasks/show.json"
    (let [f (partial request :get "/tasks/show.json")]

      (let [res (f)]
        (is-ok-response res)
        (is-not-empty-body res)
        (is (= (set (json/read-str (:body res))) #{1 3 5 7 9 11})))))

  (testing "GET /events/:id"
    (let [f #(request :get (str "/events/" %))]

      (let [_   (load-fixture "unsuccessful_product_event")
            res (f 1)]
        (is-ok-response res)
        (is-not-empty-body res)
        (does-http-body-contain ["id"] res))))


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

  )
