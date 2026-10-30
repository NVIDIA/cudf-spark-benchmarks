WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit 
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT CASE WHEN cd.cd_gender = 'M' THEN c.c_customer_sk END) AS male_customers,
        COUNT(DISTINCT CASE WHEN cd.cd_gender = 'F' THEN c.c_customer_sk END) AS female_customers
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
),
item_ranking AS (
    SELECT 
        i.i_item_sk,
        DENSE_RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank,
        CASE WHEN ss.total_quantity IS NULL THEN 0 ELSE 1 END AS has_sales,
        COALESCE(ROUND(ss.total_sales / NULLIF(ss.total_quantity, 0), 2), 0) AS avg_sale_price
    FROM 
        sales_summary ss
    JOIN 
        item i ON i.i_item_sk = ss.ws_item_sk
),
top_items AS (
    SELECT 
        ir.i_item_sk,
        ir.sales_rank,
        ir.avg_sale_price
    FROM 
        item_ranking ir
    WHERE 
        ir.sales_rank <= 10
)
SELECT 
    ci.c_customer_sk,
    ci.male_customers,
    ci.female_customers,
    ti.i_item_sk,
    ti.avg_sale_price,
    COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status,
    CASE 
        WHEN ci.total_orders > 5 THEN 'Frequent Buyer'
        WHEN ci.total_orders < 3 THEN 'Infrequent Buyer'
        ELSE 'Occasional Buyer' 
    END AS buyer_category,
    CASE 
        WHEN ti.avg_sale_price > 100 THEN 'Expensive Item'
        WHEN ti.avg_sale_price BETWEEN 50 AND 100 THEN 'Moderately Priced Item'
        ELSE 'Affordable Item'
    END AS item_price_category
FROM 
    customer_summary ci
CROSS JOIN 
    top_items ti
LEFT JOIN 
    customer_demographics cd ON cd.cd_demo_sk = ci.c_customer_sk
ORDER BY 
    buyer_category DESC, 
    item_price_category, 
    ci.total_orders DESC;