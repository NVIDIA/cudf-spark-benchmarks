
WITH  sales_cte AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL AND
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d) 
    GROUP BY 
        ws.ws_item_sk
),
top_sales AS (
    SELECT 
        ws_item_sk AS item_sk,
        total_quantity,
        total_sales_price
    FROM 
        sales_cte
    WHERE 
        rank <= 10
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        cd.cd_dep_count,
        ca.ca_city
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    COALESCE(ts.total_quantity, 0) AS total_quantity,
    COALESCE(ts.total_sales_price, 0) AS total_sales_price,
    CASE 
        WHEN ci.cd_marital_status = 'M' THEN 'Married'
        ELSE 'Single'
    END AS marital_status,
    CASE 
        WHEN ci.cd_gender = 'M' THEN 'Male'
        ELSE 'Female'
    END AS gender,
    ROUND((COALESCE(ts.total_sales_price, 0) / NULLIF(ci.cd_purchase_estimate, 0)) * 100, 2) AS sales_percentage
FROM 
    customer_info ci
LEFT JOIN 
    top_sales ts ON ci.c_customer_sk = ts.item_sk
ORDER BY 
    total_sales_price DESC,
    ci.c_last_name ASC;
