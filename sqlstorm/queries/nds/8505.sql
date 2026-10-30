
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales_amount,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                           AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_sold_date_sk
),

DemographicData AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer_demographics
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_gender, cd_marital_status
),

WarehouseData AS (
    SELECT 
        w_warehouse_id,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory
    JOIN 
        warehouse ON inv_warehouse_sk = w_warehouse_sk
    GROUP BY 
        w_warehouse_id
)

SELECT 
    S.ws_sold_date_sk,
    S.total_sales_amount,
    S.total_orders,
    S.total_quantity,
    S.avg_net_profit,
    D.cd_gender,
    D.cd_marital_status,
    D.customer_count,
    D.total_purchase_estimate,
    W.w_warehouse_id,
    W.total_inventory
FROM 
    SalesData S
JOIN 
    DemographicData D ON 1=1
JOIN 
    WarehouseData W ON 1=1
ORDER BY 
    S.ws_sold_date_sk, D.cd_gender, D.cd_marital_status;
