
WITH CustomerOrders AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_revenue,
        SUM(ws.ws_ext_sales_price) AS total_web_revenue,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
), RankedOrders AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY cd_marital_status ORDER BY total_store_revenue DESC) AS store_revenue_rank,
        RANK() OVER (PARTITION BY cd_marital_status ORDER BY total_web_revenue DESC) AS web_revenue_rank
    FROM 
        CustomerOrders
)
SELECT 
    c_customer_id,
    c_first_name,
    c_last_name,
    total_store_sales,
    total_web_sales,
    total_store_revenue,
    total_web_revenue,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    ca_city,
    ca_state,
    ca_country
FROM 
    RankedOrders
WHERE 
    store_revenue_rank <= 10 OR web_revenue_rank <= 10
ORDER BY 
    cd_marital_status, 
    total_web_revenue DESC, 
    total_store_revenue DESC;
