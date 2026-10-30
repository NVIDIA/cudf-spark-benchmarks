
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_extended_price,
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
QualifiedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_availqty) > 1000
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    c.c_name AS customer_name,
    COUNT(DISTINCT rq.o_orderkey) AS total_orders,
    AVG(q.total_supplycost) AS avg_supply_cost,
    SUM(rq.total_extended_price) AS total_revenue
FROM 
    RankedOrders rq
JOIN 
    customer c ON rq.o_orderkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    QualifiedSuppliers q ON c.c_nationkey = q.s_suppkey
GROUP BY 
    r.r_name, n.n_name, c.c_name
HAVING 
    SUM(rq.total_extended_price) > 50000
ORDER BY 
    total_revenue DESC;
