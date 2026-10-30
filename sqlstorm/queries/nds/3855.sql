
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        address.ca_city,
        address.ca_state,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address address ON c.c_current_addr_sk = address.ca_address_sk
),
popular_items AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 100
    GROUP BY 
        ws.ws_item_sk
),
top_customers AS (
    SELECT 
        c_info.c_customer_sk,
        c_info.c_first_name,
        c_info.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_spending
    FROM 
        customer_info c_info
    JOIN 
        web_sales ws ON c_info.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c_info.c_customer_sk, c_info.c_first_name, c_info.c_last_name
    HAVING 
        SUM(ws.ws_ext_sales_price) > 500
    ORDER BY 
        total_spending DESC
    LIMIT 10
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    pi.total_sales,
    CASE 
        WHEN pi.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status
FROM 
    top_customers tc
LEFT JOIN 
    popular_items pi ON tc.c_customer_sk = pi.ws_item_sk
WHERE 
    EXISTS (
        SELECT 1 
        FROM web_sales ws
        WHERE ws.ws_bill_customer_sk = tc.c_customer_sk 
        AND ws.ws_sold_date_sk BETWEEN 20240101 AND 20241231
    )
ORDER BY 
    tc.c_customer_sk;
