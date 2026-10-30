WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 5000
    GROUP BY 
        p.p_partkey, p.p_name
),
TopSales AS (
    SELECT 
        r.r_name AS region,
        n.n_name AS nation,
        rs.p_name,
        rs.total_sales
    FROM 
        RankedSales rs
    JOIN 
        supplier s ON rs.p_partkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.sales_rank <= 10
)
SELECT 
    region, 
    nation, 
    COUNT(*) AS product_count, 
    SUM(total_sales) AS region_sales
FROM 
    TopSales
GROUP BY 
    region, nation
ORDER BY 
    region_sales DESC, region;
