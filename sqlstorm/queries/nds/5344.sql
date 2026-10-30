
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458111 AND 2458711 
    GROUP BY 
        ws_item_sk
), 
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand
    FROM 
        item i
), 
top_sales AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        ss.avg_net_profit,
        ss.order_count,
        id.i_item_desc,
        id.i_current_price,
        id.i_brand
    FROM 
        sales_summary ss
    JOIN 
        item_details id ON ss.ws_item_sk = id.i_item_sk
    ORDER BY 
        ss.total_sales DESC
    LIMIT 10
)
SELECT 
    ts.total_sales,
    ts.total_quantity,
    ts.avg_net_profit,
    ts.order_count,
    ts.i_item_desc,
    ts.i_current_price,
    ts.i_brand
FROM 
    top_sales ts
JOIN 
    customer_demographics cd ON cd.cd_demo_sk IN (
        SELECT c.c_current_cdemo_sk
        FROM customer c
        JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
        WHERE ws.ws_item_sk IN (SELECT ws_item_sk FROM top_sales) 
        GROUP BY c.c_current_cdemo_sk
        HAVING COUNT(DISTINCT ws.ws_order_number) > 5
    )
WHERE 
    cd.cd_gender = 'M' AND 
    cd.cd_marital_status = 'M' AND 
    cd.cd_purchase_estimate > 5000
ORDER BY 
    ts.total_sales DESC;
