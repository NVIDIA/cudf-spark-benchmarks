
WITH SalesData AS (
    SELECT 
        w.w_warehouse_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
        d.d_year
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        w.w_warehouse_name, d.d_year
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(sd.total_net_profit) AS gender_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        SalesData sd ON sd.unique_customers = c.c_customer_sk
    GROUP BY 
        cd.cd_gender
),
WarehousePerformance AS (
    SELECT 
        w.w_warehouse_name,
        SUM(sd.total_net_profit) AS warehouse_profit,
        AVG(sd.avg_sales_price) AS avg_sales_by_warehouse
    FROM 
        SalesData sd
    JOIN 
        warehouse w ON sd.w_warehouse_name = w.w_warehouse_name
    GROUP BY 
        w.w_warehouse_name
)
SELECT 
    cd.cd_gender, 
    cd.customer_count, 
    cd.gender_profit, 
    wp.warehouse_profit, 
    wp.avg_sales_by_warehouse
FROM 
    CustomerDemographics cd
JOIN 
    WarehousePerformance wp ON cd.gender_profit = wp.warehouse_profit
ORDER BY 
    cd.cd_gender, wp.warehouse_profit DESC;
