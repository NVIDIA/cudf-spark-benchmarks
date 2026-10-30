WITH TotalSales AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        part AS p
    JOIN 
        lineitem AS l ON p.p_partkey = l.l_partkey
    JOIN 
        orders AS o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        p.p_partkey
),
RankedSales AS (
    SELECT 
        ts.p_partkey,
        ts.total_revenue,
        ts.order_count,
        RANK() OVER (ORDER BY ts.total_revenue DESC) AS sales_rank
    FROM 
        TotalSales AS ts
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_type,
    rs.total_revenue,
    rs.order_count,
    rs.sales_rank
FROM 
    RankedSales AS rs
JOIN 
    part AS p ON rs.p_partkey = p.p_partkey
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    rs.sales_rank;