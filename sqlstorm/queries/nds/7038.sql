
WITH CustomerStats AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_purchase_estimate > 500
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
WeeklySales AS (
    SELECT 
        d.d_year, 
        d.d_week_seq, 
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales
    FROM 
        date_dim AS d
    JOIN 
        web_sales AS ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year, d.d_week_seq
),
TopItems AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_revenue
    FROM 
        item AS i
    JOIN 
        web_sales AS ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id
    ORDER BY 
        total_sales_revenue DESC
    LIMIT 10
)
SELECT 
    cs.cd_gender,
    cs.cd_marital_status,
    ws.d_year,
    ws.d_week_seq,
    ws.total_sales,
    ti.i_item_id,
    ti.total_quantity_sold,
    ti.total_sales_revenue,
    cs.customer_count
FROM 
    CustomerStats AS cs
JOIN 
    WeeklySales AS ws ON cs.customer_count > 0
JOIN 
    TopItems AS ti ON cs.customer_count > 0
ORDER BY 
    cs.cd_gender, 
    cs.cd_marital_status, 
    ws.d_year DESC, 
    ws.d_week_seq DESC;
