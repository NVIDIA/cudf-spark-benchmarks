
WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        region r
        JOIN nation n ON r.r_regionkey = n.n_regionkey
        JOIN supplier s ON n.n_nationkey = s.s_nationkey
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        JOIN part p ON ps.ps_partkey = p.p_partkey
        JOIN lineitem l ON p.p_partkey = l.l_partkey
        JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' 
        AND o.o_orderdate < DATE '1995-12-31'
        AND o.o_orderstatus <> 'O' 
    GROUP BY 
        r.r_name
),
TopRegions AS (
    SELECT 
        region_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
),
NullSales AS (
    SELECT 
        region_name,
        COALESCE(total_sales, 0) AS sales
    FROM 
        TopRegions
)
SELECT 
    r.r_name AS region_name,
    COALESCE(ns.sales, 0) AS total_sales,
    CASE 
        WHEN ns.sales > 1000000 THEN 'High Sales'
        WHEN ns.sales BETWEEN 500000 AND 1000000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM 
    region r
LEFT JOIN 
    NullSales ns ON r.r_name = ns.region_name
LEFT JOIN 
    orders o ON o.o_orderdate >= DATE '1995-01-01' 
              AND o.o_orderdate < DATE '1996-01-01'
WHERE 
    ns.sales IS NOT NULL
GROUP BY 
    r.r_name, ns.sales
ORDER BY 
    total_sales DESC, r.r_name;
