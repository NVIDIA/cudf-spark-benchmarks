
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_mktsegment
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '1998-10-01' - INTERVAL '6 months'
),
AggregateLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    GROUP BY l.l_orderkey
),
CustomerPurchase AS (
    SELECT c.c_custkey, c.c_name, SUM(ali.total_sales) AS total_spent
    FROM customer c
    LEFT JOIN AggregateLineItems ali ON c.c_custkey = ali.l_orderkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT s.s_name, 
       s.s_nationkey, 
       SUM(CASE WHEN r.o_orderkey IS NOT NULL THEN r.o_totalprice ELSE 0 END) AS total_order_value,
       COUNT(r.o_orderkey) AS order_count,
       STRING_AGG(DISTINCT c.c_name) AS customers,
       ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(CASE WHEN r.o_orderkey IS NOT NULL THEN r.o_totalprice ELSE 0 END) DESC) AS rank
FROM supplier s
LEFT JOIN RecentOrders r ON s.s_suppkey = r.o_orderkey
LEFT JOIN CustomerPurchase c ON r.o_orderkey = c.c_custkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_comment LIKE '%supply%')
GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
ORDER BY total_order_value DESC
LIMIT 10;
