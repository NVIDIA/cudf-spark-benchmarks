
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases,
        COUNT(DISTINCT ss.ss_item_sk) AS unique_items_purchased
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 
        (SELECT d_date_sk FROM date_dim WHERE d_date = DATE '2023-01-01') AND 
        (SELECT d_date_sk FROM date_dim WHERE d_date = DATE '2023-12-31')
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_spent,
        cs.total_purchases,
        cs.unique_items_purchased,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS sales_rank
    FROM 
        CustomerSales cs
),
AverageStats AS (
    SELECT 
        AVG(total_spent) AS avg_spent,
        AVG(total_purchases) AS avg_purchases,
        AVG(unique_items_purchased) AS avg_unique_items
    FROM 
        CustomerSales
)
SELECT 
    tc.c_customer_id,
    tc.total_spent,
    tc.total_purchases,
    tc.unique_items_purchased,
    avg.avg_spent,
    avg.avg_purchases,
    avg.avg_unique_items
FROM 
    TopCustomers tc, AverageStats avg
WHERE 
    tc.sales_rank <= 10;
