
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_sales_quantity,
        COALESCE(SUM(ws.ws_net_paid_inc_tax), 0) AS total_sales_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    LEFT JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND dd.d_month_seq BETWEEN 1 AND 6
    GROUP BY 
        ws.ws_item_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band,
        COUNT(DISTINCT o.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales o ON c.c_customer_sk = o.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, hd.hd_income_band_sk
),
item_ranking AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        ss.total_sales_quantity,
        ss.total_sales_revenue,
        ss.sales_rank
    FROM 
        item i
    JOIN 
        sales_summary ss ON i.i_item_sk = ss.ws_item_sk
    WHERE 
        ss.sales_rank <= 10
)
SELECT 
    ir.i_item_desc,
    ir.total_sales_quantity,
    ir.total_sales_revenue,
    ci.gender,
    ci.income_band,
    ci.order_count
FROM 
    item_ranking ir
JOIN 
    customer_info ci ON ir.total_sales_quantity > 0
ORDER BY 
    ir.total_sales_revenue DESC;
