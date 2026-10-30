
WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
TopProducts AS (
    SELECT 
        r.r_name,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_avail_qty,
        CASE 
            WHEN COUNT(DISTINCT ps.ps_partkey) > 5 THEN 'Diverse'
            ELSE 'Specialized' 
        END AS product_type
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_comment LIKE '%excellent%'
    GROUP BY 
        r.r_name, s.s_name
    HAVING 
        SUM(ps.ps_availqty) > 500
),
FinalReport AS (
    SELECT 
        t.r_name,
        t.s_name,
        t.supplier_count,
        t.total_avail_qty,
        rs.total_sales,
        rs.sales_rank
    FROM 
        TopProducts t
    LEFT JOIN 
        RankedSales rs ON t.supplier_count = (SELECT COUNT(DISTINCT ps.ps_partkey) FROM partsupp ps WHERE ps.ps_supplycost > 50)
    WHERE 
        rs.sales_rank = 1 OR rs.sales_rank IS NULL
)
SELECT 
    f.r_name,
    f.s_name,
    COALESCE(f.total_avail_qty, 0) AS total_avail_qty,
    COALESCE(f.total_sales, CAST(0.00 AS DECIMAL)) AS total_sales,
    CASE 
        WHEN f.total_sales > 10000 THEN 'High Performer' 
        ELSE 'Low Performer' 
    END AS performance_category
FROM 
    FinalReport f
WHERE 
    f.r_name IS NOT NULL
ORDER BY 
    f.total_sales DESC, f.s_name ASC
LIMIT 10 OFFSET 5;
