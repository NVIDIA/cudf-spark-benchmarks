
WITH  sales_summary AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
top_sales AS (
    SELECT 
        ws_item_sk, 
        total_quantity, 
        total_net_profit
    FROM 
        sales_summary
    WHERE 
        rank <= 10
),
customer_data AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        COALESCE(hd_demo_sk, -1) AS hd_demo_sk,
        SUM(COALESCE(cd_purchase_estimate, 0)) AS total_purchase_estimation
    FROM 
        customer
    LEFT JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    LEFT JOIN 
        household_demographics ON hd_demo_sk = c_current_hdemo_sk
    GROUP BY 
        c_customer_sk, cd_gender, cd_marital_status, hd_demo_sk
)
SELECT 
    cu.c_customer_sk,
    cu.cd_gender,
    cu.cd_marital_status,
    COALESCE(SUM(ts.total_quantity), 0) AS total_items_sold,
    COALESCE(SUM(ts.total_net_profit), 0) AS total_net_profit,
    AVG(cu.total_purchase_estimation) AS avg_purchase_estimation
FROM 
    customer_data AS cu
LEFT JOIN 
    top_sales AS ts ON cu.c_customer_sk = ts.ws_item_sk
GROUP BY 
    cu.c_customer_sk, cu.cd_gender, cu.cd_marital_status
HAVING 
    COALESCE(SUM(ts.total_quantity), 0) > 0 OR AVG(cu.total_purchase_estimation) > 1000
ORDER BY 
    total_net_profit DESC, total_items_sold DESC;
