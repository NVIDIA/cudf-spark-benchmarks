
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
AggregateOrderData AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(o.o_orderkey) AS order_count,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey
),
SupplierSales AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        SUM(ald.total_sales) AS total_sales_supp
    FROM 
        RankedSuppliers rs
    LEFT JOIN 
        AggregateOrderData ald ON rs.s_suppkey = ald.o_orderkey
    GROUP BY 
        rs.s_suppkey, rs.s_name
    HAVING 
        SUM(ald.total_sales) IS NOT NULL
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(ss.total_sales_supp, 0) AS supplier_total_sales,
    COUNT(DISTINCT ss.s_suppkey) AS unique_suppliers,
    RANK() OVER (ORDER BY COALESCE(ss.total_sales_supp, 0) DESC) AS sales_rank
FROM 
    part p
LEFT JOIN 
    SupplierSales ss ON p.p_partkey = ss.s_suppkey
WHERE 
    p.p_retailprice > (SELECT AVG(p_retailprice) FROM part) 
    AND p.p_size BETWEEN 10 AND 50
GROUP BY 
    p.p_partkey, p.p_name, ss.total_sales_supp
ORDER BY 
    sales_rank;
