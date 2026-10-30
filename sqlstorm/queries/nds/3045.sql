
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
),
item_summary AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        SUM(COALESCE(ws.ws_quantity, 0)) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
),
sales_analysis AS (
    SELECT 
        ci.c_first_name,
        ci.c_last_name,
        ci.c_email_address,
        isr.total_quantity,
        isr.avg_sales_price * isr.total_quantity AS total_revenue,
        r.rank
    FROM 
        customer_info ci
    JOIN 
        item_summary isr ON ci.c_customer_sk = isr.i_item_sk
    JOIN 
        ranked_sales r ON isr.i_item_sk = r.ws_item_sk
    WHERE 
        r.rank <= 5
)
SELECT 
    sa.c_first_name,
    sa.c_last_name,
    sa.c_email_address,
    sa.total_quantity,
    sa.total_revenue,
    CASE 
        WHEN sa.total_revenue IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status
FROM 
    sales_analysis sa
ORDER BY 
    sa.total_revenue DESC 
LIMIT 10;

