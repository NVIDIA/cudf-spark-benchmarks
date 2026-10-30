
WITH Sales AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        SUM(l.l_extendedprice * (1 - l.l_discount)) * 0.06 AS tax_amount
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1997-12-31'
    GROUP BY 
        c.c_custkey
),
TopCustomers AS (
    SELECT 
        sp.s_name,
        sp.s_nationkey,
        SUM(s.total_sales) AS total_customer_sales,
        SUM(s.tax_amount) AS total_tax_collected
    FROM 
        Sales s
    JOIN 
        supplier sp ON s.c_custkey = sp.s_suppkey
    GROUP BY 
        sp.s_name, sp.s_nationkey
    ORDER BY 
        total_customer_sales DESC
    LIMIT 10
)
SELECT 
    n.n_name AS nation,
    COUNT(tc.s_name) AS number_of_customers,
    AVG(tc.total_customer_sales) AS average_sales_per_customer,
    MAX(tc.total_tax_collected) AS max_tax_collected
FROM 
    TopCustomers tc
JOIN 
    nation n ON tc.s_nationkey = n.n_nationkey
GROUP BY 
    n.n_name
ORDER BY 
    average_sales_per_customer DESC;
