WITH  supplier_sales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' 
        AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
    UNION ALL
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate < DATE '1996-01-01' 
        AND l.l_shipdate >= DATE '1995-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
region_sales AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(ss.total_sales) AS region_total_sales
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        supplier_sales ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY 
        r.r_regionkey, r.r_name
),
final_output AS (
    SELECT 
        rs.region_total_sales,
        rs.r_name,
        ROW_NUMBER() OVER (ORDER BY rs.region_total_sales DESC) AS sales_rank
    FROM 
        region_sales rs
)
SELECT 
    fo.r_name,
    fo.region_total_sales,
    CASE 
        WHEN fo.region_total_sales IS NULL THEN 'No Sales'
        WHEN fo.region_total_sales > 100000 THEN 'High Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    final_output fo
WHERE 
    fo.sales_rank <= 5
ORDER BY 
    fo.sales_rank;