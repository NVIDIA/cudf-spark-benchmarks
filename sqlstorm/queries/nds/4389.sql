
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ss.ss_net_paid_inc_tax, 0) + COALESCE(ws.ws_net_paid_inc_tax, 0)) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transaction_count,
        COUNT(DISTINCT ws.ws_order_number) AS web_transaction_count
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
Demographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate > 10000 THEN 'High'
            WHEN cd.cd_purchase_estimate > 5000 THEN 'Medium'
            ELSE 'Low' 
        END AS purchase_category
    FROM 
        customer_demographics cd
),
SalesSummary AS (
    SELECT 
        cs.c_customer_sk,
        d.cd_gender,
        d.cd_marital_status,
        d.purchase_category,
        COALESCE(cs.total_sales, 0) AS total_sales,
        cs.store_transaction_count,
        cs.web_transaction_count
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        Demographics d ON cs.c_customer_sk = d.cd_demo_sk
)
SELECT 
    s.cd_gender,
    s.purchase_category,
    COUNT(s.c_customer_sk) AS customer_count,
    AVG(s.total_sales) AS avg_sales,
    SUM(CASE WHEN s.store_transaction_count > 0 THEN 1 ELSE 0 END) AS store_customers,
    SUM(CASE WHEN s.web_transaction_count > 0 THEN 1 ELSE 0 END) AS web_customers
FROM 
    SalesSummary s
GROUP BY 
    s.cd_gender, s.purchase_category
HAVING 
    AVG(s.total_sales) > 5000
ORDER BY 
    s.cd_gender, s.purchase_category;
