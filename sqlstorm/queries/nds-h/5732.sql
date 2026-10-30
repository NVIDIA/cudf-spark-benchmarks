WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
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
TopRevenueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        r.total_revenue
    FROM 
        RankedOrders r
    JOIN 
        orders o ON r.o_orderkey = o.o_orderkey
    WHERE 
        r.order_rank <= 5
)
SELECT 
    n.n_name AS nation,
    COUNT(DISTINCT c.c_custkey) AS number_of_customers,
    SUM(tr.total_revenue) AS total_revenue
FROM 
    TopRevenueOrders tr
JOIN 
    customer c ON c.c_custkey = tr.o_orderkey
JOIN 
    supplier s ON s.s_suppkey = c.c_nationkey
JOIN 
    nation n ON n.n_nationkey = s.s_nationkey
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue DESC;