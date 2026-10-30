
WITH CustomerStats AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(CASE WHEN cd_dep_count > 0 THEN 1 ELSE 0 END) AS households_with_deps,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        AVG(cd_dep_count) AS avg_dep_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        cd_gender, cd_marital_status
), StoreSalesData AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        AVG(ss_quantity) AS avg_sales_quantity,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_store_sk
), PromotionStats AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws_order_number) AS promo_order_count,
        SUM(ws_ext_sales_price) AS total_promo_sales
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE 
        p.p_start_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND p.p_end_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        p.p_promo_id
)
SELECT 
    cs.cd_gender,
    cs.cd_marital_status,
    cs.customer_count,
    cs.households_with_deps,
    cs.avg_purchase_estimate,
    cs.avg_dep_count,
    ssd.total_sales,
    ssd.avg_sales_quantity,
    ssd.total_transactions,
    ps.promo_order_count,
    ps.total_promo_sales
FROM 
    CustomerStats cs
JOIN 
    StoreSalesData ssd ON cs.customer_count > 100
LEFT JOIN 
    PromotionStats ps ON ps.promo_order_count > 10
ORDER BY 
    cs.customer_count DESC, ssd.total_sales DESC;
