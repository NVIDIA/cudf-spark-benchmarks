
WITH sales_summary AS (
    SELECT 
        ci.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_purchased
    FROM 
        web_sales ws
    JOIN 
        customer ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    JOIN 
        customer_demographics cd ON ci.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND 
        cd.cd_marital_status = 'M'
    GROUP BY 
        ci.c_customer_id
),
high_value_customers AS (
    SELECT 
        css.c_customer_id,
        css.total_sales,
        css.total_orders,
        css.avg_sales_price,
        css.unique_items_purchased
    FROM 
        sales_summary css
    WHERE 
        css.total_sales > (
            SELECT 
                AVG(total_sales) 
            FROM 
                sales_summary
        )
)
SELECT 
    hvc.c_customer_id,
    hvc.total_sales,
    hvc.total_orders,
    hvc.avg_sales_price,
    hvc.unique_items_purchased,
    cd.cd_gender,
    cd.cd_credit_rating,
    cd.cd_education_status
FROM 
    high_value_customers hvc
JOIN 
    customer ci ON hvc.c_customer_id = ci.c_customer_id
JOIN 
    customer_demographics cd ON ci.c_current_cdemo_sk = cd.cd_demo_sk
ORDER BY 
    hvc.total_sales DESC
LIMIT 100;
