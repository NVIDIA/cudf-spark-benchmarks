WITH RevenueBySupplier AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name 
    FROM 
        RevenueBySupplier s
    WHERE 
        total_revenue = (SELECT MAX(total_revenue) FROM RevenueBySupplier)
),
OrderCount AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    ts.s_name, 
    oc.order_count
FROM 
    TopSuppliers ts
JOIN 
    OrderCount oc ON ts.s_suppkey = oc.c_custkey
ORDER BY 
    oc.order_count DESC
LIMIT 10;