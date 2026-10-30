
WITH SalesData AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_linenumber) AS line_item_count,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, c.c_name, c.c_nationkey
),
TopCustomers AS (
    SELECT 
        c.c_nationkey,
        c.c_name,
        sd.total_sales,
        sd.line_item_count
    FROM 
        SalesData sd
    JOIN 
        customer c ON sd.o_orderkey = c.c_custkey
    WHERE 
        sd.sales_rank <= 5
),
RegionSales AS (
    SELECT 
        r.r_name,
        COALESCE(SUM(tc.total_sales), 0) AS region_sales
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        TopCustomers tc ON n.n_nationkey = tc.c_nationkey
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name,
    r.region_sales,
    CASE 
        WHEN r.region_sales = 0 THEN 'No sales'
        ELSE CONCAT('Total sales: ', r.region_sales)
    END AS sales_description,
    RANK() OVER (ORDER BY r.region_sales DESC) AS region_rank
FROM 
    RegionSales r
ORDER BY 
    r.region_sales DESC
LIMIT 10;
