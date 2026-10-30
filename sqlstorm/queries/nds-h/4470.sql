WITH SuppOrderAnalysis AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        AVG(l.l_quantity) AS avg_quantity_per_order
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_nationkey,
        n.n_name AS nation_name,
        SUM(o.o_totalprice) AS total_spend
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, n.n_nationkey, n.n_name
)
SELECT 
    ra.s_suppkey,
    ra.s_name,
    ra.total_revenue,
    ra.total_orders,
    ra.avg_quantity_per_order,
    cr.c_custkey,
    cr.c_name,
    cr.nation_name,
    cr.total_spend
FROM 
    SuppOrderAnalysis ra
FULL OUTER JOIN 
    CustomerRegion cr ON ra.s_suppkey = cr.n_nationkey
WHERE 
    (ra.total_revenue IS NOT NULL OR cr.total_spend IS NOT NULL)
    AND (ra.total_orders > 10 OR cr.total_spend > 1000)
ORDER BY 
    COALESCE(ra.total_revenue, 0) DESC, 
    COALESCE(cr.total_spend, 0) DESC;
