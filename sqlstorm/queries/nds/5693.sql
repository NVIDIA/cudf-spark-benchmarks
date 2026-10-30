WITH sales_data AS (
    SELECT 
        ws_item_sk AS item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2459232 AND 2459262 
    GROUP BY 
        ws_item_sk
),
customer_data AS (
    SELECT 
        c.c_customer_sk AS customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(sd.total_profit) AS total_profit_carried
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        sales_data sd ON c.c_customer_sk = sd.item_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_sk AS warehouse_sk,
        SUM(sd.total_quantity) AS total_quantity_sold,
        SUM(sd.total_profit) AS total_profit_generated
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    JOIN 
        sales_data sd ON ws.ws_item_sk = sd.item_sk
    GROUP BY 
        w.w_warehouse_sk
)
SELECT 
    cd.customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    ws.warehouse_sk,
    ws.total_quantity_sold,
    ws.total_profit_generated,
    cd.total_profit_carried
FROM 
    customer_data cd
JOIN 
    warehouse_summary ws ON cd.total_profit_carried > 1000 
ORDER BY 
    cd.total_profit_carried DESC, ws.total_profit_generated DESC;