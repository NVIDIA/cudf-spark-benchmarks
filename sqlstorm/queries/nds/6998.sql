
WITH SalesStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS average_profit,
        COUNT(DISTINCT ws.ws_web_page_sk) AS unique_web_pages
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
        AND d.d_month_seq IN (6, 7, 8)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY 
        total_sales DESC
    LIMIT 100
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate, 
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
    JOIN 
        SalesStats ss ON ss.c_customer_sk = cd.cd_demo_sk
), 
ShippingModes AS (
    SELECT 
        sm.sm_ship_mode_id,
        sm.sm_type,
        SUM(ws.ws_ext_ship_cost) AS total_ship_cost
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20230601 AND 20230831
    GROUP BY 
        sm.sm_ship_mode_id, sm.sm_type
)

SELECT 
    ss.c_first_name,
    ss.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    ss.total_sales,
    ss.order_count,
    ss.average_profit,
    cd.cd_purchase_estimate,
    sm.sm_type,
    sm.total_ship_cost
FROM 
    SalesStats ss
JOIN 
    CustomerDemographics cd ON ss.c_customer_sk = cd.cd_demo_sk
JOIN 
    ShippingModes sm ON ss.c_customer_sk IN (SELECT DISTINCT ws.ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_sold_date_sk BETWEEN 20230601 AND 20230831)
ORDER BY 
    ss.total_sales DESC;
