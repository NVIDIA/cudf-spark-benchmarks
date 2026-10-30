WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
), 
PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost) AS total_cost
    FROM 
        partsupp ps 
    GROUP BY 
        ps.ps_partkey
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_value
    FROM 
        supplier s
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
    os.o_orderdate,
    os.c_name,
    os.total_sales,
    os.distinct_parts,
    os.total_quantity,
    ps.total_available,
    ps.total_cost,
    ts.s_name AS top_supplier
FROM 
    OrderSummary os
JOIN 
    PartSupplier ps ON os.o_orderkey = ps.ps_partkey
JOIN 
    TopSuppliers ts ON ps.ps_partkey = ts.s_suppkey
WHERE 
    os.total_sales > 10000
ORDER BY 
    os.total_sales DESC, 
    os.o_orderdate ASC;