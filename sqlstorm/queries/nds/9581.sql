
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE 
        t.t_hour BETWEEN 9 AND 17 
        AND cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        ws.ws_item_sk
), 
ranked_sales AS (
    SELECT 
        s.*,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        sales_summary s
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    r.total_quantity,
    r.total_sales,
    r.avg_profit,
    r.sales_rank
FROM 
    ranked_sales r
JOIN 
    item i ON r.ws_item_sk = i.i_item_sk
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.sales_rank;
