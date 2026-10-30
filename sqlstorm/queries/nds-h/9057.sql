
WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ps.ps_comment
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        o.o_orderdate,
        o.o_orderstatus,
        o.o_clerk,
        o.o_shippriority
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus, o.o_clerk, o.o_shippriority
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS supplier_value
    FROM 
        SupplierParts s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    ORDER BY 
        supplier_value DESC
    LIMIT 10
)
SELECT 
    os.o_orderkey,
    os.total_sales,
    os.o_orderdate,
    os.o_orderstatus,
    os.o_clerk,
    os.o_shippriority,
    ts.s_name AS top_supplier
FROM 
    OrderSummary os
JOIN 
    TopSuppliers ts ON os.o_orderstatus = 'O' AND os.o_shippriority >= 1
WHERE 
    os.total_sales > 50000
ORDER BY 
    os.total_sales DESC;
