
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
        AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopNations AS (
    SELECT 
        n.n_name,
        SUM(RankedOrders.revenue) AS total_revenue,
        c.c_nationkey,  -- added to GROUP BY
        n.n_nationkey   -- added to GROUP BY
    FROM 
        RankedOrders
    JOIN 
        customer c ON c.c_custkey = RankedOrders.o_orderkey  
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name, c.c_nationkey, n.n_nationkey  -- updated GROUP BY
    ORDER BY 
        total_revenue DESC
    LIMIT 5
)
SELECT 
    n.n_name,
    n.total_revenue,
    r.r_comment
FROM 
    TopNations n
JOIN 
    region r ON n.c_nationkey = r.r_regionkey  -- fixed join condition
WHERE 
    r.r_name = 'Europe'
ORDER BY 
    n.total_revenue DESC;
