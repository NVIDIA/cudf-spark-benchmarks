
WITH RecursiveSales AS (
    SELECT 
        ss_customer_sk, 
        SUM(ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss_ticket_number) AS transaction_count,
        ROW_NUMBER() OVER (PARTITION BY ss_customer_sk ORDER BY SUM(ss_net_profit) DESC) AS rn
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_customer_sk
),
TopCustomers AS (
    SELECT 
        cs_bill_cdemo_sk AS csbill_cdemo_sk, 
        SUM(cs_net_profit) AS catalog_profit
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cs_bill_cdemo_sk
),
CombinedSales AS (
    SELECT 
        s.ss_customer_sk,
        s.total_profit,
        COALESCE(c.catalog_profit, 0) AS catalog_profit,
        s.transaction_count
    FROM 
        RecursiveSales s
    LEFT JOIN 
        TopCustomers c ON s.ss_customer_sk = c.csbill_cdemo_sk
)
SELECT 
    ca.ca_city,
    COUNT(*) AS total_customers,
    AVG(cs.total_profit) AS avg_store_profit,
    SUM(cs.catalog_profit) AS total_catalog_profit,
    SUM(cs.transaction_count) AS total_transactions
FROM 
    CombinedSales cs
JOIN 
    customer c ON cs.ss_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    ca.ca_state = 'CA' 
    AND (cs.total_profit > 1000 OR cs.catalog_profit > 500)
    AND cs.transaction_count > 5
GROUP BY 
    ca.ca_city
ORDER BY 
    total_customers DESC;
