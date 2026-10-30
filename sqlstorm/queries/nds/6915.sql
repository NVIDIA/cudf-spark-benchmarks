
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank_sales
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND i.i_current_price > 20.00 
        AND ws.ws_sold_date_sk BETWEEN 2458485 AND 2458845
    GROUP BY 
        ws.ws_order_number, ws.ws_item_sk
)

SELECT 
    r.ws_order_number,
    r.ws_item_sk,
    r.total_quantity,
    r.total_sales,
    i.i_item_desc,
    i.i_brand,
    r.rank_sales
FROM 
    ranked_sales r
JOIN 
    item i ON r.ws_item_sk = i.i_item_sk
WHERE 
    r.rank_sales <= 10
ORDER BY 
    r.total_sales DESC, r.total_quantity DESC;
