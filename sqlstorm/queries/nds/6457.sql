
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        SUM(ss.ss_quantity) AS total_quantity_sold
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
        AND d.d_moy IN (1, 2, 12)
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        s.total_net_profit,
        s.total_sales,
        s.avg_sales_price,
        s.total_quantity_sold,
        ROW_NUMBER() OVER (ORDER BY s.total_net_profit DESC) AS ranking
    FROM 
        SalesSummary s
    JOIN 
        customer c ON s.c_customer_id = c.c_customer_id
)
SELECT 
    tc.c_customer_id,
    tc.total_net_profit,
    tc.total_sales,
    tc.avg_sales_price,
    tc.total_quantity_sold
FROM 
    TopCustomers tc
WHERE 
    tc.ranking <= 10
ORDER BY 
    tc.total_net_profit DESC;
