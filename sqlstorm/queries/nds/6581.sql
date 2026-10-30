WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        ws.ws_item_sk,
        i.i_item_desc,
        c.c_first_name,
        c.c_last_name,
        cc.cc_call_center_id
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        call_center cc ON c.c_current_cdemo_sk = cc.cc_call_center_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2458120 AND 2458180 
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk, i.i_item_desc, c.c_first_name, c.c_last_name, cc.cc_call_center_id
),
top_sales AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY ws_sold_date_sk ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    d.d_date AS sales_date,
    ts.i_item_desc,
    ts.total_sales,
    ts.total_net_paid,
    ts.total_orders,
    ts.avg_net_profit,
    ts.c_first_name,
    ts.c_last_name,
    ts.cc_call_center_id
FROM 
    top_sales ts
JOIN 
    date_dim d ON ts.ws_sold_date_sk = d.d_date_sk
WHERE 
    ts.sales_rank <= 5
ORDER BY 
    d.d_date, ts.total_sales DESC;