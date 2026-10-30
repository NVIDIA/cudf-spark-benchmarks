WITH  OrderCTE AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate DESC) AS recent_order
    FROM orders
    WHERE o_orderstatus = 'O' AND o_orderdate >= DATE '1996-01-01'
),
SupplierDetails AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rank_by_balance
    FROM supplier
    WHERE s_acctbal IS NOT NULL
),
PartSupplierCost AS (
    SELECT ps_partkey, ps_suppkey, ps_supplycost,
           RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost ASC) AS rank_by_cost
    FROM partsupp
    WHERE ps_availqty > 0
)
SELECT 
    p.p_name, 
    n.n_name AS supplier_nation,
    SUM(COALESCE(l.l_extendedprice * (1 - l.l_discount), 0)) AS total_revenue,
    AVG(o.o_totalprice) AS avg_order_price,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(s.s_acctbal) AS max_supplier_balance
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
WHERE p.p_size BETWEEN 10 AND 20
AND EXISTS (
    SELECT 1
    FROM OrderCTE oc
    WHERE oc.o_custkey = o.o_custkey
    AND oc.recent_order <= 5
)
AND COALESCE(s.s_acctbal, 0) > (
    SELECT AVG(sd.s_acctbal)
    FROM SupplierDetails sd
    WHERE sd.rank_by_balance <= 10
)
GROUP BY p.p_name, n.n_name
HAVING AVG(o.o_totalprice) > 1000
ORDER BY total_revenue DESC;