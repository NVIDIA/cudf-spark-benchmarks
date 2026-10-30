
WITH sales_summary AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_sales_price) AS total_sales,
        SUM(cs_ext_discount_amt) AS total_discount,
        SUM(cs_net_profit) AS total_net_profit
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cs_item_sk
),
customer_summary AS (
    SELECT 
        c_customer_sk,
        COUNT(DISTINCT cs_order_number) AS order_count,
        SUM(cs_ext_sales_price) AS customer_spending
    FROM 
        customer c
    JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c_customer_sk
),
demographic_summary AS (
    SELECT 
        cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE 
        cd_credit_rating = 'Excellent'
    GROUP BY 
        cd_demo_sk
)
SELECT 
    ss.cs_item_sk,
    ss.total_quantity,
    ss.total_sales,
    ss.total_discount,
    cs.order_count,
    cs.customer_spending,
    ds.customer_count,
    ds.avg_purchase_estimate
FROM 
    sales_summary ss
LEFT JOIN 
    customer_summary cs ON ss.cs_item_sk = cs.c_customer_sk
LEFT JOIN 
    demographic_summary ds ON cs.c_customer_sk = ds.cd_demo_sk
WHERE 
    ss.total_sales > 1000
ORDER BY 
    ss.total_net_profit DESC
LIMIT 100;
