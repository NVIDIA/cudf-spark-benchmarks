
WITH SalesSummary AS (
    SELECT 
        ws_ship_mode_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_list_price) AS avg_list_price
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_ship_mode_sk
),
CustomerInfo AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE 
        c.c_birth_year < 1990
    GROUP BY 
        cd_gender, cd_marital_status
),
TopItems AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_item_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    ORDER BY 
        total_item_sales DESC
    LIMIT 10
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    cs.customer_count,
    ss.total_quantity,
    ss.total_sales,
    ss.avg_list_price,
    ti.total_item_sales
FROM 
    customer_address ca
JOIN 
    SalesSummary ss ON ss.ws_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_mode)
JOIN 
    CustomerInfo cs ON cs.customer_count > 100
JOIN 
    TopItems ti ON ti.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_ship_customer_sk IS NOT NULL)
WHERE 
    ca.ca_state IN ('CA', 'NY')
ORDER BY 
    cs.customer_count DESC, ss.total_sales DESC;
