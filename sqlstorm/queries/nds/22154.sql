
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_sales_price, 
        ws.ws_quantity, 
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
item_revenue AS (
    SELECT 
        i.i_item_sk, 
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_revenue
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk, 
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders,
        SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
        COUNT(*) FILTER (WHERE hd.hd_income_band_sk IS NOT NULL) AS income_band_customers
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY 
        c.c_customer_sk
),
sales_summary AS (
    SELECT 
        rws.ws_item_sk, 
        total_revenue, 
        COUNT(DISTINCT ci.c_customer_sk) AS customer_count,
        AVG(ci.total_catalog_orders) AS avg_catalog_orders
    FROM 
        ranked_sales rws
    JOIN 
        item_revenue ir ON rws.ws_item_sk = ir.i_item_sk
    JOIN 
        customer_info ci ON rws.ws_item_sk = ci.c_customer_sk
    WHERE 
        rws.sales_rank <= 10
    GROUP BY 
        rws.ws_item_sk, total_revenue
)
SELECT 
    ir.i_item_sk, 
    ir.total_revenue,
    COALESCE(ss.customer_count, 0) AS active_customers,
    CASE 
        WHEN ir.total_revenue <= 1000 THEN 'Low Revenue'
        WHEN ir.total_revenue BETWEEN 1001 AND 5000 THEN 'Medium Revenue'
        ELSE 'High Revenue' 
    END AS revenue_category
FROM 
    item_revenue ir
LEFT JOIN 
    sales_summary ss ON ir.i_item_sk = ss.ws_item_sk
WHERE 
    ir.i_item_sk NOT IN (SELECT wp.wp_web_page_sk FROM web_page wp WHERE wp.wp_autogen_flag = 'Y')
ORDER BY 
    ir.total_revenue DESC
LIMIT 50;
