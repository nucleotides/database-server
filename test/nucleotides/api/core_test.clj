(ns nucleotides.api.core-test
  (:require [clojure.test       :refer :all]
            [helper.validation  :refer :all]
            [clojure.core.match :refer [match]]

            [ring.mock.request  :as mock]

            [helper.event          :refer :all]
            [helper.fixture        :as fix]
            [helper.http-response  :as resp]
            [helper.database       :as db]

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


(defn test-app-response [{:keys [db-tests response-tests fixtures keep-db? testing-data]
                          :or {keep-db? false, testing-data false}
                          :as m}]
  (match [keep-db? testing-data]
         [true   true] (throw (IllegalArgumentException.
                              "Testing error - database cannot be both kept and peudo data loaded"))
         [false false] (do
                         (db/empty-database)
                         (apply fix/load-fixture (concat fix/base-fixtures fixtures)))
         [false  true] (do
                         (db/drop-tables)
                         (apply fix/load-fixture (cons "initial_state" fixtures)))
         [true  false] (do)) ;; do nothing to database when `:keep-db?` given
  (let [response (http-request m)]
    (dorun
      (for [t response-tests]
        (t response)))
    (dorun
      (for [[table length] db-tests]
        (is (= length (db/table-length table)))))))



(deftest app

  (testing "GET /tasks/show.json"

    (defn test-show-tasks [{:keys [fixtures expected]}]
      (test-app-response
        {:method          :get
         :url             "/tasks/show.json"
         :fixtures        fixtures
         :response-tests  [resp/is-ok-response
                           (resp/has-header "Content-Type" "application/json;charset=UTF-8")
                           (partial resp/dispatch-response-body-test #(is (= (sort %) (sort expected))))]}))



    (testing "getting all incomplete tasks"
      (test-show-tasks {:expected [1 3 5 7 9 11]}))

    (testing "getting incomplete tasks with an unsuccessful produce task"
      (test-show-tasks
        {:fixtures  [:unsuccessful-product-event]
         :expected  [3 5 7 9 11]}))

    (testing "getting incomplete tasks with successful produce task"
      (test-show-tasks
        {:fixtures  [:successful-product-event]
         :expected  [2 3 5 7 9 11]}))

    (testing "getting incomplete tasks with an unsuccessful evaluate task"
      (test-show-tasks
        {:fixtures  [:successful-product-event :unsuccessful-evaluate-event]
         :expected  [3 5 7 9 11]}))

    (testing "getting incomplete tasks with successful produce and evaluate task"
      (test-show-tasks
        {:fixtures  [:successful-product-event :successful-evaluate-event]
         :expected  [3 5 7 9 11]})))



  (testing "GET /tasks/:id"

    (defn test-get-task [{:keys [task-id fixtures files events completed successful]}]
      (test-app-response
        {:method          :get
         :url             (str "/tasks/" task-id)
         :fixtures        fixtures
         :response-tests  [resp/is-ok-response
                           (resp/has-header "Content-Type" "application/json;charset=UTF-8")
                           (partial resp/dispatch-response-body-test is-valid-task?)
                           (resp/contains-entries-at? [:inputs] (map resp/file-entry files))
                           (resp/contains-event-entries [:events] events)
                           (resp/is-complete? completed)
                           (resp/is-successful? successful)]}))



    (testing "Getting an unknown task ID"
      (test-app-response
        {:method          :get
         :url             "/tasks/1000"
         :response-tests  [resp/is-client-error-response
                           (resp/has-body "Task not found: 1000")]}))

    (testing "Getting an invalid task ID"
      (test-app-response
        {:method          :get
         :url             "/tasks/unknown"
         :response-tests  [resp/is-client-error-response
                           (resp/has-body "Task not found: unknown")]})))

    (testing "a produce task with no events"
      (test-get-task
        {:task-id 1
         :files [["short_read_fastq" "s3://reads" "7673a"]]
         :completed  false
         :successful false }))

    (testing "a produce task with a successful event"
      (test-get-task
        {:task-id 1
         :completed true
         :successful true
         :files [["short_read_fastq" "s3://reads" "7673a"]]
         :fixtures [:successful-product-event]
         :events [(mock-event :produce :success)]}))

    (testing "a produce task with a failed event"
      (test-get-task
        {:task-id 1
         :completed true
         :successful false
         :files [["short_read_fastq" "s3://reads" "7673a"]]
         :fixtures [:unsuccessful-product-event]
         :events [(mock-event :produce :failure)]}))

    (testing "an incomplete evaluate task with no produce files"
      (test-get-task
        {:task-id 2
         :completed false
         :successful false
         :files [["reference_fasta" "s3://ref" "d421a4"]]}))

    (testing "an incomplete evaluate task with a successful produce task"
      (test-get-task
        {:task-id 2
         :completed false
         :successful false
         :files [["reference_fasta" "s3://ref" "d421a4"]
                 ["contig_fasta"    "s3://contigs" "f7455"]]
         :fixtures [:successful-product-event]})

      (testing "a failed evaluate task with a successful produce task"
        (test-get-task
          {:task-id 2
           :completed true
           :successful false
           :fixtures [:successful-product-event :unsuccessful-evaluate-event]}))

      (testing "a successful evaluate task with a successful produce task"
        (test-get-task
          {:task-id 2
           :completed true
           :successful true
           :fixtures [:successful-product-event :successful-evaluate-event]}))

    (testing "an evaluate task where multiple produce events have been completed"
      (test-app-response
        {:method          :get
         :url             "/tasks/2"
         :fixtures        [:successful-product-event
                           :second-successful-product-event]
         :response-tests  [(partial resp/dispatch-response-body-test is-valid-task?)
                           (resp/is-length-at? [:inputs] 2)]})))



  (testing "GET /event/:id"

    (defn test-get-event [{:keys [event-id fixtures files]}]
      (test-app-response
        {:method          :get
         :url             (str "/events/" event-id)
         :fixtures        fixtures
         :response-tests  [resp/is-ok-response
                           resp/is-not-empty-body
                           (partial resp/dispatch-response-body-test is-valid-event?)
                           (resp/contains-entries-at? [:files] (map resp/file-entry files))]}))




    (testing "a valid unknown event id"
      (test-app-response
        {:method          :get
         :url             "/events/1000"
         :response-tests  [resp/is-client-error-response
                           (resp/has-body "Event not found: 1000")]}))

    (testing "an invalid unknown event id"
      (test-app-response
        {:method          :get
         :url             "/events/unknown"
         :response-tests  [resp/is-client-error-response
                           (resp/has-body "Event not found: unknown")]}))

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
                           (resp/has-header "Location" "/events/1")]
         :db-tests       {"event" 1
                          "event_file_instance" 1}}))

    (testing "with a successful evaluate event"
      (test-app-response
        {:method          :post
         :url             "/events"
         :body            (mock-json-event :evaluate :success)
         :content         "application/json"
         :response-tests  [resp/is-ok-response
                           (resp/has-header "Location" "/events/1")]
         :db-tests       {"event" 1
                          "event_file_instance" 1}}))

    (testing "with an unknown file type"
      (test-app-response
        {:method          :post
         :url             "/events"
         :body            (mock-json-event :evaluate :invalid-file)
         :content         "application/json"
         :response-tests  [resp/is-client-error-response
                           (resp/has-body "Unknown file types in request: unknown")]
         :db-tests        {"event" 0
                           "event_file_instance" 0}}))

    (testing "with an unknown metric type"
      (test-app-response
        {:method          :post
         :url             "/events"
         :body            (mock-json-event :evaluate :invalid-metric)
         :content         "application/json"
         :response-tests  [resp/is-client-error-response
                           (resp/has-body "Unknown metrics in request: unknown")]
         :db-tests        {"event" 0
                           "event_file_instance" 0}}))

    (testing "posting the same event twice"
      (let [params {:method   :post
                    :url      "/events"
                    :body     (mock-json-event :produce :failure)
                    :content  "application/json"}]
        (db/empty-database)
        (apply fix/load-fixture fix/base-fixtures)
        (http-request params)
        (test-app-response
          (merge params
                 {:keep-db?        true
                  :response-tests  [resp/is-ok-response
                                    (resp/has-header "Location" "/events/2")]
                  :db-tests       {"event" 2
                                   "event_file_instance" 2}})))))



  (testing "GET /benchmarks/:id"

    (defn test-get-benchmark [{:keys [benchmark-id fixtures complete successful]}]
      (test-app-response
        {:method          :get
         :url             (str "/benchmarks/" benchmark-id)
         :fixtures        fixtures
         :response-tests  [resp/is-ok-response
                           resp/is-not-empty-body
                           (partial resp/dispatch-response-body-test is-valid-benchmark?)
                           (resp/is-complete? complete)
                           (resp/is-successful? successful)]}))



    (testing "an unknown benchmark id"
      (test-app-response
        {:method          :get
         :url             "/benchmarks/unknown"
         :response-tests  [resp/is-client-error-response
                           (resp/has-body "Benchmark not found: unknown")]}))

    (testing "a benchmark with no events"
      (test-get-benchmark
        {:benchmark-id  "2f221a18eb86380369570b2ed147d8b4"
         :complete      false
         :successful    false}))

    (testing "a benchmark with a completed produce task"
      (test-get-benchmark
        {:benchmark-id  "2f221a18eb86380369570b2ed147d8b4"
         :fixtures      [:successful_product_event]
         :complete      false
         :successful    false}))

    (testing "a benchmark with a failed produce task"
      (test-get-benchmark
        {:benchmark-id  "2f221a18eb86380369570b2ed147d8b4"
         :fixtures      [:unsuccessful_product_event]
         :complete      true
         :successful    false}))

    (testing "a benchmark with a failed evaluate task"
      (test-get-benchmark
        {:benchmark-id  "2f221a18eb86380369570b2ed147d8b4"
         :fixtures      [:successful_product_event :unsuccessful_evaluate_event]
         :complete      true
         :successful    false}))

    (testing "a completed benchmark"
      (test-get-benchmark
        {:benchmark-id  "2f221a18eb86380369570b2ed147d8b4"
         :fixtures      [:successful_product_event :successful_evaluate_event]
         :complete      true
         :successful    true})))



  (testing "GET /results/complete"

    (defn test-get-results [{:keys [fixtures params entries]}]
      (test-app-response
        {:method          :get
         :url             (str "/results/complete?" (ring.util.codec/form-encode params))
         :testing-data    true
         :fixtures        fixtures
         :response-tests  [resp/is-ok-response
                           (resp/has-header "Content-Type" (app/content-types (keyword (:format params))))
                           (resp/has-header "Content-Disposition" (str "attachment; filename=\"nucleotides_benchmark_metrics." (:format params) "\""))
                           (resp/is-length-at? entries)]}))


    (testing "getting JSON results"

      (testing "when no benchmarks have been completed"
        (test-get-results
          {:params   {:format "json"}
           :entries  0}))

      (testing "using the benchmark URL parameter when no benchmarks have been completed"
        (test-get-results
          {:params   {:format "json" :benchmark_type ["benchmark_1"]}
           :entries  0}))

      (testing "using the variable URL parameter when no benchmarks have been completed"
        (test-get-results
          {:params   {:format "json" :variable ["produce_task_metric_1"]}
           :entries  0}))

      (testing "when a set of benchmarks for an image task have been completed"
        (test-get-results
          {:params    {:format "json"}
           :entries   2
           :fixtures  ["benchmark_instance/two_completed_from_two_different_benchmark_types"]}))

      (testing "using URL parameters to subset for one completed benchmark"
        (test-get-results
          {:params    {:format "json" :benchmark_type ["benchmark_1"]}
           :entries   1
           :fixtures  ["benchmark_instance/two_completed_from_two_different_benchmark_types"]})))


    (testing "getting CSV results"

      (testing "when no benchmarks have been completed"
        (test-get-results
          {:params   {:format "csv"}
           :entries  0}))

      (testing "when a set of benchmarks for an image task has been completed"
        (test-get-results
          {:params    {:format "csv"}
           :entries   6
           :fixtures  ["benchmark_instance/two_completed_from_two_different_benchmark_types"]}))

      (testing "using the URL variable parameter to subset for a single metric"
        (test-get-results
          {:params    {:format "csv" :variable "produce_task_metric_1"}
           :entries   2
           :fixtures  ["benchmark_instance/two_completed_from_two_different_benchmark_types"]}))

      (testing "using the URL variable parameter to subset for a multiple metrics"
        (test-get-results
          {:params    {:format "csv" :variable ["evaluate_task_metric_1" "evaluate_task_metric_2"] :benchmark_type "benchmark_1"}
           :entries   2
           :fixtures  ["benchmark_instance/two_completed_from_two_different_benchmark_types"]}))

      (testing "using the URL parameters to subset for a multiple metrics and benchmarks"
        (test-get-results
          {:params    {:format "csv" :variable ["evaluate_task_metric_1" "evaluate_task_metric_2"]}
           :entries   4
           :fixtures  ["benchmark_instance/two_completed_from_two_different_benchmark_types"]}))

      (testing "using the URL variable parameter to subset for a specific metric"
        (test-get-results
          {:params    {:format "csv" :benchmark_type "benchmark_1"}
           :entries   3
           :fixtures  ["benchmark_instance/two_completed_from_two_different_benchmark_types"]}))

      (testing "when a set of benchmarks for an image task has been partially completed"
        (test-get-results
          {:params    {:format "csv"}
           :entries   0
           :fixtures  ["benchmark_instance/one_partially_completed"]}))

      (testing "for an image task when one set has failed and another is successful"
        (test-get-results
          {:params    {:format "csv"}
           :entries   3
           :fixtures  ["benchmark_instance/one_completed_and_one_failed"]}))))



  (testing "GET /status.json"

    (defn test-get-status [{:keys [fixtures]}]
      (test-app-response
        {:method          :get
         :url             "/status.json"
         :testing-data    true
         :fixtures        fixtures
         :response-tests  [resp/is-ok-response
                           (resp/has-header "Content-Type" "application/json;charset=UTF-8")
                           (partial resp/dispatch-response-body-test is-valid-status?)]}))

    (testing "when no tasks have been completed"
      (test-get-status {}))))
