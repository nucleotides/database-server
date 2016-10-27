(ns helper.validation
  (:require [clojure.test :refer :all]))

(defn validate-fields [fields coll]
  (dorun
    (for [field fields]
      (do (is (contains? coll field))
          (is (not (nil? (field coll))) (str field " is nil in " coll))))))

(def is-valid-image?
  (partial validate-fields [:name :sha256 :task :type :version]))

(def is-valid-file?
  (partial validate-fields [:url :type :sha256]))

(defn is-valid-event? [event]
  (validate-fields [:id :created_at :task :success :files :metrics] event)
  (dorun (map is-valid-file? (:files event))))

(defn is-valid-task? [task]
  (validate-fields [:id :benchmark :type :complete :success :image :inputs :events] task)
  (is-valid-image? (:image task))
  (dorun (map is-valid-file? (:inputs task)))
  (dorun (map is-valid-event? (:events task))))

(defn is-valid-benchmark? [bench]
  (validate-fields [:id :complete :success :type :tasks] bench)
  (is (not (contains? bench :task_id)))
  (is (not (empty? (:tasks bench))))
  (dorun (map is-valid-task? (:tasks bench))))

(defn is-valid-status? [status]
  (validate-fields [:tasks :benchmarks] status)
  (validate-fields [:all :produce :evaluate] (:tasks status))
  (validate-fields [:all] (:benchmarks status))
  (let [summary-keys [:n :n_successful :n_errorful :n_outstanding :n_executed
                      :percent_successful :percent_errorful :percent_outstanding :percent_executed]]
    (doall
      (for [x (map last (concat (:tasks status) (:benchmarks status)))]
        (validate-fields summary-keys x)))))


