
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpenders AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name
    FROM 
        CustomerSales
    WHERE 
        total_web_sales > (SELECT AVG(total_web_sales) FROM CustomerSales)
),
PromotionStats AS (
    SELECT 
        p.p_promo_id,
        COUNT(cs.c_customer_sk) AS customer_count,
        SUM(ws.ws_net_paid) AS total_sales_from_promo
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        CustomerSales cs ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.c_customer_sk IS NOT NULL
    GROUP BY 
        p.p_promo_id
),
TotalReturns AS (
    SELECT 
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        SUM(cr_return_amt_inc_tax) AS total_catalog_return_amt
    FROM 
        store_returns sr
    FULL OUTER JOIN 
        catalog_returns cr ON sr.sr_item_sk = cr.cr_item_sk
)
SELECT 
    H.c_first_name,
    H.c_last_name,
    COALESCE(P.p_promo_id, 'None') AS promotional_campaign,
    P.total_sales_from_promo AS promo_sales,
    T.total_return_amt,
    T.total_catalog_return_amt
FROM 
    HighSpenders H
LEFT JOIN 
    PromotionStats P ON H.c_customer_sk = P.customer_count
CROSS JOIN 
    TotalReturns T
WHERE 
    (P.total_sales_from_promo IS NULL OR P.total_sales_from_promo > 5000)
ORDER BY 
    H.c_last_name, H.c_first_name;
