
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s 
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
), 
TopSuppliers AS (
    SELECT 
        r.r_name,
        rs.s_name,
        rs.s_acctbal
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.rn = 1
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), 
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_custkey) AS unique_customers
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey
)

SELECT 
    ts.r_name AS region_name,
    ts.s_name AS supplier_name,
    COUNT(os.o_orderkey) AS order_count,
    SUM(os.total_sales) AS total_sales,
    AVG(ts.s_acctbal) AS avg_supplier_acctbal
FROM 
    TopSuppliers ts
LEFT OUTER JOIN 
    OrderSummary os ON ts.s_name = CAST(os.o_orderkey AS STRING)  
GROUP BY 
    ts.r_name, ts.s_name, ts.s_acctbal
HAVING 
    COUNT(os.o_orderkey) > 0
    AND SUM(os.total_sales) > 10000.00
ORDER BY 
    total_sales DESC, ts.r_name;
