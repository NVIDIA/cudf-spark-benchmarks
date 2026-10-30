
WITH sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    INNER JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0
    GROUP BY 
        ws.ws_order_number, 
        ws.ws_item_sk
), 
customer_data AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
sales_ranked AS (
    SELECT 
        sd.ws_order_number,
        sd.ws_item_sk,
        sd.total_sales,
        sd.total_profit,
        RANK() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        sales_data sd
)

SELECT 
    cd.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(SUM(sr.total_sales), 0) AS total_web_sales,
    COALESCE(SUM(sr.total_profit), 0) AS total_web_profit,
    COUNT(DISTINCT sr.ws_order_number) AS unique_orders,
    MAX(sr.sales_rank) AS highest_sales_rank
FROM 
    customer_data cd
LEFT JOIN 
    sales_ranked sr ON cd.c_customer_sk = sr.ws_item_sk
WHERE 
    cd.cd_purchase_estimate IS NOT NULL
AND 
    (cd.cd_gender = 'M' OR cd.cd_marital_status = 'S')
GROUP BY 
    cd.c_customer_sk, 
    cd.cd_gender, 
    cd.cd_marital_status
ORDER BY 
    total_web_sales DESC
LIMIT 10;
