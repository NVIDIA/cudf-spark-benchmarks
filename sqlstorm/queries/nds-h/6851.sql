WITH RankedSales AS (
    SELECT 
        ps.ps_partkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, p.p_brand
),
TopBrands AS (
    SELECT 
        p.p_brand, 
        SUM(rs.total_sales) AS brand_sales
    FROM 
        RankedSales rs
    JOIN 
        part p ON rs.ps_partkey = p.p_partkey
    WHERE 
        rs.sales_rank <= 5
    GROUP BY 
        p.p_brand
),
RegionSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    rb.p_brand, 
    rb.brand_sales, 
    rs.nation_name, 
    rs.total_sales,
    (rb.brand_sales / NULLIF(rs.total_sales, 0)) * 100 AS percentage_of_sales
FROM 
    TopBrands rb
JOIN 
    RegionSales rs ON rb.p_brand = rs.nation_name
ORDER BY 
    percentage_of_sales DESC;
