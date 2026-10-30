WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_nationkey
),
TopNations AS (
    SELECT 
        n.n_name,
        SUM(ro.total_revenue) AS nation_revenue
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.o_orderkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        ro.revenue_rank <= 5
    GROUP BY 
        n.n_name
)
SELECT 
    n.n_name,
    nt.nation_revenue
FROM 
    nation n
JOIN 
    TopNations nt ON n.n_name = nt.n_name
ORDER BY 
    nt.nation_revenue DESC;
