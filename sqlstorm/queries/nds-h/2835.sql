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
        o.o_orderdate >= DATE '1997-01-01'
        AND o.o_orderdate < DATE '1997-12-31'
        AND l.l_returnflag = 'N'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales,
        ss.order_count,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(ts.order_count, 0) AS order_count,
    CASE 
        WHEN ts.sales_rank IS NULL THEN 'Not Ranked'
        ELSE CONCAT('Rank ', ts.sales_rank)
    END AS sales_rank
FROM 
    TopSuppliers ts
FULL OUTER JOIN 
    supplier s ON ts.s_suppkey = s.s_suppkey
WHERE 
    s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name IN ('USA', 'Germany', 'Japan'))
ORDER BY 
    total_sales DESC, order_count DESC
LIMIT 10;