
WITH CustomerOrders AS (
    SELECT 
        c.c_name AS customer_name, 
        COUNT(o.o_orderkey) AS total_orders, 
        SUM(o.o_totalprice) AS total_spent,
        c.c_mktsegment AS market_segment,
        SUBSTRING(c.c_comment, 1, 20) AS comment_excerpt
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name, c.c_mktsegment, c.c_comment
),
TopCustomers AS (
    SELECT 
        customer_name, 
        total_orders, 
        total_spent, 
        market_segment, 
        comment_excerpt,
        RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
    FROM 
        CustomerOrders
)
SELECT 
    tc.customer_name, 
    tc.total_orders, 
    tc.total_spent, 
    tc.market_segment, 
    tc.comment_excerpt,
    CONCAT('Customer ', tc.customer_name, ' has spent a total of ', CAST(tc.total_spent AS DECIMAL(10, 2)), ' in ', tc.total_orders, ' orders. Comment: ', tc.comment_excerpt) AS detailed_info
FROM 
    TopCustomers tc
WHERE 
    tc.spending_rank <= 10
ORDER BY 
    tc.spending_rank;
