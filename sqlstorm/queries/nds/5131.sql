
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        AVG(ws.ws_net_profit) AS average_profit,
        MAX(ws.ws_sales_price) AS max_price,
        MIN(ws.ws_sales_price) AS min_price
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023 AND
        cd.cd_gender = 'F'
    GROUP BY 
        ws.ws_item_sk
),
item_details AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_brand,
        i.i_category,
        ss.total_quantity_sold,
        ss.total_sales,
        ss.average_profit,
        ss.max_price,
        ss.min_price
    FROM 
        sales_summary ss
    JOIN 
        item i ON ss.ws_item_sk = i.i_item_sk
)
SELECT 
    id.i_item_id,
    id.i_item_desc,
    id.i_brand,
    id.i_category,
    id.total_quantity_sold,
    id.total_sales,
    id.average_profit,
    id.max_price,
    id.min_price
FROM 
    item_details id
ORDER BY 
    id.total_sales DESC
LIMIT 10;
