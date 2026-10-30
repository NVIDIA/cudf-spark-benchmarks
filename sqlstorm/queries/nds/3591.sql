
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(ws.ws_order_number) AS web_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
),
StoreSales AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(ss.ss_ticket_number) AS store_order_count
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cb.total_web_sales,
        cb.web_order_count,
        sb.total_store_sales,
        sb.store_order_count
    FROM 
        customer_demographics cd
    JOIN 
        CustomerSales cb ON cd.cd_demo_sk = cb.c_customer_sk
    LEFT JOIN 
        StoreSales sb ON cb.c_customer_sk = sb.s_store_sk 
    WHERE 
        cd.cd_gender = 'F' OR cd.cd_marital_status = 'M'
),
SalesSummary AS (
    SELECT 
        d.cd_gender,
        d.cd_marital_status,
        COALESCE(SUM(d.total_web_sales), 0) AS total_web_sales,
        COALESCE(SUM(d.total_store_sales), 0) AS total_store_sales,
        COUNT(DISTINCT d.cd_demo_sk) AS demographic_count
    FROM 
        Demographics d
    GROUP BY 
        d.cd_gender, d.cd_marital_status
)
SELECT 
    ds.cd_gender,
    ds.cd_marital_status,
    ds.total_web_sales,
    ds.total_store_sales,
    ds.demographic_count,
    CASE 
        WHEN ds.total_web_sales > ds.total_store_sales THEN 'Web Dominant'
        WHEN ds.total_web_sales < ds.total_store_sales THEN 'Store Dominant'
        ELSE 'Equal Sales'
    END AS sales_dominance
FROM 
    SalesSummary ds
ORDER BY 
    ds.total_web_sales DESC, ds.total_store_sales DESC;
