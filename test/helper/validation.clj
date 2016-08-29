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
  (validate-fields [:id :benchmark :type :complete :image :inputs :events] task)
  (is-valid-image? (:image task))
  (dorun (map is-valid-file? (:inputs task)))
  (dorun (map is-valid-event? (:events task))))

(defn is-valid-benchmark? [bench]
  (validate-fields [:id :complete :type :tasks] bench)
  (is (not (contains? bench :task_id)))
  (is (not (empty? (:tasks bench))))
  (dorun (map is-valid-task? (:tasks bench))))
