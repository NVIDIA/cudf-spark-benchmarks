WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name, 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS number_of_orders
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
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
        o.o_orderstatus = 'O' 
        AND l.l_shipdate > '1997-01-01'
    GROUP BY 
        n.n_name, r.r_name
),
RankedSales AS (
    SELECT 
        nation_name, 
        region_name,
        total_sales,
        number_of_orders,
        RANK() OVER (PARTITION BY region_name ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
)
SELECT 
    COALESCE(r.region_name, 'Unknown Region') AS region_name,
    r.nation_name,
    r.total_sales,
    r.number_of_orders,
    CASE 
        WHEN r.sales_rank = 1 THEN 'Top Seller'
        WHEN r.sales_rank <= 3 THEN 'High Seller'
        ELSE 'Regular Seller' 
    END AS seller_category
FROM 
    RankedSales r 
LEFT JOIN 
    region rg ON r.region_name = rg.r_name
WHERE 
    r.total_sales IS NOT NULL
ORDER BY 
    r.region_name, r.total_sales DESC;