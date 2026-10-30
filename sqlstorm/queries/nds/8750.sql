
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND dd.d_year = 2023 
        AND i.i_current_price > 20.00
    GROUP BY 
        ws.ws_item_sk
),
ranked_sales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_orders,
        sd.total_quantity,
        sd.total_sales,
        sd.avg_net_profit,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        sales_data sd
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    rs.total_orders,
    rs.total_quantity,
    rs.total_sales,
    rs.avg_net_profit,
    rs.sales_rank
FROM 
    ranked_sales rs
JOIN 
    item i ON rs.ws_item_sk = i.i_item_sk
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    rs.sales_rank;
