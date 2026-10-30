WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
), 
SalesRank AS (
    SELECT 
        nation_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
)
SELECT 
    r.r_name AS region_name,
    sr.nation_name,
    sr.total_sales,
    sr.sales_rank,
    COALESCE(s.s_acctbal, 0) AS supplier_account_balance
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SalesRank sr ON n.n_name = sr.nation_name
LEFT JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey AND s.s_acctbal > 10000
WHERE 
    sr.sales_rank <= 5 OR sr.sales_rank IS NULL
ORDER BY 
    r.r_name, sr.sales_rank;
