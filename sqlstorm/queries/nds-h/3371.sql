
WITH RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS recent_order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_nationkey
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COALESCE(so.total_revenue, 0) AS total_revenue,
    ss.total_parts,
    ss.avg_supplycost
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    (SELECT 
        o.o_orderdate, 
        SUM(o.total_revenue) AS total_revenue, 
        n.n_nationkey
     FROM 
        RecentOrders o
     JOIN 
        nation n ON o.recent_order_rank = n.n_nationkey
     GROUP BY 
        o.o_orderdate, n.n_nationkey) so ON n.n_nationkey = so.n_nationkey
LEFT JOIN 
    SupplierStats ss ON ss.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps
        JOIN part p ON ps.ps_partkey = p.p_partkey
        WHERE p.p_retailprice > 100.00
    )
WHERE 
    ss.total_parts IS NOT NULL
ORDER BY 
    total_revenue DESC, nation_name;
