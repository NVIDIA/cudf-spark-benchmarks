
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT 
                d.d_date_sk 
            FROM 
                date_dim d 
            WHERE 
                d.d_year = 2023
        )
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
StoreSales AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_net_paid) AS total_store_net_paid
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss.ss_sold_date_sk IN (
            SELECT 
                d.d_date_sk 
            FROM 
                date_dim d 
            WHERE 
                d.d_year = 2023
        )
    GROUP BY 
        s.s_store_sk
),
DemographicSummary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT cs.c_customer_sk) AS customer_count,
        SUM(cs.total_net_paid) AS total_sales,
        AVG(cs.total_net_paid) AS average_sales
    FROM 
        customer_demographics cd
    LEFT JOIN 
        CustomerSales cs ON cd.cd_demo_sk = cs.c_customer_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ds.cd_gender,
    ds.cd_marital_status,
    ds.customer_count,
    ds.total_sales,
    ds.average_sales,
    COALESCE(ss.total_store_net_paid, 0) AS total_store_sales,
    CASE 
        WHEN ds.customer_count > 0 THEN ds.total_sales / ds.customer_count 
        ELSE 0 
    END AS average_sales_per_customer
FROM 
    DemographicSummary ds
FULL OUTER JOIN 
    StoreSales ss ON ds.cd_gender = 'F' AND ds.cd_marital_status = 'M'
WHERE 
    ds.customer_count > 50 OR ds.total_sales > 10000
ORDER BY 
    ds.total_sales DESC, ds.customer_count DESC;
