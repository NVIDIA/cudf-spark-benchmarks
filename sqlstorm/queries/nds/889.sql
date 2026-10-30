
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
Promotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS promo_sales_count,
        SUM(ws.ws_net_paid) AS promo_sales_amount
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk, p.p_promo_name
),
FemaleCustomerInfo AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        c.c_first_name,
        c.c_last_name
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE 
        cd.cd_gender = 'F'
),
IncomeDemographics AS (
    SELECT 
        h.hd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        h.hd_buy_potential
    FROM 
        household_demographics h
    LEFT JOIN 
        income_band ib ON h.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    fci.c_first_name,
    fci.c_last_name,
    SUM(cs.total_sales) AS total_spent,
    COUNT(cs.transaction_count) AS number_of_transactions,
    pi.promo_sales_count,
    pi.promo_sales_amount,
    id.ib_lower_bound,
    id.ib_upper_bound,
    id.hd_buy_potential
FROM 
    FemaleCustomerInfo fci
LEFT JOIN 
    CustomerSales cs ON fci.cd_demo_sk = cs.c_customer_sk
LEFT JOIN 
    Promotions pi ON pi.promo_sales_count > 0
LEFT JOIN 
    IncomeDemographics id ON fci.cd_demo_sk = id.hd_demo_sk
WHERE 
    (id.hd_buy_potential IS NOT NULL AND pi.promo_sales_amount IS NOT NULL) 
    OR fci.cd_marital_status = 'M'
GROUP BY 
    fci.c_first_name, fci.c_last_name, pi.promo_sales_count, pi.promo_sales_amount,
    id.ib_lower_bound, id.ib_upper_bound, id.hd_buy_potential
HAVING 
    SUM(cs.total_sales) > 1000
ORDER BY 
    total_spent DESC;
