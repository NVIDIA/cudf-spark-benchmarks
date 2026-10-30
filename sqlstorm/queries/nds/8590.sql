
WITH sales_summary AS (
    SELECT 
        d.d_year AS sales_year,
        d.d_month_seq AS sales_month,
        SUM(ss.ss_net_paid) AS total_net_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers
    FROM 
        store_sales ss
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year, d.d_month_seq
), customer_summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        SUM(cd.cd_purchase_estimate) AS total_estimated_purchases
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
), promotions_summary AS (
    SELECT 
        p.p_promo_name,
        COUNT(cs.cs_order_number) AS total_orders,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM 
        catalog_sales cs
    JOIN 
        promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        p.p_promo_name
)
SELECT 
    ss.sales_year,
    ss.sales_month,
    ss.total_net_sales,
    ss.total_transactions,
    ss.unique_customers,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_customers,
    cs.total_estimated_purchases,
    ps.p_promo_name,
    ps.total_orders,
    ps.total_net_profit
FROM 
    sales_summary ss
JOIN 
    customer_summary cs ON cs.total_customers > 0
LEFT JOIN 
    promotions_summary ps ON ps.total_orders > 0
ORDER BY 
    ss.sales_year, ss.sales_month, cs.cd_gender, cs.cd_marital_status;
