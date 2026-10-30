WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01'
),
SupplierParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty, 
           COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, sp.total_avail_qty, sp.unique_suppliers,
           RANK() OVER (ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    JOIN SupplierParts sp ON p.p_partkey = sp.ps_partkey
    WHERE p.p_retailprice IS NOT NULL
)
SELECT r.r_name, COUNT(DISTINCT c.c_custkey) AS customer_count,
       AVG(lo.l_extendedprice * (1 - lo.l_discount)) AS avg_value,
       SUM(CASE WHEN lo.l_returnflag = 'R' THEN 1 ELSE 0 END) AS total_returns,
       COUNT(DISTINCT t.p_partkey) AS top_parts_count
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN lineitem lo ON ps.ps_partkey = lo.l_partkey
LEFT JOIN TopParts t ON ps.ps_partkey = t.p_partkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
WHERE t.price_rank <= 10 AND c.c_acctbal IS NOT NULL
GROUP BY r.r_name
ORDER BY customer_count DESC, avg_value DESC;