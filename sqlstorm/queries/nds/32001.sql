
WITH  sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        MIN(ws_sold_date_sk) AS first_sale_date
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
customer_segment AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY COALESCE(cd.cd_purchase_estimate, 0) DESC) AS rank 
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
item_analysis AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_current_price,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        COALESCE(AVG(ws.ws_sales_price), 0) AS avg_sales_price
    FROM 
        item i 
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_product_name, i.i_current_price
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.marital_status,
    sa.total_quantity,
    sa.total_sales,
    ia.i_product_name,
    ia.num_orders,
    ia.total_profit,
    ia.avg_sales_price
FROM 
    customer_segment cs
LEFT JOIN 
    sales_data sa ON cs.c_customer_sk = sa.ws_item_sk
FULL OUTER JOIN 
    item_analysis ia ON cs.rank = 1 AND ia.total_profit > 1000 
WHERE 
    cs.purchase_estimate > 100
ORDER BY 
    cs.marital_status, cs.c_last_name, ia.total_profit DESC;
