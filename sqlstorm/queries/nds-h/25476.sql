WITH PartSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        p.p_partkey, p.p_name
),
RankedSales AS (
    SELECT 
        ps.p_partkey,
        ps.p_name,
        ps.total_sales,
        ps.order_count,
        RANK() OVER (ORDER BY ps.total_sales DESC) AS sales_rank
    FROM 
        PartSales ps
    WHERE 
        ps.total_sales > 0
)
SELECT 
    rs.p_partkey,
    rs.p_name,
    rs.total_sales,
    rs.order_count,
    rs.sales_rank,
    CONCAT('Top Seller: ', rs.p_name) AS seller_tag,
    REPLACE(REPLACE(rs.p_name, ' ', '-'), 'TOP-', 'PREMIUM-') AS formatted_name
FROM 
    RankedSales rs
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    rs.sales_rank;