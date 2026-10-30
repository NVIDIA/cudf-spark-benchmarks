
WITH CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        AVG(cd_dep_count) AS avg_dep_count
    FROM 
        customer_demographics
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        ws_ship_mode_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451545 AND 2451545 + 30  
    GROUP BY 
        ws_ship_mode_sk
),
WarehouseStats AS (
    SELECT 
        w_warehouse_sk,
        COUNT(DISTINCT ws_order_number) AS orders_fulfilled,
        SUM(ws_net_paid) AS total_sales_fulfilled
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w_warehouse_sk
),
FinalReport AS (
    SELECT 
        cs.cd_gender,
        cs.total_customers,
        cs.avg_purchase_estimate,
        ss.total_sales,
        ss.order_count,
        ws.orders_fulfilled,
        ws.total_sales_fulfilled
    FROM 
        CustomerStats cs
    LEFT JOIN 
        SalesSummary ss ON ss.ws_ship_mode_sk IN (1, 2, 3)  
    LEFT JOIN 
        WarehouseStats ws ON ws.w_warehouse_sk = 1  
)
SELECT 
    fr.cd_gender,
    fr.total_customers,
    fr.avg_purchase_estimate,
    fr.total_sales,
    fr.order_count,
    fr.orders_fulfilled,
    fr.total_sales_fulfilled
FROM 
    FinalReport fr
ORDER BY 
    fr.total_sales DESC;
