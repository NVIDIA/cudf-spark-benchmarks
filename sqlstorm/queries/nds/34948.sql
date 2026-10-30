
WITH  sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' AND
        cd.cd_gender = 'F'
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
top_sales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_sales
    FROM 
        sales_data sd
    WHERE 
        sd.sales_rank <= 10
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    SUM(cd.total_net_profit) AS total_net_profit,
    COALESCE(SUM(ts.total_sales), 0) AS top_sales_total
FROM 
    customer_address ca
JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    customer_data cd ON c.c_customer_sk = cd.c_customer_sk
LEFT JOIN 
    top_sales ts ON ts.ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_category = 'Electronics')
WHERE 
    ca.ca_state IN ('CA', 'NY')
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    total_customers DESC, total_net_profit DESC
LIMIT 50;
