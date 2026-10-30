WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01'
        AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
),
TopRevenueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.c_name,
        o.total_revenue
    FROM 
        RankedOrders o
    WHERE 
        o.revenue_rank <= 10
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.c_name,
    o.total_revenue,
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    p.p_brand,
    SUM(l.l_quantity) AS total_quantity
FROM 
    TopRevenueOrders o
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
GROUP BY 
    o.o_orderkey, o.o_orderdate, o.c_name, o.total_revenue, s.s_name, p.p_name, p.p_brand
ORDER BY 
    o.total_revenue DESC;