
WITH SalesSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid_inc_tax) AS total_spent,
        COUNT(ss.ss_ticket_number) AS total_transactions,
        DENSE_RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(ss.ss_net_paid_inc_tax) DESC) AS spending_rank
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
),
TopCustomers AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        total_spent, 
        total_transactions
    FROM 
        SalesSummary
    WHERE 
        spending_rank <= 10
),
StorePerformance AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        COUNT(ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_sales_price) AS avg_item_price
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name
),
CustomerStorePerformance AS (
    SELECT 
        t.c_customer_sk,
        t.c_first_name,
        t.c_last_name,
        sp.s_store_sk,
        sp.s_store_name,
        COUNT(ss.ss_ticket_number) AS transactions_from_store,
        SUM(ss.ss_net_profit) AS profits_from_store
    FROM 
        TopCustomers t
    JOIN 
        store_sales ss ON t.c_customer_sk = ss.ss_customer_sk
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    JOIN 
        StorePerformance sp ON s.s_store_sk = sp.s_store_sk
    GROUP BY 
        t.c_customer_sk, t.c_first_name, t.c_last_name, sp.s_store_sk, sp.s_store_name
)
SELECT 
    uv.c_first_name,
    uv.c_last_name,
    s.s_store_name,
    uv.total_spent,
    uv.total_transactions,
    sp.total_sales,
    sp.total_profit,
    sp.avg_item_price,
    cp.transactions_from_store,
    cp.profits_from_store
FROM 
    TopCustomers uv
JOIN 
    CustomerStorePerformance cp ON uv.c_customer_sk = cp.c_customer_sk
JOIN 
    StorePerformance sp ON cp.s_store_sk = sp.s_store_sk
JOIN 
    store s ON cp.s_store_sk = s.s_store_sk
ORDER BY 
    uv.total_spent DESC, sp.total_profit DESC;
