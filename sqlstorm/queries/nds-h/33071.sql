WITH  regional_sales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
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
        o.o_orderdate >= DATE '1996-01-01' AND 
        o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        r.r_name
),
ranked_sales AS (
    SELECT 
        region_name, 
        total_sales,
        sales_rank,
        COUNT(*) OVER () AS total_regions
    FROM 
        regional_sales
),
high_sales AS (
    SELECT 
        region_name, 
        total_sales,
        sales_rank,
        total_regions,
        CASE 
            WHEN total_sales > (SELECT AVG(total_sales) FROM ranked_sales) THEN 'Above Average'
            ELSE 'Below Average'
        END AS performance
    FROM 
        ranked_sales
    WHERE 
        sales_rank <= 5
)
SELECT 
    h.region_name,
    h.total_sales,
    h.performance,
    COALESCE((SELECT SUM(s.s_acctbal) 
               FROM supplier s 
               JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
               JOIN part p ON ps.ps_partkey = p.p_partkey 
               WHERE p.p_name LIKE '%' || h.region_name || '%' 
               AND p.p_retailprice IS NOT NULL), 0) AS supplier_total_acctbal
FROM 
    high_sales h
ORDER BY 
    h.total_sales DESC;