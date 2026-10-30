WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2000)
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
AggregatedData AS (
    SELECT 
        ci.c_customer_id,
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        COALESCE(SUM(sd.total_quantity), 0) AS total_quantity,
        COALESCE(SUM(sd.total_sales), 0) AS total_sales
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesData sd ON ci.c_customer_id = CONCAT('cust_', sd.ws_item_sk)  
    GROUP BY 
        ci.c_customer_id, ci.full_name, ci.ca_city, ci.ca_state, ci.ca_country
)
SELECT 
    *,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    AggregatedData
WHERE 
    ca_city IS NOT NULL AND ca_state IS NOT NULL
ORDER BY 
    total_sales DESC, total_quantity DESC;