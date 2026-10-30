WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_nationkey
),
TopNations AS (
    SELECT 
        n.n_name, 
        SUM(RO.total_revenue) AS total_revenue
    FROM 
        RankedOrders RO
    JOIN 
        customer c ON RO.o_orderkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        RO.rn <= 5
    GROUP BY 
        n.n_name
)
SELECT 
    r.r_name,
    tn.total_revenue
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    TopNations tn ON n.n_name = tn.n_name
ORDER BY 
    r.r_name, tn.total_revenue DESC;
