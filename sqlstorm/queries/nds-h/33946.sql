WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE sh.level < 3
),
TotalOrderValues AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
    GROUP BY o.o_orderkey
),
HighValueOrders AS (
    SELECT tov.o_orderkey, tov.total_value
    FROM TotalOrderValues tov
    WHERE tov.total_value > (SELECT AVG(total_value) FROM TotalOrderValues)
),
SupplierOrderInfo AS (
    SELECT s.s_name, COUNT(DISTINCT lo.o_orderkey) AS order_count,
           SUM(lo.total_value) AS total_order_value
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN HighValueOrders lo ON l.l_orderkey = lo.o_orderkey
    GROUP BY s.s_name
)
SELECT 
    s.s_name,
    CASE 
        WHEN so.total_order_value IS NULL THEN 'No Orders'
        ELSE CAST(so.total_order_value AS STRING) 
    END AS order_value_status,
    COALESCE(so.order_count, 0) AS total_orders,
    RANK() OVER (ORDER BY COALESCE(so.total_order_value, 0) DESC) AS rank
FROM SupplierOrderInfo so
JOIN supplier s ON so.s_name = s.s_name
WHERE s.s_acctbal > 1000
  AND (s.s_comment NOT LIKE '%regular%' OR s.s_comment IS NULL)
ORDER BY rank;