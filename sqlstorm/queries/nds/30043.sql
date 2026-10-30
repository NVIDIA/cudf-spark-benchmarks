
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, hd.hd_income_band_sk
), address_summary AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    CASE 
        WHEN cs.order_count > 10 THEN 'Frequent Shopper'
        WHEN cs.total_spent > (SELECT AVG(total_spent) FROM customer_summary) THEN 'High Value'
        ELSE 'Occasional Shopper'
    END AS customer_category,
    asu.ca_city,
    asu.total_customers || ' customers' AS customer_count,
    asu.total_revenue
FROM 
    customer_summary cs
LEFT JOIN 
    address_summary asu ON cs.c_customer_sk = asu.ca_address_sk
WHERE 
    (asu.total_revenue IS NOT NULL AND asu.total_revenue > 1000)
    OR (asu.total_revenue IS NULL AND cs.total_spent > 500)
ORDER BY 
    cs.total_spent DESC
LIMIT 50;
