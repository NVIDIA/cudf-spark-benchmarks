
WITH  SalesData AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank,
        c.c_nationkey,
        n.n_name
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        c.c_custkey, n.n_name, c.c_nationkey
),
TopCustomers AS (
    SELECT 
        c_nationkey, 
        total_sales, 
        sales_rank
    FROM 
        SalesData
    WHERE 
        sales_rank <= 10
)
SELECT 
    n.n_name, 
    SUM(tc.total_sales) AS national_sales
FROM 
    TopCustomers tc
JOIN 
    nation n ON tc.c_nationkey = n.n_nationkey
GROUP BY 
    n.n_name
ORDER BY 
    national_sales DESC;
