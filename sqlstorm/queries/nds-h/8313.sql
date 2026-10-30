WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS brand_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_brand
),
TotalOrderValue AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey, rs.s_name, rs.total_cost 
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.brand_rank <= 5
),
AverageOrderValue AS (
    SELECT 
        AVG(order_value) AS avg_value 
    FROM 
        TotalOrderValue
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.total_cost,
    a.avg_value
FROM 
    TopSuppliers ts
CROSS JOIN 
    AverageOrderValue a
WHERE 
    ts.total_cost > a.avg_value
ORDER BY 
    ts.total_cost DESC;
