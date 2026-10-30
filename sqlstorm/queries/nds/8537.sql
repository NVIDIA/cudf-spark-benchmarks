
WITH CustomerData AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ca.ca_state = 'CA'
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'S'
    GROUP BY 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        ca.ca_city, 
        ca.ca_state, 
        cd.cd_gender, 
        cd.cd_marital_status
),
PromoData AS (
    SELECT 
        p.p_promo_name,
        p.p_discount_active,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        p.p_promo_name, 
        p.p_discount_active
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.ca_city,
    cd.total_spent,
    pd.p_promo_name AS promo_name,
    pd.total_discount
FROM 
    CustomerData cd
LEFT JOIN 
    PromoData pd ON cd.total_spent > pd.total_discount
ORDER BY 
    cd.total_spent DESC
LIMIT 100;
