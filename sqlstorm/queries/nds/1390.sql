
WITH customer_revenue AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales_null_handled,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
customer_demo AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_state
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ranked_customers AS (
    SELECT 
        cr.c_customer_sk,
        COALESCE(cr.total_web_sales, 0) + COALESCE(cr.total_catalog_sales, 0) + COALESCE(cr.total_store_sales, 0) AS total_revenue,
        cd.cd_gender,
        cd.cd_marital_status,
        RANK() OVER (PARTITION BY cd.ca_state ORDER BY COALESCE(cr.total_web_sales, 0) + COALESCE(cr.total_catalog_sales, 0) + COALESCE(cr.total_store_sales, 0) DESC) AS revenue_rank
    FROM 
        customer_revenue cr
    JOIN 
        customer_demo cd ON cr.c_customer_sk = cd.cd_demo_sk
)
SELECT 
    rc.c_customer_sk,
    rc.total_revenue,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.revenue_rank
FROM 
    ranked_customers rc
WHERE 
    rc.revenue_rank <= 5
ORDER BY 
    rc.revenue_rank;
