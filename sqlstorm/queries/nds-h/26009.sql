
WITH  OrderHierarchy AS (
    SELECT o_orderkey, o_orderdate, c_name, s_name, 
           ROW_NUMBER() OVER (PARTITION BY o_orderkey ORDER BY o_orderdate DESC) AS order_rank
    FROM orders
    JOIN customer ON o_custkey = c_custkey
    JOIN lineitem ON o_orderkey = l_orderkey
    JOIN partsupp ON l_partkey = ps_partkey
    JOIN supplier ON ps_suppkey = s_suppkey
), ProcessedOrders AS (
    SELECT o_orderkey AS orderkey, 
           MIN(o_orderdate) AS earliest_order, 
           COUNT(DISTINCT c_name) AS unique_customers,
           STRING_AGG(DISTINCT s_name, '; ') AS suppliers_list
    FROM OrderHierarchy 
    WHERE order_rank <= 5
    GROUP BY o_orderkey
)
SELECT oh.orderkey, 
       oh.earliest_order, 
       oh.unique_customers, 
       CHAR_LENGTH(oh.suppliers_list) AS suppliers_length,
       REGEXP_REPLACE(oh.suppliers_list, '[^a-zA-Z0-9; ]', '') AS cleaned_suppliers_list
FROM ProcessedOrders oh
WHERE oh.unique_customers > 1
ORDER BY oh.earliest_order DESC;
