
WITH YearlySales AS (
    SELECT 
        EXTRACT(YEAR FROM o_orderdate) AS order_year,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales,
        c.c_nationkey
    FROM 
        orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        order_year, c.c_nationkey
),
NationSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COALESCE(SUM(ys.total_sales), 0) AS nation_sales
    FROM 
        nation n
    LEFT JOIN YearlySales ys ON n.n_nationkey = ys.c_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
RankedSales AS (
    SELECT 
        ns.*,
        RANK() OVER (ORDER BY ns.nation_sales DESC) AS sales_rank
    FROM 
        NationSales ns
)
SELECT 
    ns.n_name,
    ns.nation_sales,
    ns.sales_rank,
    (SELECT AVG(nation_sales) FROM RankedSales WHERE sales_rank <= 5) AS avg_top5_sales,
    (CASE 
        WHEN ns.nation_sales > 10000 THEN 'High'
        WHEN ns.nation_sales BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
     END) AS sales_category
FROM 
    RankedSales ns
WHERE 
    ns.sales_rank <= 10
ORDER BY 
    ns.sales_rank;
