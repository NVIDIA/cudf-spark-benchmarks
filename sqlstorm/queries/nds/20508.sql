
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_ship) AS avg_payment,
        ROW_NUMBER() OVER (PARTITION BY CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END ORDER BY SUM(ws.ws_net_profit) DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
        AND ws.ws_sales_price > 0
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_profit DESC) AS overall_rank
    FROM 
        CustomerSales
),
TopCustomers AS (
    SELECT 
        *
    FROM 
        RankedSales
    WHERE 
        overall_rank <= 10 OR total_profit IS NULL
),
StoresSummary AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_net_profit) AS store_profit,
        COUNT(ss.ss_ticket_number) AS total_sales,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_profit,
    ts.s_store_name,
    ts.store_profit,
    COALESCE(ts.total_sales, 0) AS total_store_sales,
    COALESCE(ts.unique_customers, 0) AS unique_store_customers
FROM 
    TopCustomers tc
FULL OUTER JOIN 
    StoresSummary ts ON tc.total_profit = ts.store_profit
WHERE 
    (tc.total_profit > 1000 OR ts.store_profit IS NULL)
    AND (tc.gender_rank < 3 OR ts.total_sales IS NOT NULL)
ORDER BY 
    COALESCE(tc.total_profit, 0) DESC, 
    COALESCE(ts.store_profit, 0) DESC
LIMIT 100;
