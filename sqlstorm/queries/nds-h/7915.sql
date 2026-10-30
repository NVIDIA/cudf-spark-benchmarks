WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_name, o.o_orderdate, c.c_nationkey
),
TopNations AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_name
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 10
)

SELECT 
    r.r_name AS region_name,
    tn.n_name AS nation_name,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    SUM(ro.revenue) AS total_revenue
FROM 
    RankedOrders ro
JOIN 
    customer c ON ro.o_orderkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    TopNations tn ON n.n_name = tn.n_name
WHERE 
    ro.revenue_rank <= 5
GROUP BY 
    r.r_name, tn.n_name
ORDER BY 
    total_revenue DESC, r.r_name ASC;
