
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
),
SalesData AS (
    SELECT 
        ws.ws_web_site_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT DISTINCT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ws.ws_web_site_sk
)
SELECT 
    rc.c_customer_id,
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_purchase_estimate,
    sd.total_sales,
    sd.total_orders
FROM 
    RankedCustomers rc
JOIN 
    SalesData sd ON rc.c_customer_id = CAST(sd.ws_web_site_sk AS CHAR(16))
WHERE 
    rc.rank <= 10;
