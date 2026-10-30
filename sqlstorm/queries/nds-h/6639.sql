WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRevenueOrders AS (
    SELECT 
        r.o_orderkey, 
        r.o_orderdate,
        r.total_revenue,
        c.c_name,
        n.n_name AS nation_name
    FROM 
        RankedOrders r
    JOIN 
        orders o ON r.o_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        r.revenue_rank <= 10
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.total_revenue,
    c.c_name,
    n.n_name,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY o.total_revenue DESC) AS nation_order
FROM 
    TopRevenueOrders o
JOIN 
    customer c ON o.c_name = c.c_name
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
ORDER BY 
    o.o_orderdate, total_revenue DESC;
