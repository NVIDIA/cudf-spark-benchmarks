
WITH SalesSummary AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        i.i_item_id, i.i_item_desc
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(ss.ss_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        SUM(ws.ws_ext_sales_price) AS total_web_sales
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        w.w_warehouse_name
)
SELECT 
    ss.i_item_desc AS item_description,
    ss.total_quantity_sold,
    ss.total_sales_amount,
    ss.total_orders,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count, 
    cd.total_profit,
    ws.w_warehouse_name,
    ws.total_web_orders,
    ws.total_web_sales
FROM 
    SalesSummary ss
JOIN 
    CustomerDemographics cd ON ( ss.total_quantity_sold > 100 AND cd.total_profit > 5000 ) 
JOIN 
    WarehouseSales ws ON ws.total_web_orders > 20
ORDER BY 
    ss.total_sales_amount DESC, cd.customer_count DESC;
