
WITH  CTE_SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        JOIN part p ON ps.ps_partkey = p.p_partkey
        JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),
Filtered_Suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(cte.total_sales, 0) AS total_sales
    FROM 
        supplier s
        LEFT JOIN CTE_SupplierSales cte ON s.s_suppkey = cte.s_suppkey
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal)
            FROM supplier s2
        )
)
SELECT 
    fs.s_suppkey,
    fs.s_name,
    CASE 
        WHEN fs.total_sales > 10000 THEN 'High Performer'
        WHEN fs.total_sales BETWEEN 5000 AND 10000 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS total_returns,
    COUNT(DISTINCT o.o_orderkey) AS number_of_orders
FROM 
    Filtered_Suppliers fs
    JOIN nation n ON fs.s_suppkey = n.n_nationkey  
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN partsupp ps ON fs.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
GROUP BY 
    fs.s_suppkey, fs.s_name, r.r_name, n.n_name, fs.total_sales
ORDER BY 
    fs.total_sales DESC, performance_category;
