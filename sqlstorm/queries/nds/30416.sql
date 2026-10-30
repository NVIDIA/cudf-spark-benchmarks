
WITH  sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        CAST(d.d_date AS DATE) AS sales_date,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sold_date_sk) AS row_num
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
),
customer_summary AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_paid) AS total_spent,
        COUNT(DISTINCT sd.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        sales_data sd ON c.c_customer_sk = sd.ws_item_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT 
    s.c_customer_sk,
    s.c_first_name,
    s.c_last_name,
    s.total_quantity,
    s.total_spent,
    s.order_count,
    CASE 
        WHEN s.order_count > 5 THEN 'Frequent'
        WHEN s.total_spent > 1000 THEN 'High Spender'
        ELSE 'Regular'
    END AS customer_category,
    COALESCE(num_return.return_count, 0) AS return_count
FROM
    customer_summary s
LEFT JOIN (
    SELECT 
        cr_returning_customer_sk,
        COUNT(cr_returning_customer_sk) AS return_count
    FROM 
        catalog_returns cr
    GROUP BY 
        cr_returning_customer_sk
) num_return ON s.c_customer_sk = num_return.cr_returning_customer_sk
WHERE 
    s.total_quantity > 10
ORDER BY 
    s.total_spent DESC 
LIMIT 100;
