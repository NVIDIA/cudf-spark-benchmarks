WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS unique_customers,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
RankedOrders AS (
    SELECT 
        os.o_orderkey,
        os.o_orderdate,
        os.total_revenue,
        os.unique_customers,
        os.unique_parts,
        RANK() OVER (ORDER BY os.total_revenue DESC) AS revenue_rank
    FROM 
        OrderSummary os
)
SELECT 
    r.r_name AS region_name,
    COUNT(ro.o_orderkey) AS total_orders,
    AVG(ro.total_revenue) AS average_revenue,
    SUM(ro.unique_customers) AS total_unique_customers,
    SUM(ro.unique_parts) AS total_unique_parts
FROM 
    RankedOrders ro
JOIN 
    customer c ON ro.o_orderkey = c.c_custkey
JOIN 
    supplier s ON c.c_nationkey = s.s_nationkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    ro.revenue_rank <= 100
GROUP BY 
    r.r_name
ORDER BY 
    total_orders DESC, average_revenue DESC;