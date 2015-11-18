(ns nucleotides.api.benchmarks-test
  (:require [clojure.test       :refer :all]
            [clojure.data.json  :as json]
            [clojure.walk       :as walk]

            [nucleotides.database.connection  :as con]
            [nucleotides.api.benchmarks       :as bench]
            [helper                           :as help]))

(defn show
  ([params] (bench/show (con/create-connection) {:params params
                                                 :query-params params}))
  ([]       (show {})))

(deftest nucleotides.api.benchmarks

  (testing "#show"

    (testing "with a single benchmark entry"
      (let [_ (help/load-fixture "a_single_benchmark")]

        (testing "with no request parameter"
          (let [{:keys [status body]} (show)]
            (is (= 200 status))
            (is (not (empty? body)))
            (dorun
              (for [k [:id :image_task :image_name :image_sha256
                       :input_url :input_md5 :product :evaluation]]
                (is (contains? (first body) k))))))

        (testing "with product=false request parameter"
          (let [{:keys [status body]} (show {:product "false"})]
            (is (= 200 status))
            (is (not (empty? body)))
            (dorun
              (for [k [:id :image_task :image_name :image_sha256
                       :input_url :input_md5 :product :evaluation]]
                (is (contains? (first body) k))))))

        (testing "with product=true request parameter"
          (let [{:keys [status body]} (show {:product "true"})]
            (is (= 200   status))
            (is (empty?  body))))))))
