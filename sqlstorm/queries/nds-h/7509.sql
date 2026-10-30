
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rnk
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(total_cost) FROM (SELECT SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost FROM supplier s JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey GROUP BY s.s_suppkey) avg_cost)
),
FinalResult AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.revenue,
        ts.s_name AS top_supplier
    FROM 
        RankedOrders ro
    JOIN 
        TopSuppliers ts ON ro.o_orderkey % ts.s_suppkey = 0
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    COALESCE(o.revenue, 0) AS revenue,
    COALESCE(fs.top_supplier, 'None') AS top_supplier_name
FROM 
    RankedOrders o
LEFT JOIN 
    FinalResult fs ON o.o_orderkey = fs.o_orderkey
ORDER BY 
    o.revenue DESC, o.o_orderdate;
