WITH nation_supplier_sales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        nation n
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
    GROUP BY 
        n.n_name
), 
region_sales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(ns.total_sales) AS region_total_sales
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        nation_supplier_sales ns ON n.n_name = ns.nation_name
    GROUP BY 
        r.r_name
)
SELECT 
    rs.region_name,
    rs.region_total_sales,
    RANK() OVER (ORDER BY rs.region_total_sales DESC) AS sales_rank
FROM 
    region_sales rs
WHERE 
    rs.region_total_sales > 100000
ORDER BY 
    rs.region_total_sales DESC;
