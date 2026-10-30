WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_addr_sk,
        rd.total_sales,
        COALESCE((
            SELECT COUNT(DISTINCT wr_order_number) 
            FROM web_returns wr 
            WHERE wr_returning_customer_sk = c.c_customer_sk
        ), 0) AS return_count
    FROM 
        customer c
    JOIN 
        ranked_sales rd ON c.c_customer_sk = rd.ws_bill_customer_sk
    WHERE 
        rd.sales_rank <= 10  
),
address_info AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer_address ca
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    ai.ca_city,
    ai.ca_state,
    ai.ca_country,
    tc.total_sales,
    ROUND(tc.total_sales * 0.1, 2) AS estimated_tax,
    CASE 
        WHEN tc.return_count > 0 THEN 'Yes' 
        ELSE 'No' 
    END AS has_returns
FROM 
    top_customers tc
LEFT JOIN 
    address_info ai ON tc.c_current_addr_sk = ai.ca_address_sk
ORDER BY 
    tc.total_sales DESC;