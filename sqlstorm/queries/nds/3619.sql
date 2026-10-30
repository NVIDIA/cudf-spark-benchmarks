
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
WebSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_web_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
SalesSummary AS (
    SELECT 
        cs.c_customer_sk,
        COALESCE(cs.total_store_sales, 0) AS store_sales,
        COALESCE(ws.total_web_sales, 0) AS web_sales,
        (COALESCE(cs.total_store_sales, 0) + COALESCE(ws.total_web_sales, 0)) AS total_sales,
        CASE 
            WHEN COALESCE(cs.total_store_sales, 0) > 0 AND COALESCE(ws.total_web_sales, 0) > 0 
            THEN 'Both'
            WHEN COALESCE(cs.total_store_sales, 0) > 0 
            THEN 'Store'
            WHEN COALESCE(ws.total_web_sales, 0) > 0 
            THEN 'Web'
            ELSE 'None'
        END AS sales_channel
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        WebSales ws ON cs.c_customer_sk = ws.ws_bill_customer_sk
),
RankedSales AS (
    SELECT 
        s.*,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesSummary s
)
SELECT 
    c.c_customer_id,
    rs.store_sales,
    rs.web_sales,
    rs.total_sales,
    rs.sales_channel,
    rs.sales_rank
FROM 
    RankedSales rs
JOIN 
    customer c ON rs.c_customer_sk = c.c_customer_sk
WHERE 
    (rs.sales_channel = 'Both' OR rs.sales_channel = 'Store')
    AND rs.total_sales > (
        SELECT AVG(total_sales) 
        FROM RankedSales 
        WHERE sales_channel IS NOT NULL
    )
ORDER BY 
    rs.sales_rank;
