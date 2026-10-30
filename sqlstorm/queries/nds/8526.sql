
WITH SalesData AS (
    SELECT 
        customer.c_customer_id,
        customer.c_first_name,
        customer.c_last_name,
        SUM(store_sales.ss_ext_sales_price) AS total_sales,
        COUNT(store_sales.ss_ticket_number) AS transaction_count,
        AVG(store_sales.ss_net_profit) AS avg_net_profit,
        MAX(store_sales.ss_sold_date_sk) AS last_purchase_date
    FROM customer
    JOIN store_sales ON customer.c_customer_sk = store_sales.ss_customer_sk
    JOIN date_dim ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
    WHERE date_dim.d_year = 2023
    GROUP BY 
        customer.c_customer_id,
        customer.c_first_name,
        customer.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_id AS customer_id,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        sd.total_sales,
        sd.transaction_count,
        sd.avg_net_profit,
        sd.last_purchase_date,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM SalesData sd
    JOIN customer c ON sd.c_customer_id = c.c_customer_id
)
SELECT 
    tc.sales_rank,
    tc.customer_id,
    tc.first_name,
    tc.last_name,
    tc.total_sales,
    tc.transaction_count,
    tc.avg_net_profit,
    tc.last_purchase_date
FROM TopCustomers tc
WHERE tc.sales_rank <= 10
ORDER BY tc.sales_rank;
