
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(ws2.ws_sold_date_sk) FROM web_sales ws2)
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
StoreSales AS (
    SELECT 
        s.s_store_sk,
        s.s_store_id,
        SUM(ss.ss_net_paid_inc_tax) AS total_store_sales
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    WHERE 
        ss.ss_sold_date_sk = (SELECT MAX(ss2.ss_sold_date_sk) FROM store_sales ss2)
    GROUP BY 
        s.s_store_sk, s.s_store_id
),
SalesSummary AS (
    SELECT 
        cs.c_customer_id,
        COALESCE(cs.total_web_sales, 0) AS web_sales,
        COALESCE(ss.total_store_sales, 0) AS store_sales,
        COALESCE(cs.total_web_sales, 0) + COALESCE(ss.total_store_sales, 0) AS total_sales
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_id = ss.s_store_id
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS rank
    FROM 
        SalesSummary
)
SELECT 
    CONCAT('Customer ID: ', r.c_customer_id, ' - Total Sales: $', ROUND(r.total_sales, 2)) AS sales_info
FROM 
    RankedSales r
WHERE 
    r.rank <= 10 OR r.web_sales > 10000 OR r.store_sales > 5000
ORDER BY 
    r.total_sales DESC;
