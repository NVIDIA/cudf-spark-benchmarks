
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
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopNOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.total_revenue
    FROM 
        RankedOrders o 
    WHERE 
        o.revenue_rank <= 10
)
SELECT 
    t.o_orderkey,
    t.o_orderdate,
    c.c_name,
    s.s_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_spent,
    SUM(l.l_extendedprice * l.l_discount) AS total_discount
FROM 
    TopNOrders t
JOIN 
    lineitem l ON t.o_orderkey = l.l_orderkey
JOIN 
    orders o ON t.o_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    t.o_orderkey, t.o_orderdate, c.c_name, s.s_name
ORDER BY 
    total_spent DESC;
