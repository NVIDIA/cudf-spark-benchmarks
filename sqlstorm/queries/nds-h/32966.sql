WITH  nation_sales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        n.n_name
), total_sales AS (
    SELECT 
        SUM(total_sales) AS overall_sales
    FROM 
        nation_sales
), filtered_sales AS (
    SELECT 
        nation_name,
        total_sales
    FROM 
        nation_sales
    WHERE 
        sales_rank <= 5
)
SELECT 
    fs.nation_name, 
    fs.total_sales, 
    ts.overall_sales,
    CASE 
        WHEN fs.total_sales IS NULL THEN 'No Sales'
        ELSE CONCAT('Sales: ', fs.total_sales)
    END AS formatted_sales
FROM 
    filtered_sales fs
CROSS JOIN 
    total_sales ts
WHERE 
    fs.total_sales > (SELECT AVG(total_sales) FROM nation_sales)
ORDER BY 
    fs.total_sales DESC;

