
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
HighValueCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name, 
        rc.cd_gender, 
        rc.cd_purchase_estimate
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rn <= 10
),
MonthlySales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
),
SalesByPromotions AS (
    SELECT 
        p.p_promo_name,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        p.p_promo_name
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.cd_purchase_estimate,
    COALESCE(ms.total_profit, 0) AS monthly_profit,
    COALESCE(sp.total_sales, 0) AS promotion_sales
FROM 
    HighValueCustomers c
LEFT JOIN 
    MonthlySales ms ON c.cd_purchase_estimate BETWEEN 500 AND 1000 AND ms.d_year = 2023
LEFT JOIN 
    SalesByPromotions sp ON sp.total_sales > 1000
WHERE 
    c.cd_gender IN ('M', 'F')
ORDER BY 
    c.cd_purchase_estimate DESC;
