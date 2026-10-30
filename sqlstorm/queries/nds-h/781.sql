WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        s.s_acctbal > 1000 AND 
        o.o_orderstatus = 'O'
    GROUP BY 
        s.s_suppkey, s.s_name
), RankedSuppliers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SupplierSales
), CustomerData AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS segment_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL
)
SELECT 
    rs.s_name,
    rs.total_sales,
    rs.order_count,
    cd.c_name AS top_customer,
    cd.c_acctbal
FROM 
    RankedSuppliers rs
LEFT JOIN 
    CustomerData cd ON cd.segment_rank = 1
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    rs.total_sales DESC;
