
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        MIN(i.i_current_price) AS min_price,
        MAX(i.i_current_price) AS max_price,
        AVG(i.i_current_price) AS avg_price,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk AND ws.ws_order_number = cs.cs_order_number
    GROUP BY 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS customer_count,
        SUM(sd.total_net_profit) AS total_profit_by_gender_marital
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        web_sales ws ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        SalesData sd ON sd.ws_item_sk = ws.ws_item_sk
    GROUP BY 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count,
    cd.total_profit_by_gender_marital,
    COUNT(DISTINCT ca.ca_country) AS unique_countries,
    COUNT(DISTINCT w.w_warehouse_id) AS warehouses_involved
FROM 
    CustomerDemographics cd
JOIN 
    customer_address ca ON cd.cd_demo_sk = ca.ca_address_sk
JOIN 
    warehouse w ON w.w_warehouse_sk = ca.ca_address_sk
GROUP BY 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.customer_count, 
    cd.total_profit_by_gender_marital
ORDER BY 
    total_profit_by_gender_marital DESC;
