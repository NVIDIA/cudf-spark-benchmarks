
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRevenueOrders AS (
    SELECT 
        r.o_orderkey,
        r.total_revenue
    FROM 
        RankedOrders r
    WHERE 
        r.order_rank = 1
    ORDER BY 
        r.total_revenue DESC
    LIMIT 10
)
SELECT 
    p.p_name,
    s.s_name,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
    COALESCE(TR.total_revenue, 0) AS total_revenue
FROM 
    partsupp ps
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    TopRevenueOrders TR ON TR.o_orderkey = ps.ps_partkey 
WHERE 
    s.s_acctbal > 1000
GROUP BY 
    p.p_name, s.s_name, TR.total_revenue
HAVING 
    SUM(ps.ps_supplycost * ps.ps_availqty) > 5000
ORDER BY 
    total_revenue DESC, total_cost ASC;
