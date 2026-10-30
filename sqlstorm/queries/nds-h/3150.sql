WITH RegionalSales AS (
    SELECT 
        N.n_name AS nation_name,
        SUM(L.l_extendedprice * (1 - L.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY N.n_nationkey ORDER BY SUM(L.l_extendedprice * (1 - L.l_discount)) DESC) AS sales_rank
    FROM 
        lineitem L
    JOIN 
        orders O ON L.l_orderkey = O.o_orderkey
    JOIN 
        customer C ON O.o_custkey = C.c_custkey
    JOIN 
        nation N ON C.c_nationkey = N.n_nationkey
    GROUP BY 
        N.n_nationkey, N.n_name
), MaxSales AS (
    SELECT 
        MAX(total_sales) AS max_sales
    FROM 
        RegionalSales
)

SELECT 
    RS.nation_name,
    RS.total_sales,
    CASE 
        WHEN RS.total_sales IS NULL THEN 'No Sales'
        WHEN RS.total_sales > MS.max_sales * 0.5 THEN 'High Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    RegionalSales RS
LEFT JOIN 
    MaxSales MS ON 1=1
WHERE 
    RS.sales_rank <= 5
ORDER BY 
    RS.total_sales DESC;


