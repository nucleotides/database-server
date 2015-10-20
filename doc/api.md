## /events/

### POST /events/update

Add a new event to the database.

#### Resource URL

http://api.nucleotides/0.2/events/update

#### Parameters

  * **benchmark_id**

    **Required**: The benchmark's alphanumeric identifier. Each benchmark has a
    unique identifier created from a digest of its fields.

  * **benchmark_type_code**

    **Required**: The code identifying the type of benchmark. The list of
    possible benchmarks are defined in the [nucleotides benchmark list][bench].

  * **status_code**

    **Required**: The outcome code of the event. This may have one of the
    following values:

      * **0000**: This event completed successfully.

      * **0001**: This event failed to complete due to the container failing
        with an error.

      * **0002**: This event failed to complete due to the container finishing
        without error but not producing any data.

  * **event_type_code**

    **Required**: The code for the type of event. This can have the following
    values:

      * **0000**: Started testing container reference data set.

      * **0001**: Testing container has finished.

      * **0002**: Started evaluation container with testing container generated
        data.

      * **0003**: Evaluation container has finished.

  * **log_file_s3_url**

    **Optional**: The S3 url for a file containing a log of the event.

  * **log_file_digest**

    **Optional**: The SHA256 digest of the log file.

  * **event_file_s3_url**

    **Optional**: The S3 url for a file containing data specific to this event.

  * **event_file_digest**

    **Optional**: The SHA256 digest of the event file.

  * **cgroup_file_s3_url**

    **Optional**: The S3 url for a file containing cgroup metrics for this
    event.

  * **cgroup_file_digest**

    **Optional**: The SHA256 digest of the cgroup file.

#### Example request

POST http://api.nucleotides/0.2/events/update?benchmark_id=afd0&benchmark_type_code=0000&state_code=0000&event_type_code=0000

#### Example response

HTTP/1.1 201 Created
Date: Fri, 7 Oct 2005 17:17:11 GMT
Content-Length: nnn
Content-Type: text/plain;charset="utf-8"
Location: http://api.nucleotides/0.2/events/show.json?id=243145735212777472

243145735212777472



### GET /events/show/:id

2eturns a single event as JSON document.

#### Resource URL

http://api.nucleotides/0.2/events/show.json

#### Parameters

  * **id**

    **Required**: The unique ID of this event. This is the time stamp of this
    event in milliseconds since 00:00:00 Coordinated Universal Time (UTC). This
    is unique for this event. (Assuming no two events are created at exactly
    the same millisecond.)

#### Example request

GET http://api.nucleotides/0.2/events/show.json?id=1234

#### Example response

    {"id"                  : "243145735212777472",
     "created_at"          : "20150113T162702.420Z",
     "benchmark_id"        : "afd0...",
     "benchmark_type_code" : "0000",
     "state_code"          : "0000",
     "event_type_code"     : "0000"}



### GET /events/lookup

Returns a list of up to 100 events as a JSON document.

#### Resource URL

http://api.nucleotides/0.2/events/show.json

#### Parameters

  * **benchmark_id**

    **Optional**: A comma separated list of benchmark IDs. Returns a list of
    all the events related to these benchmarks.

  * **max_id**:

    **Optional**: The event ID, inclusive, to end pagination of the events
    list. Used to fetch multiple pages of events in separate requests.

  * **benchmark_type_id**:

    **Optional**: The code identifying the type of benchmark. Selects for only
    the events for this kind of benchmark.

  * **state_code**:

    **Optional**: A comma separated list of state_codes. Limit the returned
    events to this code.

  * **event_type_code**:

    **Optional**: Limit the returned events to this type.

#### Example request

GET http://api.nucleotides/0.2/events/lookup.json?benchmark_id=a8f3&max_id=1234

[bench]: https://github.com/nucleotides/nucleotides-data/blob/master/data/benchmark_type.yml
