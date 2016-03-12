(ns nucleotides.api.tasks-test
  (:require [clojure.test                     :refer :all]
            [clojure.data.json                :as json]
            [helper.http-response             :as resp]
            [helper.fixture                   :as fix]
            [helper.event                     :as ev]
            [helper.image                     :as image]
            [helper.database                  :as db]
            [nucleotides.api.tasks            :as task]))


(def contains-task-entries
  (resp/does-http-body-contain [:id :benchmark :type :complete :image :inputs]))

(defn contains-task-files [file-list]
  (let [path  [:body :inputs]
        files (map resp/file-entry file-list)]
    (fn [response]
      (apply resp/contains-file-entries response path files))))

(defn contains-events [events]
  (let [path [:body :events]]
    (fn [response]
      (apply resp/contains-event-entries response path events))))


(use-fixtures :each (fn [f]
                      (do
                        (db/empty-database)
                        (apply fix/load-fixture fix/base-fixtures)
                        (f))))

(deftest nucleotides.api.tasks

  (testing "#exists?"
    (is (true?  (task/exists? 1)))
    (is (true?  (task/exists? "1")))
    (is (false? (task/exists? 1000)))
    (is (false? (task/exists? "1000")))
    (is (false? (task/exists? "unknown")))))
