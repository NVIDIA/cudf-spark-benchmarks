
WITH CustomerAnalytics AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_quantity) AS total_purchases,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
WarehousePerformance AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_quantity) AS total_sales,
        AVG(ws.ws_net_profit) AS average_profit_per_sale,
        COUNT(DISTINCT ws.ws_order_number) AS unique_orders
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
SalesByState AS (
    SELECT 
        ca.ca_state,
        SUM(ws.ws_net_profit) AS total_profit_by_state,
        COUNT(ws.ws_order_number) AS order_count_by_state
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_state
)
SELECT 
    ca.c_customer_id,
    ca.cd_gender,
    ca.cd_marital_status,
    ca.cd_education_status,
    wp.w_warehouse_id,
    wp.total_sales,
    wp.average_profit_per_sale,
    sb.ca_state,
    sb.total_profit_by_state,
    sb.order_count_by_state
FROM 
    CustomerAnalytics ca
JOIN 
    WarehousePerformance wp ON ca.total_purchases > 0
JOIN 
    SalesByState sb ON ca.total_profit > 0
WHERE 
    ca.total_profit > 1000
ORDER BY 
    ca.total_purchases DESC, wp.total_sales DESC;
