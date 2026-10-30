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
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey
),
BestSuppliers AS (
    SELECT 
        sc.s_suppkey,
        SUM(od.total_revenue) AS revenue_generated
    FROM 
        SupplierCosts sc
    JOIN 
        partsupp ps ON sc.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        OrderDetails od ON l.l_orderkey = od.o_orderkey
    GROUP BY 
        sc.s_suppkey
    ORDER BY 
        revenue_generated DESC
    LIMIT 10
)
SELECT 
    s.s_name,
    s.s_address,
    sc.total_cost,
    bs.revenue_generated
FROM 
    supplier s
JOIN 
    SupplierCosts sc ON s.s_suppkey = sc.s_suppkey
JOIN 
    BestSuppliers bs ON s.s_suppkey = bs.s_suppkey
ORDER BY 
    sc.total_cost DESC;