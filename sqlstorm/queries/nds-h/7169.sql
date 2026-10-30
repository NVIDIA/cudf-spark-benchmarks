WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate <= DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRegions AS (
    SELECT 
        n.n_regionkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        n.n_regionkey
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT ro.o_orderkey) AS number_of_orders,
    SUM(ro.revenue) AS total_revenue,
    AVG(ro.revenue) AS average_order_value,
    tr.total_revenue AS region_revenue
FROM 
    region r
LEFT JOIN 
    RankedOrders ro ON ro.o_orderdate IS NOT NULL
LEFT JOIN 
    TopRegions tr ON r.r_regionkey = tr.n_regionkey
GROUP BY 
    r.r_regionkey, r.r_name, tr.total_revenue
HAVING 
    AVG(ro.revenue) > 1000
ORDER BY 
    total_revenue DESC
LIMIT 10;