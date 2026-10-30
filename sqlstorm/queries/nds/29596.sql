
WITH CTE_Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
CTE_Income_Band AS (
    SELECT 
        c.c_customer_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
),
CTE_Sales AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_sold,
        SUM(cs.cs_sales_price) AS total_sales
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk
),
CTE_Warehouse_Sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_web_sales,
        SUM(ws.ws_sales_price) AS total_web_sales_value
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
)
SELECT 
    C.full_name,
    C.ca_city,
    C.ca_state,
    C.ca_zip,
    C.ca_country,
    I.ib_lower_bound,
    I.ib_upper_bound,
    COALESCE(S.total_sold, 0) AS total_catalog_sold,
    COALESCE(W.total_web_sales, 0) AS total_web_sold,
    COALESCE(S.total_sales, 0) AS total_catalog_sales_value,
    COALESCE(W.total_web_sales_value, 0) AS total_web_sales_value
FROM CTE_Customer_Info C
JOIN CTE_Income_Band I ON C.c_customer_sk = I.c_customer_sk
LEFT JOIN CTE_Sales S ON C.c_customer_sk = S.cs_item_sk
LEFT JOIN CTE_Warehouse_Sales W ON C.c_customer_sk = W.ws_item_sk
WHERE C.cd_gender = 'F' AND C.cd_marital_status = 'M'
ORDER BY C.full_name;
