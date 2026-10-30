
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_paid_inc_tax), 0) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
Promotions AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS promo_order_count,
        SUM(ws.ws_net_paid_inc_tax) AS promo_sales
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        p.p_promo_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_sales,
    cs.total_orders,
    cs.unique_items,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COALESCE(promo.total_orders, 0) AS promo_order_count,
    COALESCE(promo.promo_sales, 0) AS promo_sales
FROM 
    CustomerSales cs
LEFT JOIN 
    CustomerDemographics cd ON cs.c_customer_sk = cd.cd_demo_sk
LEFT JOIN 
    (
        SELECT 
            pd.promo_order_count,
            pd.promo_sales,
            COUNT(DISTINCT pd.promo_order_count) AS total_orders
        FROM 
            Promotions pd
        GROUP BY 
            pd.promo_order_count, pd.promo_sales
    ) promo ON promo.promo_order_count = cs.total_orders
WHERE 
    cs.total_sales > 1000 
    OR cd.cd_marital_status = 'M'
ORDER BY 
    cs.total_sales DESC
LIMIT 10;
