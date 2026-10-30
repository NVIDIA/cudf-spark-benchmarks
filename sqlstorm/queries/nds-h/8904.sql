WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rev_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate
),
TopRevenueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        r.total_revenue
    FROM 
        RankedOrders r
    JOIN 
        orders o ON r.o_orderkey = o.o_orderkey
    WHERE 
        r.rev_rank <= 10
)
SELECT 
    n.n_name AS nation,
    SUM(tr.total_revenue) AS revenue_total,
    COUNT(DISTINCT tr.o_orderkey) AS order_count
FROM 
    TopRevenueOrders tr
JOIN 
    customer c ON tr.o_orderkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
GROUP BY 
    n.n_name
ORDER BY 
    revenue_total DESC;
