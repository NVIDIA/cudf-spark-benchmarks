
WITH CustomerFullName AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
WarehouseAddress AS (
    SELECT 
        w_warehouse_sk,
        CONCAT(w_street_number, ' ', w_street_name, ' ', w_street_type, ', ', w_city, ', ', w_state, ' ', w_zip) AS full_address
    FROM 
        warehouse
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cfn.full_name,
    cfn.cd_gender,
    cfn.cd_marital_status,
    cfn.cd_education_status,
    wa.full_address,
    ss.total_net_profit,
    ss.total_orders
FROM 
    CustomerFullName cfn
LEFT JOIN 
    WarehouseAddress wa ON wa.w_warehouse_sk = (SELECT MIN(w_warehouse_sk) FROM warehouse)
LEFT JOIN 
    SalesSummary ss ON cfn.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    cfn.cd_gender = 'F' 
    AND cfn.cd_marital_status = 'S'
ORDER BY 
    ss.total_net_profit DESC
LIMIT 10;
