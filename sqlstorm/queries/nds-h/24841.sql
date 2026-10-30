WITH RankedSales AS (
    SELECT 
        ps_partkey,
        ps_suppkey,
        ps_availqty,
        ps_supplycost,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost DESC) AS cost_rank
    FROM 
        partsupp
    WHERE 
        ps_availqty > 0
),
HighCostSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        r.r_name,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        RankedSales rs ON s.s_suppkey = rs.ps_suppkey
    JOIN 
        part p ON p.p_partkey = rs.ps_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.cost_rank = 1 AND s.s_acctbal IS NOT NULL
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, r.r_name
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate > cast('1998-10-01' as date) - INTERVAL '1 YEAR'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice
)
SELECT 
    h.s_name,
    h.r_name,
    h.part_count,
    r.total_revenue,
    CASE 
        WHEN h.part_count IS NULL THEN 'No parts'
        WHEN h.part_count > 5 THEN 'Many parts'
        ELSE 'Few parts'
    END AS category,
    COALESCE(SUM(r.total_revenue), 0) AS total_revenue_sum
FROM 
    HighCostSuppliers h
LEFT JOIN 
    RecentOrders r ON h.part_count = (
        SELECT AVG(part_count) FROM HighCostSuppliers
    )
WHERE 
    h.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
    OR h.s_name IS NULL
GROUP BY 
    h.s_name, h.r_name, h.part_count, r.total_revenue
ORDER BY 
    total_revenue_sum DESC NULLS LAST;