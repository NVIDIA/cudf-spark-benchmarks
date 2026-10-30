
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
HighRevenueOrders AS (
    SELECT 
        r.o_orderkey,
        r.total_revenue,
        r.o_orderdate,
        r.o_orderstatus
    FROM 
        RankedOrders r
    WHERE 
        r.revenue_rank <= 10
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT l.l_suppkey) AS unique_suppliers,
    c.c_mktsegment
FROM 
    HighRevenueOrders ho
JOIN 
    orders o ON ho.o_orderkey = o.o_orderkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    o.o_orderstatus = 'O'
GROUP BY 
    o.o_orderkey, o.o_orderdate, c.c_mktsegment
ORDER BY 
    total_revenue DESC;
