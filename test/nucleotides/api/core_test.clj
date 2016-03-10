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


(defn test-get-event [{:keys [event-id fixtures files]}]
  (test-app-response
    {:method          :get
     :url             (str "/events/" event-id)
     :fixtures        fixtures
     :response-tests  [resp/is-ok-response
                       resp/is-not-empty-body
                       (resp/does-http-body-contain [:task :success :created_at :metrics :id :files])
                       #(apply resp/contains-file-entries % [:body] (map resp/file-entry files))]}))


(defn test-show-tasks [{:keys [fixtures expected]}]
  (test-app-response
    {:method          :get
     :url             "/tasks/show.json"
     :fixtures        fixtures
     :response-tests  [resp/is-ok-response
                       #(is (= (sort (json/read-str (:body %))) (sort expected)))]}))


(deftest app

  (testing "GET /tasks/show.json"

    (testing "getting all incomplete tasks"
      (test-show-tasks {:expected [1 3 5 7 9 11]}))

    (testing "getting incomplete tasks with an unsuccessful produce task"
      (test-show-tasks
        {:fixtures  [:unsuccessful-product-event]
         :expected  [1 3 5 7 9 11]}))

    (testing "getting incomplete tasks with successful produce task"
      (test-show-tasks
        {:fixtures  [:successful-product-event]
         :expected  [2 3 5 7 9 11]}))

    (testing "getting incomplete tasks with successful produce task"
      (test-show-tasks
        {:fixtures  [:successful-product-event :successful-evaluate-event]
         :expected  [3 5 7 9 11]})))

  (testing "GET /events/:id"

    (testing "for an unsuccessful product event"
      (test-get-event
        {:event-id 1
         :fixtures [:unsuccessful-product-event]}))

    (testing "for a successful evaluate event"
      (test-get-event
        {:event-id 1
         :fixtures [:successful-evaluate-event]})))



  (testing "POST /events"

    (testing "with a failed produce event"
      (test-app-response
        {:method          :post
         :url             "/events"
         :body            (mock-json-event :produce :failure)
         :content         "application/json"
         :response-tests  [resp/is-ok-response
                           #(resp/has-header % "Location")]
         :db-tests       {"event" 1
                          "event_file_instance" 1}}))

    (testing "with a successful evaluate event"
      (test-app-response
        {:method          :post
         :url             "/events"
         :body            (mock-json-event :evaluate :success)
         :content         "application/json"
         :response-tests  [resp/is-ok-response
                           #(resp/has-header % "Location")]
         :db-tests       {"event" 1
                          "event_file_instance" 1}}))

    (testing "with an unknown metric type"
      (test-app-response
        {:method          :post
         :url             "/events"
         :body            (-> (mock-event :evaluate :success)
                              (assoc-in [:metrics :unknown] 0)
                              (json/write-str))
         :content         "application/json"
         :response-tests  [resp/is-client-error-response]
         :db-tests       {"event" 0
                          "event_file_instance" 0}})))


  (testing "GET /benchmarks/:id"

    (testing "a benchmark with no events"
      (test-app-response
        {:method          :get
         :url             "/benchmarks/453e406dcee4d18174d4ff623f52dcd8"
         :response-tests  [resp/is-ok-response
                           resp/is-not-complete
                           resp/is-not-empty-body
                           bench-test/has-benchmark-fields
                           bench-test/has-task-fields]}))

    (testing "a completed benchmark"
      (test-app-response
        {:method          :get
         :url             "/benchmarks/453e406dcee4d18174d4ff623f52dcd8"
         :fixtures        [:successful_product_event :successful_evaluate_event]
         :response-tests  [resp/is-ok-response
                           resp/is-not-empty-body
                           resp/is-complete
                           bench-test/has-benchmark-fields
                           bench-test/has-task-fields]}))))
