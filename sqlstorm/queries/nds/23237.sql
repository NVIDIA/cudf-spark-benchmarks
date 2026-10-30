
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_customer_id, 
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
), 
customer_sales AS (
    SELECT 
        cs.cs_bill_customer_sk,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        cs.cs_bill_customer_sk
), 
sales_breakdown AS (
    SELECT 
        cus.c_customer_id,
        cs.order_count, 
        cs.total_net_profit,
        CASE 
            WHEN cs.total_net_profit > 1000 THEN 'High Value'
            WHEN cs.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_segment
    FROM 
        ranked_customers cus
    LEFT JOIN 
        customer_sales cs ON cus.c_customer_sk = cs.cs_bill_customer_sk
    WHERE 
        cus.purchase_rank <= 10
)
SELECT 
    sb.c_customer_id,
    COALESCE(sb.order_count, 0) AS order_count,
    COALESCE(sb.total_net_profit, 0.00) AS total_net_profit,
    sb.customer_value_segment,
    CASE 
        WHEN sb.customer_value_segment = 'High Value' THEN 'VIP'
        ELSE 'Regular'
    END AS customer_category,
    CASE 
        WHEN sb.customer_value_segment IS NULL THEN 'Not Categorized'
        ELSE sb.customer_value_segment
    END AS segment_fallback
FROM 
    sales_breakdown sb
FULL OUTER JOIN 
    store s ON s.s_store_sk = (SELECT MIN(ss.ss_store_sk) FROM store_sales ss WHERE ss.ss_item_sk IN (SELECT i.i_item_sk FROM item i WHERE i.i_brand = 'BrandX') GROUP BY ss.ss_store_sk ORDER BY SUM(ss.ss_net_paid) DESC LIMIT 1)
WHERE 
    s.s_country IS NOT NULL
ORDER BY 
    sb.total_net_profit DESC NULLS LAST;
