
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales_amount,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
),
BestSellingItems AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity_sold,
        r.total_sales_amount,
        i.i_product_name,
        i.i_category
    FROM RankedSales r
    JOIN item i ON r.ws_item_sk = i.i_item_sk
    WHERE r.sales_rank <= 10
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT s.ss_ticket_number) AS total_purchases,
        SUM(s.ss_net_paid) AS total_spent
    FROM customer c
    JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
    WHERE s.ss_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY c.c_customer_sk
)
SELECT 
    b.i_product_name,
    b.i_category,
    SUM(cp.total_purchases) AS customer_count,
    SUM(cp.total_spent) AS total_revenue
FROM BestSellingItems b
JOIN CustomerPurchases cp ON b.ws_item_sk IN (SELECT ss_item_sk FROM store_sales WHERE ss_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023))
GROUP BY b.i_product_name, b.i_category
ORDER BY total_revenue DESC;
