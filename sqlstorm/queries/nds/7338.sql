
WITH SalesStats AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity_sold,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_sales_price) AS avg_sales_price,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE 
        p.p_start_date_sk <= (
            SELECT MAX(d.d_date_sk) 
            FROM date_dim d 
            WHERE d.d_year = 2023
        ) AND 
        p.p_end_date_sk >= (
            SELECT MIN(d.d_date_sk) 
            FROM date_dim d 
            WHERE d.d_year = 2023
        )
    GROUP BY cs.cs_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        SUM(ws.ws_net_paid) AS total_web_revenue
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
SalesByDemographics AS (
    SELECT 
        cd.cd_gender,
        SUM(ss.total_sales) AS total_sales_by_gender,
        AVG(cs.total_web_revenue) AS avg_revenue_per_customer
    FROM SalesStats ss
    JOIN CustomerStats cs ON ss.cs_item_sk = cs.total_web_orders
    JOIN customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
)
SELECT 
    cd.cd_gender,
    sb.total_sales_by_gender,
    sb.avg_revenue_per_customer
FROM SalesByDemographics sb
JOIN customer_demographics cd ON sb.cd_gender = cd.cd_gender
WHERE sb.total_sales_by_gender > 10000
ORDER BY sb.total_sales_by_gender DESC;
