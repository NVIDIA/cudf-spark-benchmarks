
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_current_cdemo_sk,
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate, 
        cd.cd_credit_rating, 
        cd.cd_dep_count, 
        cd.cd_dep_employed_count, 
        cd.cd_dep_college_count, 
        hd.hd_income_band_sk
),
SalesData AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        ws.ws_ship_date_sk, 
        ws.ws_item_sk
),
PromotionSummary AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        p.p_promo_sk, 
        p.p_promo_name
),
FinalReport AS (
    SELECT 
        ci.c_customer_sk,
        ci.cd_gender,
        ci.cd_marital_status,
        SUM(sd.total_quantity) AS total_quantity_purchased,
        SUM(sd.total_profit) AS total_profit,
        COUNT(DISTINCT ps.p_promo_sk) AS active_promotions
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesData sd ON ci.c_customer_sk = sd.ws_item_sk
    LEFT JOIN 
        PromotionSummary ps ON sd.ws_item_sk = ps.p_promo_sk
    GROUP BY 
        ci.c_customer_sk, 
        ci.cd_gender, 
        ci.cd_marital_status
)
SELECT 
    fr.c_customer_sk,
    fr.cd_gender,
    fr.cd_marital_status,
    fr.total_quantity_purchased,
    fr.total_profit,
    fr.active_promotions,
    RANK() OVER (ORDER BY fr.total_profit DESC) AS profit_rank
FROM 
    FinalReport fr
WHERE 
    fr.total_profit > (SELECT AVG(total_profit) FROM FinalReport)
ORDER BY 
    fr.total_profit DESC;
