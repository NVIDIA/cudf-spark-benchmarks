WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM orders o
    WHERE o.o_orderdate > (cast('1998-10-01' as date) - INTERVAL '1 year') 
      AND o.o_orderstatus IN ('O', 'F')
), 
TotalRevenue AS (
    SELECT 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        l.l_orderkey
    FROM lineitem l
    GROUP BY l.l_orderkey
), 
SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS product_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY s.s_suppkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name, 
    p.p_name AS part_name,
    COALESCE(tr.total_revenue, 0) AS revenue,
    COALESCE(SUM(ss.total_cost), 0) AS supplier_total_cost,
    CASE 
        WHEN SUM(ss.product_count) IS NULL THEN 'No Suppliers' 
        ELSE 'Available Suppliers' 
    END AS supplier_availability
FROM region r 
JOIN nation n ON r.r_regionkey = n.n_regionkey 
JOIN supplier s ON n.n_nationkey = s.s_nationkey 
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey 
LEFT JOIN TotalRevenue tr ON tr.l_orderkey = ps.ps_partkey 
LEFT JOIN SupplierStats ss ON ss.s_suppkey = s.s_suppkey 
WHERE p.p_container IS NOT NULL 
AND (p.p_size BETWEEN 1 AND 30 OR p.p_size IS NULL)
GROUP BY r.r_name, n.n_name, p.p_name, tr.total_revenue 
HAVING SUM(ps.ps_availqty) > 0
ORDER BY revenue DESC NULLS LAST;