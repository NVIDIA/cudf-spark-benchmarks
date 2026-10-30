WITH CustomerSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
RankedCustomerSales AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.total_spent,
        cs.total_orders,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS sales_rank
    FROM 
        CustomerSales cs
)

SELECT 
    rc.c_name,
    rc.total_spent,
    rc.total_orders,
    CASE 
        WHEN rc.total_orders > 10 THEN 'High'
        WHEN rc.total_orders BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS order_category,
    (SELECT COUNT(*) FROM customer c WHERE c.c_acctbal IS NULL) AS null_account_balance_count
FROM 
    RankedCustomerSales rc
WHERE 
    rc.sales_rank <= 10
ORDER BY 
    rc.total_spent DESC;