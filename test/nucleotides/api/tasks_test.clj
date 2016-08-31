(ns nucleotides.api.tasks-test
  (:require [clojure.test                     :refer :all]
            [helper.http-response             :as resp]
            [helper.fixture                   :as fix]
            [helper.database                  :as db]
            [nucleotides.api.tasks            :as task]))


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
