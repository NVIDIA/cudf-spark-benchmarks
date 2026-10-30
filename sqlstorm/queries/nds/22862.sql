
WITH  address_hierarchy AS (
    SELECT 
        ca_address_sk, 
        ca_address_id, 
        CONCAT(ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city, 
        CASE WHEN ca_county IS NULL THEN 'Unknown County' ELSE ca_county END AS county,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) AS addr_rank
    FROM customer_address
    WHERE ca_state = 'CA'
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        SUM(COALESCE(ws.ws_sales_price, 0)) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
income_details AS (
    SELECT 
        hd.hd_demo_sk,
        COUNT(hd.hd_income_band_sk) AS total_income_bands
    FROM 
        household_demographics hd
    INNER JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        ib.ib_lower_bound IS NOT NULL AND ib.ib_upper_bound IS NOT NULL
    GROUP BY 
        hd.hd_demo_sk
),
promotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        COUNT(p.p_item_sk) AS promo_count,
        SUM(COALESCE(store_sales.ss_net_profit, 0)) AS promo_profit
    FROM 
        promotion p
    JOIN 
        catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    LEFT JOIN 
        store_sales ON cs.cs_item_sk = store_sales.ss_item_sk
    GROUP BY 
        p.p_promo_sk, p.p_promo_name
    HAVING 
        SUM(COALESCE(store_sales.ss_net_profit, 0)) > 1000
),
final_report AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.total_spent,
        a.full_address,
        a.county,
        COALESCE(id.total_income_bands, 0) AS total_income_bands,
        COALESCE(p.promo_count, 0) AS promo_count,
        COALESCE(p.promo_profit, 0) AS promo_profit
    FROM 
        customer_details cd
    JOIN 
        address_hierarchy a ON cd.c_customer_sk = a.addr_rank
    LEFT JOIN 
        income_details id ON cd.c_customer_sk = id.hd_demo_sk
    LEFT JOIN 
        promotions p ON cd.c_customer_sk = p.promo_count
    WHERE 
        cd.total_spent IS NOT NULL
)
SELECT 
    * 
FROM 
    final_report
WHERE 
    full_address LIKE '%Street%' 
    AND total_spent > 5000
ORDER BY 
    county ASC, c_last_name DESC;
