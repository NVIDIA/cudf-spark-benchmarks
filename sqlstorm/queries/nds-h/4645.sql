WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS num_orders
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND
        l.l_shipdate >= '1997-01-01' AND 
        l.l_shipdate < '1998-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),

SupplierRanked AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.total_sales,
        s.num_orders,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        SupplierSales s
)

SELECT 
    r.r_name,
    n.n_name,
    sr.s_name,
    sr.total_sales,
    sr.num_orders,
    sr.sales_rank
FROM 
    SupplierRanked sr
LEFT JOIN 
    supplier s ON sr.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    sr.sales_rank <= 10 AND 
    (n.n_comment IS NULL OR n.n_comment <> '') 
ORDER BY 
    r.r_name, sr.total_sales DESC;