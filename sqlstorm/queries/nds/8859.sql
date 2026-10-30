
WITH SalesSummary AS (
    SELECT 
        d.d_year,
        d.d_moy,
        p.p_promo_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
        AND p.p_discount_active = 'Y'
    GROUP BY 
        d.d_year, d.d_moy, p.p_promo_name
),
CustomerSummary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender IN ('M', 'F')
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ss.d_year,
    ss.d_moy,
    ss.p_promo_name,
    ss.total_quantity,
    ss.total_sales,
    ss.total_profit,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.avg_purchase_estimate,
    cs.total_customers
FROM 
    SalesSummary ss
JOIN 
    CustomerSummary cs ON cs.cd_gender = CASE 
                                            WHEN ss.total_quantity > 100 THEN 'M' 
                                            ELSE 'F' 
                                         END
ORDER BY 
    ss.d_year, 
    ss.d_moy, 
    ss.total_sales DESC;
