WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
NationsRevenue AS (
    SELECT 
        n.n_name,
        SUM(ro.total_revenue) AS nation_revenue
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.o_orderkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    nr.n_name,
    nr.nation_revenue,
    RANK() OVER (ORDER BY nr.nation_revenue DESC) AS revenue_rank
FROM 
    NationsRevenue nr
WHERE 
    nr.nation_revenue > (SELECT AVG(nation_revenue) FROM NationsRevenue)
ORDER BY 
    nr.nation_revenue DESC;
