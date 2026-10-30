
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate, 
        COALESCE(hd.hd_income_band_sk, 0) AS income_band_sk,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, hd.hd_income_band_sk
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank
    FROM 
        customer_summary cs
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM customer_summary)
),
top_categories AS (
    SELECT 
        i.i_category,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_category
    HAVING 
        SUM(ws.ws_quantity) > 100
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_spent,
    tc.i_category,
    MAX(tc.total_quantity_sold) AS max_quantity_sold
FROM 
    high_value_customers hvc
JOIN 
    top_categories tc ON hvc.spending_rank <= 10
GROUP BY 
    hvc.c_first_name, hvc.c_last_name, hvc.total_spent, tc.i_category
ORDER BY 
    hvc.total_spent DESC, max_quantity_sold DESC
LIMIT 100;
