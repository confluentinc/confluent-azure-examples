# Microsoft Build 2024 Confluent Cloud for Apache Flink Demo

This repository contains Flink SQL demo queries that can be used on Confluent Cloud for Apache Flink®.

This repo was borrowed from MartijnVisser/cc-for-apache-flink-demos:main

## Requirements

- An open mind and willingness to [read the docs](https://docs.confluent.io/cloud/current/overview.html)

## Create your environment and cluster

Create an environment named `microsoft-build-2024` and a cluster named `webshop-ops`

## Create your Flink compute pool

From the Environments page click into the `webshop-ops` cluster and then select the Flink tab. Once in the Flink tab select `Create compute pool` and select the same region your cluster is running in or one close to it.

## Create your topics and Datagen connectors

Running these queries requires 4 topics to be set up using the [Datagen connector](https://docs.confluent.io/cloud/current/connectors/cc-datagen-source.html), using AVRO and Schema Registry.

**_NOTE:_** These require your Datagen connectors to have been running for over an hour. Setup the Datagen connectors then come back after some time to start the demo

* Topic `clickstream` -> Datagen template `SHOE_CLICKSTREAM`
* Topic `customers` -> Datagen template `SHOE_CUSTOMERS`
* Topic `orders` -> Datagen template `SHOE_ORDERS`
* Topic `shoes` -> Datagen template `SHOES`

## Explore your data in the Flink workspace

```sql
SELECT * FROM orders;
```

## Count number of unique orders per hour

```sql
SELECT window_start, window_end, COUNT(DISTINCT order_id) as nr_of_orders
  FROM TABLE(
    TUMBLE(TABLE orders, DESCRIPTOR($rowtime), INTERVAL '1' HOUR))
  GROUP BY window_start, window_end;
```

## Create table including underlying Kafka topic

```sql
CREATE TABLE sales_per_hour (
 window_start TIMESTAMP(3),
 window_end   TIMESTAMP(3),
 nr_of_orders BIGINT
);
```

## Materialize number of unique orders per hour in newly created topic

```sql
INSERT INTO sales_per_hour
 SELECT window_start, window_end, COUNT(DISTINCT order_id) as nr_of_orders
    FROM TABLE(
      TUMBLE(TABLE `microsoft-build-2024`.`webshop-ops`.`orders`, DESCRIPTOR($rowtime), INTERVAL '1' HOUR))
    GROUP BY window_start, window_end;
```

**_NOTE:_**  Make sure that you select the correct full qualified names, because they are specific for your setup

## Deduplicate table

```sql
SELECT id, name, brand
FROM (
  SELECT *,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY $rowtime DESC) AS row_num
  FROM `shoes`)
WHERE row_num = 1
```

## Enrich clickstream data by joining with deduplicated table

```sql
WITH uniqueShoes AS (
SELECT id, name, brand
FROM (
  SELECT *,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY $rowtime DESC) AS row_num
  FROM `microsoft-build-2024`.`webshop-ops`.`shoes`)
WHERE row_num = 1
)
SELECT 
  c.`$rowtime`,
  c.product_id,
  s.name, 
  s.brand
FROM 
  clickstream c
  INNER JOIN uniqueShoes s ON c.product_id = s.id;
```

**_NOTE:_**  Make sure that you select the correct full qualified names, because they are specific for your setup

## Measure average view time of less then 30

```sql
SELECT *
FROM clickstream
    MATCH_RECOGNIZE (
        PARTITION BY user_id
        ORDER BY `$rowtime`
        MEASURES
            FIRST(A.`$rowtime`) AS start_tstamp,
            LAST(A.`$rowtime`) AS end_tstamp,
            AVG(A.view_time) AS avgViewTime
        ONE ROW PER MATCH
        AFTER MATCH SKIP PAST LAST ROW
        PATTERN (A+ B)
        DEFINE
            A AS AVG(A.view_time) < 30
    ) MR;
```
