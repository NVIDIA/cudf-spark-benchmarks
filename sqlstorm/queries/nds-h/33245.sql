WITH  SalesCTE AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
RegionSales AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(sc.total_sales) AS total_region_sales
    FROM 
        SalesCTE sc
    JOIN 
        supplier s ON sc.c_custkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    r.region_name,
    r.nation_name,
    r.total_region_sales,
    CASE 
        WHEN r.total_region_sales IS NULL THEN 'No Sales'
        ELSE CAST(r.total_region_sales AS STRING)
    END AS sales_description
FROM 
    RegionSales r
FULL OUTER JOIN 
    (SELECT DISTINCT r_name FROM region) r2 ON r.region_name = r2.r_name
WHERE 
    r.total_region_sales > 10000 OR r.total_region_sales IS NULL
ORDER BY 
    r.total_region_sales DESC NULLS LAST;