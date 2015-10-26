(ns nucleotides.database.load-test
  (:require [clojure.test                    :refer :all]
            [clojure.java.jdbc               :as db]
            [helper                          :as help]
            [nucleotides.database.load       :as loader]
            [nucleotides.database.connection :as con]
            [nucleotides.util                :as util]))

(help/silence-logging!)

(def initial-test-data
  {:images
   [{"image_type"      "type",
     "description"     "description"
     "image_instances" {"image" "image/name"
                        "tasks" ["default" "careful"]}}]})

(use-fixtures :each (fn [f] (help/empty-database) (f)))

(deftest load-image-types

  (testing "with a single image type entry"
    (let [entries (loader/load-image-types
                (con/create-connection)
                (:images initial-test-data))]

    (is (not (empty? entries)))
    (is (= 1 (count entries))))))
