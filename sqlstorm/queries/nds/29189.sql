WITH AddressDetails AS (
    SELECT 
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LTRIM(RTRIM(ca_suite_number)) AS suite_number
    FROM 
        customer_address
),
CustomerStatistics AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        AVG(cd_dep_count) AS avg_dependent_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_gender
),
DailySales AS (
    SELECT 
        d.d_date AS sales_date,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales ws 
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_date
),
PromotionAnalysis AS (
    SELECT 
        p.p_promo_name,
        SUM(cs_ext_sales_price) AS promo_sales
    FROM 
        catalog_sales cs
    JOIN 
        promotion p ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY 
        p.p_promo_name
),
TopProducts AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        web_sales ws 
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id, 
        i.i_product_name
    ORDER BY 
        total_quantity_sold DESC
    LIMIT 10
)
SELECT 
    ad.ca_city,
    ad.ca_state,
    ad.full_address,
    cs.cd_gender,
    cs.customer_count,
    cs.avg_dependent_count,
    ds.sales_date,
    ds.total_sales,
    ds.total_profit,
    pa.promo_sales,
    tp.i_product_name,
    tp.total_quantity_sold
FROM 
    AddressDetails ad
JOIN 
    CustomerStatistics cs ON ad.ca_city = cs.cd_gender 
JOIN 
    DailySales ds ON ds.sales_date >= '2001-01-01' 
LEFT JOIN 
    PromotionAnalysis pa ON pa.promo_sales > 1000 
LEFT JOIN 
    TopProducts tp ON tp.total_quantity_sold > 500 
ORDER BY 
    ad.ca_city, cs.customer_count DESC, ds.total_sales DESC;