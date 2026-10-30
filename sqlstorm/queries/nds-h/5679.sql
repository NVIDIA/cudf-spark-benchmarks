
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_order
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.total_revenue
    FROM 
        RankedOrders ro
    WHERE 
        ro.rank_order <= 10
),
SuppliersWithHighRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l JOIN TopOrders t ON l.l_orderkey = t.o_orderkey)
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
    shr.s_name AS supplier_name,
    shr.total_cost AS supplier_cost
FROM 
    TopOrders o
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    SuppliersWithHighRevenue shr ON l.l_suppkey = shr.s_suppkey
GROUP BY 
    o.o_orderkey, o.o_orderdate, shr.s_name, shr.total_cost
ORDER BY 
    o.o_orderdate, order_total DESC;
