
WITH customer_returns AS (
    SELECT 
        cr_returning_customer_sk,
        COUNT(cr_order_number) AS total_returns,
        SUM(cr_return_amount) AS total_return_amt,
        SUM(cr_return_quantity) AS total_return_qty
    FROM 
        catalog_returns 
    GROUP BY 
        cr_returning_customer_sk
),
web_sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        SUM(ws_quantity) AS total_items_sold
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) 
                           AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
sales_analysis AS (
    SELECT 
        wss.ws_bill_customer_sk,
        COALESCE(crc.total_returns, 0) AS total_customer_returns,
        wss.total_orders,
        wss.total_sales,
        wss.total_items_sold,
        CASE 
            WHEN wss.total_sales > 1000 THEN 'High Value'
            WHEN wss.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value' 
            ELSE 'Low Value'
        END AS customer_value_segment
    FROM 
        web_sales_summary wss
    LEFT JOIN 
        customer_returns crc ON wss.ws_bill_customer_sk = crc.cr_returning_customer_sk
),
combined_analysis AS (
    SELECT 
        sa.ws_bill_customer_sk,
        sa.total_customer_returns,
        sa.total_orders,
        sa.total_sales,
        sa.customer_value_segment,
        RANK() OVER (PARTITION BY sa.customer_value_segment ORDER BY sa.total_sales DESC) AS sales_rank
    FROM 
        sales_analysis sa
    WHERE 
        sa.total_orders > 5
)

SELECT 
    ca.ca_city,
    ca.ca_state,
    sa.customer_value_segment,
    AVG(sa.total_sales) AS avg_sales,
    SUM(sa.total_customer_returns) AS total_returns,
    COUNT(DISTINCT sa.ws_bill_customer_sk) AS customer_count
FROM 
    combined_analysis sa
JOIN 
    customer c ON sa.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY 
    ca.ca_city, ca.ca_state, sa.customer_value_segment
HAVING 
    COUNT(DISTINCT sa.ws_bill_customer_sk) > 10
ORDER BY 
    avg_sales DESC, total_returns DESC;
