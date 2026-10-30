
WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        c.c_customer_sk AS ws_bill_customer_sk
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_gender = 'F' 
        AND i.i_brand = 'BrandX' 
        AND ws.ws_sold_date_sk BETWEEN 2400 AND 2405
    GROUP BY 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        c.c_customer_sk
),
top_sales AS (
    SELECT 
        ca.ca_address_id,
        SUM(ss.total_sales) AS total_sales_per_address
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        sales_summary ss ON ss.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        ca.ca_address_id
    ORDER BY 
        total_sales_per_address DESC
    LIMIT 10
)
SELECT 
    t.total_sales_per_address, 
    ca.ca_city, 
    ca.ca_state 
FROM 
    top_sales t
JOIN 
    customer_address ca ON t.ca_address_id = ca.ca_address_id;
