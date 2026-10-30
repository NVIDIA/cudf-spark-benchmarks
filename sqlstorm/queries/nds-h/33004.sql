WITH  TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS recent_rank
    FROM orders o
    WHERE o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
),
DetailedLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, l.l_quantity, l.l_discount, l.l_extendedprice,
           (l.l_extendedprice * (1 - l.l_discount)) AS discounted_price,
           CASE 
               WHEN l.l_returnflag = 'Y' THEN 'Returned'
               ELSE 'Not Returned'
           END AS return_status,
           RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS price_rank
    FROM lineitem l
    WHERE l.l_shipdate > '1997-01-01'
)
SELECT p.p_name, SUM(d.discounted_price) AS total_revenue, 
       COUNT(DISTINCT o.o_orderkey) AS order_count, 
       COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
       CASE 
           WHEN r.r_name IS NULL THEN 'Unknown Region'
           ELSE r.r_name
       END AS region_name
FROM part p
LEFT JOIN DetailedLineItems d ON p.p_partkey = d.l_partkey
LEFT JOIN RecentOrders o ON d.l_orderkey = o.o_orderkey
LEFT JOIN supplier s ON d.l_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_retailprice > 50.00
  AND d.price_rank <= 3
  AND o.recent_rank <= 5
GROUP BY p.p_name, r.r_name
HAVING SUM(d.discounted_price) > 1000
ORDER BY total_revenue DESC;