WITH SupplierSales AS (
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
    GROUP BY 
        s.s_suppkey, s.s_name
),
NationSales AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        SUM(ss.total_sales) AS nation_sales
    FROM 
        nation n
    JOIN 
        supplier s ON s.s_nationkey = n.n_nationkey
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
RegionalSales AS (
    SELECT 
        r.r_regionkey, 
        r.r_name, 
        SUM(ns.nation_sales) AS regional_sales
    FROM 
        region r
    JOIN 
        nation n ON n.n_regionkey = r.r_regionkey
    JOIN 
        NationSales ns ON ns.n_nationkey = n.n_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    r.r_name, 
    r.regional_sales
FROM 
    RegionalSales r
ORDER BY 
    r.regional_sales DESC
LIMIT 10;
