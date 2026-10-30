
WITH CTE_Sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_ext_tax) AS total_ext_tax,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
    GROUP BY 
        ws.ws_item_sk
),
CTE_Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    s.s_store_id,
    SUM(cs.cs_quantity) AS total_sales_quantity,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
    MAX(i.i_current_price) AS max_item_price,
    MIN(i.i_current_price) AS min_item_price,
    dc.total_customers,
    dc.cd_gender,
    dc.cd_marital_status
FROM 
    store_sales ss
JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk
JOIN 
    catalog_sales cs ON ss.ss_item_sk = cs.cs_item_sk
JOIN 
    item i ON ss.ss_item_sk = i.i_item_sk
JOIN 
    CTE_Demographics dc ON dc.cd_demo_sk = ss.ss_customer_sk
WHERE 
    ss.ss_sold_date_sk BETWEEN 20220101 AND 20221231
GROUP BY 
    s.s_store_id, dc.total_customers, dc.cd_gender, dc.cd_marital_status
ORDER BY 
    total_sales_quantity DESC, avg_sales_price DESC;
