WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name, 
        rs.s_suppkey, 
        rs.s_name, 
        rs.s_acctbal
    FROM 
        region r
    JOIN 
        RankedSuppliers rs ON r.r_regionkey = rs.s_suppkey
    WHERE 
        rs.supplier_rank <= 5
),
CustomerOrderSummary AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS total_orders
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
)
SELECT 
    ts.r_name AS region_name, 
    ts.s_name AS top_supplier, 
    cos.c_name AS customer_name, 
    cos.total_order_value, 
    cos.total_orders
FROM 
    TopSuppliers ts
JOIN 
    CustomerOrderSummary cos ON ts.s_suppkey = cos.c_custkey
ORDER BY 
    ts.r_name, cos.total_order_value DESC
LIMIT 10;
