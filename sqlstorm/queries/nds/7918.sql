
WITH RankedCustomer AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS expenditure_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d_date_sk FROM date_dim WHERE d_year = 2023
        )
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
RankedPromotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        COUNT(cp.cp_catalog_page_sk) AS pages_linked,
        RANK() OVER (ORDER BY COUNT(cp.cp_catalog_page_sk) DESC) AS promotion_rank
    FROM 
        promotion p
    LEFT JOIN 
        catalog_page cp ON p.p_promo_sk = cp.cp_catalog_page_sk
    GROUP BY 
        p.p_promo_sk, p.p_promo_name
)
SELECT 
    rc.c_customer_sk,
    rc.c_first_name,
    rc.c_last_name,
    rc.total_spent,
    rp.p_promo_name,
    rp.pages_linked
FROM 
    RankedCustomer rc
JOIN 
    RankedPromotions rp ON rc.expenditure_rank <= 5 AND rp.promotion_rank <= 3
ORDER BY 
    rc.total_spent DESC, rp.pages_linked DESC
LIMIT 25;
