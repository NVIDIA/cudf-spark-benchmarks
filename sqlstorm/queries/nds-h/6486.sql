
WITH TotalSales AS (
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
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        n.n_name
),
RankedSales AS (
    SELECT 
        nation_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        TotalSales
)
SELECT 
    s.nation_name,
    r.total_sales,
    r.sales_rank
FROM 
    RankedSales r
JOIN 
    (SELECT DISTINCT n.n_name AS nation_name
     FROM nation n
     JOIN supplier s ON n.n_nationkey = s.s_nationkey) s ON r.nation_name = s.nation_name
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.sales_rank;
