
WITH CustomerStats AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_quantity) AS avg_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND dd.d_moy BETWEEN 1 AND 6
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
StoreStats AS (
    SELECT 
        s.s_store_name,
        COUNT(ss.ss_ticket_number) AS store_order_count,
        SUM(ss.ss_ext_sales_price) AS store_sales
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    WHERE 
        ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy BETWEEN 1 AND 6)
    GROUP BY 
        s.s_store_name
),
TopStores AS (
    SELECT 
        s.s_store_name,
        ss.store_sales
    FROM 
        StoreStats ss
    JOIN 
        store s ON ss.s_store_name = s.s_store_name
    ORDER BY 
        ss.store_sales DESC
    LIMIT 5
)
SELECT 
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_sales,
    cs.avg_quantity,
    ts.store_sales,
    ts.store_order_count
FROM 
    CustomerStats cs
JOIN 
    StoreStats ts ON cs.total_sales > ts.store_sales
ORDER BY 
    cs.total_sales DESC, ts.store_sales DESC;
