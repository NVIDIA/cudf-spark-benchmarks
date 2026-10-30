
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_purchase_estimate > 1000 
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, 
        cd.cd_purchase_estimate, ca.ca_city, ca.ca_state, ca.ca_country
),
PromotionDetails AS (
    SELECT 
        p.p_promo_id,
        COUNT(ws.ws_order_number) AS usage_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
),
StoreSalesSummary AS (
    SELECT 
        s.s_store_id,
        COUNT(ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_net_paid) AS total_revenue
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_id
)
SELECT 
    cd.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.ca_city,
    cd.ca_state,
    cd.ca_country,
    cd.total_spent,
    pd.p_promo_id,
    pd.usage_count,
    pd.avg_order_value,
    ss.s_store_id,
    ss.total_sales,
    ss.total_revenue
FROM 
    CustomerDetails cd
LEFT JOIN 
    PromotionDetails pd ON cd.total_orders > 5
LEFT JOIN 
    StoreSalesSummary ss ON cd.total_spent > 5000
ORDER BY 
    cd.total_spent DESC, ss.total_revenue DESC
LIMIT 100;
