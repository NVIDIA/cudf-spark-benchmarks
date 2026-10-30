WITH SupplierOrderCounts AS (
    SELECT s.s_suppkey, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY s.s_suppkey
), CustomerSpend AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
), RegionSummary AS (
    SELECT r.r_regionkey, r.r_name, 
           SUM(CASE WHEN c.c_custkey IS NOT NULL THEN cs.total_spent ELSE 0 END) AS total_customer_spending,
           COUNT(DISTINCT ns.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation ns ON r.r_regionkey = ns.n_regionkey
    LEFT JOIN customer c ON ns.n_nationkey = c.c_nationkey
    LEFT JOIN CustomerSpend cs ON c.c_custkey = cs.c_custkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT r.r_name, r.total_customer_spending, r.nation_count, 
       SUM(so.order_count) AS total_orders
FROM RegionSummary r
LEFT JOIN SupplierOrderCounts so ON so.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE CAST(s.s_comment AS STRING) LIKE '%special%'
)
GROUP BY r.r_name, r.total_customer_spending, r.nation_count
ORDER BY r.total_customer_spending DESC, r.nation_count DESC
LIMIT 10;
