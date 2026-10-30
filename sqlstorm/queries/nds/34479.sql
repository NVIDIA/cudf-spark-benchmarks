
WITH  CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_store_sales,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_sales
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), RankedSales AS (
    SELECT 
        c.*, 
        RANK() OVER (ORDER BY total_store_sales + total_web_sales DESC) AS sales_rank
    FROM 
        CustomerSales c
), FrequentCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        EXISTS (
            SELECT 1 
            FROM store_sales ss WHERE ss.ss_customer_sk = c.c_customer_sk GROUP BY ss.ss_customer_sk 
            HAVING COUNT(DISTINCT ss.ss_ticket_number) > 5
        ) AS frequent
    FROM 
        customer c
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.total_store_sales,
    rc.total_web_sales,
    rc.sales_rank,
    fc.frequent
FROM 
    RankedSales rc
JOIN 
    FrequentCustomers fc ON rc.c_customer_sk = fc.c_customer_sk
WHERE 
    (rc.total_store_sales + rc.total_web_sales) > 1000 AND
    (fc.frequent IS TRUE OR rc.sales_rank <= 10)
ORDER BY 
    rc.sales_rank;
