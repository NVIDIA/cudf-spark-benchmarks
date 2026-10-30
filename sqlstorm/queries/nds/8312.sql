
WITH RankedSales AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_sales_price DESC) AS rank_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TotalSales AS (
    SELECT 
        rs.ws_order_number,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales_value
    FROM 
        RankedSales rs
    WHERE 
        rs.rank_sales <= 5
    GROUP BY 
        rs.ws_order_number
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ts.total_sales_value
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        TotalSales ts ON c.c_customer_sk = ts.ws_order_number
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ci.total_sales_value,
    ca.ca_city,
    ca.ca_state
FROM 
    CustomerInfo ci
JOIN 
    customer_address ca ON ci.c_customer_sk = ca.ca_address_sk
WHERE 
    ci.total_sales_value > (SELECT AVG(total_sales_value) FROM TotalSales)
ORDER BY 
    ci.total_sales_value DESC
LIMIT 10;
