
WITH  customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
sales_by_gender AS (
    SELECT 
        cd.cd_gender,
        SUM(cs.total_sales) AS gender_sales
    FROM 
        customer_sales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
sales_per_store AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_net_paid) AS store_sales_total,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name
)
SELECT 
    cs.c_customer_id,
    COALESCE(cd.cd_gender, 'Unknown') AS customer_gender,
    SUM(ws.ws_net_paid) AS total_web_sales,
    AVG(CASE WHEN ws.ws_net_paid IS NOT NULL THEN ws.ws_net_paid ELSE 0 END) AS avg_web_sales,
    st.store_sales_total,
    sbg.gender_sales
FROM 
    customer_sales cs
LEFT JOIN 
    customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON cs.c_customer_sk = ws.ws_ship_customer_sk
LEFT JOIN 
    sales_by_gender sbg ON cd.cd_gender = sbg.cd_gender
LEFT JOIN 
    sales_per_store st ON ws.ws_warehouse_sk = st.s_store_sk
WHERE 
    total_sales > 1000 OR cd.cd_marital_status = 'M'
GROUP BY 
    cs.c_customer_id, cd.cd_gender, st.store_sales_total, sbg.gender_sales
ORDER BY 
    total_web_sales DESC, cs.c_customer_id
LIMIT 50;
