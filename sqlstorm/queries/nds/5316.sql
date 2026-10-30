
WITH CustomerCounts AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c.c_customer_id) AS total_customers,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
SalesData AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
),
PromoData AS (
    SELECT 
        p.p_promo_name,
        SUM(CASE WHEN ws.ws_sales_price > 100 THEN ws.ws_net_profit ELSE 0 END) AS high_value_sales_profit
    FROM 
        promotion p
    JOIN 
        web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        p.p_promo_name
)
SELECT 
    cc.cd_gender,
    cc.total_customers,
    cc.total_dependents,
    cc.avg_purchase_estimate,
    sd.d_year,
    sd.total_sales,
    sd.total_quantity,
    sd.total_orders,
    pd.p_promo_name,
    pd.high_value_sales_profit
FROM 
    CustomerCounts cc
JOIN 
    SalesData sd ON TRUE
JOIN 
    PromoData pd ON TRUE
ORDER BY 
    cc.cd_gender, sd.d_year, pd.p_promo_name;
