
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales AS ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk 
                                FROM date_dim AS d 
                                WHERE d.d_year = 2022)
    GROUP BY 
        ws.ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY d.d_date DESC) AS rn
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        ca.ca_city IS NOT NULL
)
SELECT 
    ci.ca_city,
    ci.ca_state,
    SUM(ss.total_quantity_sold) AS total_quantity,
    SUM(ss.total_sales) AS total_sales,
    AVG(ss.avg_net_paid) AS average_net_paid,
    COUNT(DISTINCT ci.c_customer_sk) AS unique_customers
FROM 
    sales_summary AS ss
JOIN 
    customer_info AS ci ON ss.ws_item_sk = ci.c_customer_sk
WHERE 
    ci.rn = 1
GROUP BY 
    ci.ca_city, ci.ca_state
HAVING 
    SUM(ss.total_sales) > 10000
ORDER BY 
    total_sales DESC;
