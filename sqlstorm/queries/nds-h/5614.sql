WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, c.c_name, c.c_nationkey
),
TopRegions AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(ro.total_revenue) AS total_nation_revenue
    FROM 
        RankedOrders ro
    JOIN 
        supplier s ON s.s_suppkey = ro.o_orderkey 
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    tr.nation_name,
    tr.total_nation_revenue,
    CASE 
        WHEN tr.total_nation_revenue > (SELECT AVG(total_nation_revenue) FROM TopRegions) THEN 'Above Average'
        ELSE 'Below Average'
    END AS revenue_category
FROM 
    TopRegions tr
ORDER BY 
    tr.total_nation_revenue DESC
LIMIT 10;