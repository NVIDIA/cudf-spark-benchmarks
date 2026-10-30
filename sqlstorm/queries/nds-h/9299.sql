
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank,
        c.c_custkey
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_mktsegment, c.c_custkey
),
region_summary AS (
    SELECT 
        n.n_regionkey,
        r.r_name AS region_name,
        SUM(ro.total_revenue) AS total_revenue_by_region
    FROM 
        ranked_orders ro
    JOIN 
        customer c ON ro.c_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.revenue_rank <= 10
    GROUP BY 
        n.n_regionkey, r.r_name
)
SELECT 
    rs.region_name,
    rs.total_revenue_by_region,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders
FROM 
    region_summary rs
JOIN 
    ranked_orders ro ON ro.o_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o
        JOIN customer c ON o.o_custkey = c.c_custkey
        WHERE c.c_acctbal > 1000
    )
GROUP BY 
    rs.region_name, rs.total_revenue_by_region
ORDER BY 
    rs.total_revenue_by_region DESC;
