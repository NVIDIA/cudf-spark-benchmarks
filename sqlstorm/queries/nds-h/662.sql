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
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' 
        AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
), RegionSales AS (
    SELECT 
        n.n_regionkey,
        SUM(ss.total_sales) AS region_sales
    FROM 
        SupplierSales ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_regionkey
), HighestSales AS (
    SELECT 
        r.r_regionkey,
        RANK() OVER (ORDER BY rs.region_sales DESC) AS sales_rank,
        rs.region_sales
    FROM 
        region r
    LEFT JOIN 
        RegionSales rs ON r.r_regionkey = rs.n_regionkey
)
SELECT 
    r.r_name, 
    COALESCE(hs.region_sales, 0) AS sales_amount,
    hs.sales_rank
FROM 
    region r
LEFT JOIN 
    HighestSales hs ON r.r_regionkey = hs.r_regionkey
WHERE 
    (hs.sales_rank IS NULL OR hs.sales_rank <= 5) 
ORDER BY 
    sales_amount DESC;