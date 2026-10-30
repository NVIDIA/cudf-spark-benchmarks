WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),

RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01'
),

FilteredLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' 
    GROUP BY l.l_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
)

SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(pl.net_revenue) AS total_revenue,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    RANK() OVER (ORDER BY SUM(pl.net_revenue) DESC) AS revenue_rank
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN FilteredLineItems pl ON pl.l_orderkey = ps.ps_partkey
JOIN RankedOrders ro ON ro.o_orderkey = pl.l_orderkey
WHERE p.p_type LIKE '%office%'
AND s.s_acctbal IS NOT NULL
GROUP BY p.p_name
HAVING COUNT(DISTINCT s.s_suppkey) > 1
ORDER BY total_revenue DESC, supplier_count ASC
LIMIT 10 OFFSET 0;