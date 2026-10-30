
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_ship_mode_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_ship_mode_sk
),
GenderSales AS (
    SELECT 
        ci.cd_gender,
        si.ws_ship_mode_sk,
        SUM(si.total_sales) AS gender_sales,
        SUM(si.order_count) AS order_count
    FROM 
        CustomerInfo ci
    JOIN 
        SalesInfo si ON ci.c_customer_sk = si.ws_ship_mode_sk
    GROUP BY 
        ci.cd_gender, si.ws_ship_mode_sk
),
RankedSales AS (
    SELECT
        cd.cd_gender,
        sm.sm_ship_mode_id,
        gs.gender_sales,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY gs.gender_sales DESC) AS sales_rank
    FROM 
        GenderSales gs
    JOIN 
        ship_mode sm ON gs.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN 
        customer_demographics cd ON cd.cd_gender = gs.cd_gender
)
SELECT 
    r.cd_gender,
    r.sm_ship_mode_id,
    r.gender_sales,
    r.sales_rank
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 5
ORDER BY 
    r.cd_gender, r.gender_sales DESC;
