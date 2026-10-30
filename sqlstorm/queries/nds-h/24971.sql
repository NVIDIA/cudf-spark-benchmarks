WITH RegionSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus IN ('F', 'O') 
        AND l.l_shipdate BETWEEN '1994-01-01' AND '1995-01-01'
    GROUP BY 
        r.r_name
),
SalesRank AS (
    SELECT 
        region_name,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionSales
)
SELECT 
    sr.region_name,
    sr.total_sales,
    sr.order_count,
    CASE 
        WHEN sr.sales_rank <= 10 THEN 'Top 10 Region'
        WHEN sr.sales_rank BETWEEN 11 AND 20 THEN 'Top 11-20 Region'
        ELSE 'Other Region'
    END AS sales_category,
    COALESCE((
        SELECT MAX(ps_availqty)
        FROM partsupp ps
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey
            FROM part p
            WHERE p.p_mfgr = 'Manufacturer#123'
        )
    ), 0) AS max_avail_qty
FROM 
    SalesRank sr
WHERE 
    sr.order_count > (
        SELECT AVG(order_count) 
        FROM SalesRank
        WHERE sales_rank IS NOT NULL
    )
ORDER BY 
    sr.total_sales DESC
LIMIT 10 OFFSET 5;
