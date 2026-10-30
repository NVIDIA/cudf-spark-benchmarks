WITH RegionalSales AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        r.r_regionkey, r.r_name
),
SalesRank AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        r.total_sales,
        RANK() OVER (ORDER BY r.total_sales DESC) AS sales_rank
    FROM 
        RegionalSales r
)
SELECT 
    sr.r_regionkey,
    sr.r_name,
    sr.total_sales,
    sr.sales_rank,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(c.c_acctbal) AS average_customer_balance
FROM 
    SalesRank sr
LEFT JOIN 
    orders o ON sr.sales_rank <= 10
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
GROUP BY 
    sr.r_regionkey, sr.r_name, sr.total_sales, sr.sales_rank
HAVING 
    SUM(sr.total_sales) > 0
ORDER BY 
    sr.sales_rank;
