
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL
),
AveragePrices AS (
    SELECT 
        ps.ps_partkey,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
FilteredOrders AS (
    SELECT 
        os.o_orderkey,
        os.total_revenue,
        RANK() OVER (ORDER BY os.total_revenue DESC) AS revenue_rank
    FROM OrderStats os
    WHERE os.total_revenue > 10000
)
SELECT 
    r.s_name,
    r.nation_name,
    r.s_acctbal,
    ap.avg_supplycost,
    fo.total_revenue
FROM RankedSuppliers r
LEFT JOIN AveragePrices ap ON r.s_suppkey = (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_container = 'LG BOX')
    LIMIT 1
)
JOIN FilteredOrders fo ON r.s_suppkey = fo.o_orderkey
WHERE r.rn <= 3 AND fo.revenue_rank <= 5
ORDER BY r.nation_name, r.s_acctbal DESC;
