WITH  sales_data AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales, 
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2459340 AND 2459675 
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_sales_price) > 0
),
customer_info AS (
    SELECT 
        c_customer_sk, 
        cd_gender,
        CASE 
            WHEN cd_marital_status = 'M' THEN 'Married'
            WHEN cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        cd_purchase_estimate
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        SUM(s.ws_net_profit) AS total_profit
    FROM 
        customer_info c
    JOIN 
        web_sales s ON c.c_customer_sk = s.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        SUM(s.ws_net_profit) > 1000
)
SELECT 
    a.ca_city, 
    SUM(b.total_sales) AS sales_by_city,
    COUNT(DISTINCT c.c_customer_sk) AS high_value_customer_count,
    AVG(d.cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    customer_address a
LEFT JOIN 
    sales_data b ON a.ca_address_sk = b.ws_item_sk
LEFT JOIN 
    high_value_customers c ON b.ws_item_sk = c.c_customer_sk
JOIN 
    customer_info d ON c.c_customer_sk = d.c_customer_sk
WHERE 
    a.ca_state = 'CA'
GROUP BY 
    a.ca_city
ORDER BY 
    sales_by_city DESC
LIMIT 10;