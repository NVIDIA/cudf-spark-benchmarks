
WITH ranked_sales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity_sold
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
customer_sales AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cs.ws_item_sk,
        cs.ws_sales_price,
        cs.total_quantity_sold
    FROM 
        customer c
    JOIN 
        ranked_sales cs ON c.c_customer_sk = cs.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender IS NOT NULL 
        AND cd.cd_marital_status = 'M'
),
sales_summary AS (
    SELECT 
        cs.c_customer_id,
        SUM(cs.total_quantity_sold) AS total_quantity,
        AVG(cs.ws_sales_price) AS average_price,
        COUNT(DISTINCT cs.ws_item_sk) AS unique_items_sold
    FROM 
        customer_sales cs
    GROUP BY 
        cs.c_customer_id
)
SELECT 
    ss.c_customer_id,
    ss.total_quantity,
    ss.average_price,
    ss.unique_items_sold,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM 
    sales_summary ss
JOIN 
    customer c ON c.c_customer_id = ss.c_customer_id
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    ss.total_quantity > (
        SELECT AVG(total_quantity) FROM sales_summary
    )
ORDER BY 
    ss.average_price DESC
LIMIT 100;
