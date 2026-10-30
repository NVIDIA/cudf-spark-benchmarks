
WITH SalesData AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(li.l_quantity) AS avg_quantity,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),
TopCustomers AS (
    SELECT 
        c.c_nationkey,
        sd.c_custkey,
        sd.c_name,
        sd.total_sales,
        sd.order_count,
        sd.avg_quantity,
        sd.sales_rank
    FROM 
        SalesData sd
    JOIN 
        customer c ON sd.c_custkey = c.c_custkey
    WHERE 
        sd.sales_rank <= 5
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    tc.c_name,
    tc.total_sales,
    tc.order_count,
    COALESCE(ROUND(tc.avg_quantity, 2), 0) AS avg_qty,
    CASE 
        WHEN tc.total_sales > 10000 THEN 'High Value'
        WHEN tc.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    TopCustomers tc
LEFT JOIN 
    nation n ON tc.c_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
ORDER BY 
    r.r_name, n.n_name, tc.total_sales DESC;
