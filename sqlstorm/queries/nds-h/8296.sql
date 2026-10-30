
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
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, 
        o.o_orderdate
),
TopRevenueOrders AS (
    SELECT 
        o_orderkey, 
        o_orderdate, 
        total_revenue 
    FROM 
        RankedOrders
    WHERE 
        revenue_rank <= 10
)
SELECT 
    o.o_orderkey, 
    c.c_name AS customer_name, 
    s.s_name AS supplier_name, 
    pr.p_name AS part_name, 
    o.o_orderdate, 
    tro.total_revenue, 
    COUNT(l.l_linenumber) AS line_item_count
FROM 
    TopRevenueOrders tro
JOIN 
    orders o ON tro.o_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part pr ON ps.ps_partkey = pr.p_partkey
GROUP BY 
    o.o_orderkey, 
    c.c_name, 
    s.s_name, 
    pr.p_name, 
    o.o_orderdate, 
    tro.total_revenue
ORDER BY 
    tro.total_revenue DESC;
