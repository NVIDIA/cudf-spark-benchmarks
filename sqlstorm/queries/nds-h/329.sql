WITH NationwideSales AS (
    SELECT 
        c.c_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_nationkey
)
SELECT 
    n.n_name,
    COALESCE(ns.total_sales, 0) AS total_sales,
    COALESCE(ns.total_orders, 0) AS total_orders,
    CASE 
        WHEN ns.sales_rank IS NULL THEN 'Not Ranked'
        ELSE CAST(ns.sales_rank AS STRING)
    END AS sales_rank
FROM 
    nation n
LEFT JOIN 
    NationwideSales ns ON n.n_nationkey = ns.c_nationkey
WHERE 
    n.n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name LIKE 'E%')
ORDER BY 
    total_sales DESC, n.n_name ASC;
