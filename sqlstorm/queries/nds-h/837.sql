WITH regional_sales AS (
    SELECT 
        r.r_name AS region_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        r.r_name
),
region_ranked AS (
    SELECT 
        region_name, 
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        regional_sales
),
supplier_avg_cost AS (
    SELECT 
        ps.ps_suppkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
),
final_sales AS (
    SELECT 
        r.region_name,
        r.total_sales,
        r.order_count,
        ra.avg_supply_cost,
        COALESCE(ra.avg_supply_cost, 0) AS adjusted_avg_cost
    FROM 
        region_ranked r
    LEFT JOIN 
        supplier_avg_cost ra ON r.sales_rank = ra.ps_suppkey
)
SELECT 
    fs.region_name,
    fs.total_sales,
    fs.order_count,
    fs.adjusted_avg_cost,
    CASE 
        WHEN fs.total_sales > 1000000 THEN 'High Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    final_sales fs
WHERE 
    fs.total_sales IS NOT NULL 
ORDER BY 
    fs.total_sales DESC;