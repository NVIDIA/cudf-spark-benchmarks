
WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
),
SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_availqty
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
OrderDetails AS (
    SELECT li.l_orderkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
           COUNT(DISTINCT li.l_linenumber) AS line_items_count
    FROM lineitem li
    JOIN RankedOrders ro ON li.l_orderkey = ro.o_orderkey
    WHERE li.l_shipdate BETWEEN CURRENT_DATE - INTERVAL '1 year' AND CURRENT_DATE
    GROUP BY li.l_orderkey
)
SELECT r.r_name, p.p_name, COALESCE(ROUND(SUM(od.total_sales), 2), 0) AS total_sales,
       AVG(sp.total_availqty) AS avg_availqty
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN SupplierParts sp ON s.s_suppkey = sp.ps_suppkey
JOIN part p ON sp.ps_partkey = p.p_partkey
LEFT JOIN OrderDetails od ON s.s_suppkey = od.l_orderkey 
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size < 10)
  AND r.r_name <> 'ASIA'
GROUP BY r.r_name, p.p_name
HAVING AVG(sp.total_availqty) >= 100
ORDER BY total_sales DESC, p.p_name ASC
LIMIT 10;
