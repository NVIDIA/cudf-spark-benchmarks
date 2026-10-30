WITH SupplierCosts AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sc.total_cost
    FROM 
        supplier s
    JOIN 
        SupplierCosts sc ON s.s_suppkey = sc.s_suppkey
    WHERE 
        sc.total_cost > (SELECT AVG(total_cost) FROM SupplierCosts)
    ORDER BY 
        total_cost DESC
    LIMIT 10
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_custkey, c.c_name
),
OrderSupplierData AS (
    SELECT 
        ro.o_orderkey,
        ro.total_revenue,
        ts.s_suppkey,
        ts.s_name
    FROM 
        RecentOrders ro
    JOIN 
        lineitem l ON ro.o_orderkey = l.l_orderkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        TopSuppliers ts ON s.s_suppkey = ts.s_suppkey
)
SELECT 
    osd.o_orderkey,
    osd.total_revenue,
    osd.s_suppkey,
    osd.s_name
FROM 
    OrderSupplierData osd
ORDER BY 
    osd.total_revenue DESC
LIMIT 5;