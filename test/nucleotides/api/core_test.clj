(ns nucleotides.api.core-test
  (:require [clojure.test       :refer :all]
            [ring.mock.request  :as mock]
            [clojure.data.json  :as json]

            [helper.event          :refer :all]
            [helper.fixture        :as fix]
            [helper.http-response  :as resp]
            [helper.database       :as db]
            [helper.image          :as image]

            [nucleotides.api.benchmarks-test :as bench-test]

            [nucleotides.database.connection  :as con]
            [nucleotides.api.middleware       :as md]
            [nucleotides.api.core             :as app]))


(defn http-request
  "Create a mock request to the API"
  [{:keys [method url params body content] :or {params {}}}]
  (-> (mock/request method url params)
      (mock/body body)
      (mock/content-type content)
      ((md/middleware (app/api {:connection (con/create-connection)})))))

(defn test-app-response [{:keys [db-tests response-tests fixtures] :as m}]
  (db/empty-database)
  (apply fix/load-fixture (concat fix/base-fixtures fixtures))
  (let [response (http-request m)]
    (dorun
      (for [t response-tests]
        (t response)))
    (dorun
      (for [[table length] db-tests]
        (is (= length (db/table-length table)))))))

(deftest app

  (testing "GET /tasks/:id"
    (test-app-response
      {:method          :get
       :url             "/tasks/1"
       :response-tests  [resp/is-ok-response
                         resp/is-not-empty-body
                         (resp/does-http-body-contain
                                  [:id :benchmark :type :complete :image :inputs])]}))

  (testing "GET /tasks/show.json"
    (test-app-response
      {:method          :get
       :url             "/tasks/show.json"
       :response-tests  [resp/is-ok-response
                         resp/is-not-empty-body
                         #(is (= (set (json/read-str (:body %))) #{1 3 5 7 9 11}))]}))

  (testing "GET /events/:id"
    (test-app-response
      {:method          :get
       :url             "/events/1"
       :fixtures        ["unsuccessful_product_event"]
       :response-tests  [resp/is-ok-response
                         resp/is-not-empty-body
                         (resp/does-http-body-contain [:id])]}))

  (testing "POST /events"
    (test-app-response
      {:method          :post
       :url             "/events"
       :body            (mock-json-event :produce :failure)
       :content         "application/json"
       :response-tests  [resp/is-ok-response
                         #(resp/has-header % "Location")]
       :db-tests       {"event" 1
                        "event_file_instance" 1}}))

  (comment (testing "GET /benchmarks/:id"
    (test-app-response
      {:method          :get
       :url             "/benchmarks/2f221a18eb86380369570b2ed147d8b4"
       :response-tests  [resp/is-ok-response
                         resp/is-not-empty-body
                         bench-test/has-benchmark-fields
                         bench-test/has-task-fields]}))))
