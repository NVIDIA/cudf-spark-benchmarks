WITH SupplierRatings AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
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
        s.s_acctbal > 0
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT 
        sr.s_suppkey, 
        sr.s_name, 
        sr.total_sales, 
        rn.r_name,
        DENSE_RANK() OVER (ORDER BY sr.total_sales DESC) AS sales_rank
    FROM 
        SupplierRatings sr
    JOIN 
        supplier s ON sr.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region rn ON n.n_regionkey = rn.r_regionkey
)
SELECT 
    ts.s_suppkey,
    ts.s_name, 
    ts.total_sales,
    ts.sales_rank,
    CONCAT('Supplier ', ts.s_name, ' with sales of $', ROUND(ts.total_sales, 2)) AS sales_description
FROM 
    TopSuppliers ts
WHERE 
    ts.sales_rank <= 10
ORDER BY 
    ts.sales_rank;
