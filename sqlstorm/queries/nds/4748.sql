
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 1 AND 1000
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE cs.total_sales IS NOT NULL
),
StoreSalesSummary AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 1 AND 1000
    GROUP BY ss.ss_store_sk
),
HighPerformingStores AS (
    SELECT 
        st.s_store_sk,
        st.s_store_name,
        sss.total_store_sales,
        sss.total_transactions,
        RANK() OVER (ORDER BY sss.total_store_sales DESC) AS store_rank
    FROM store st
    JOIN StoreSalesSummary sss ON st.s_store_sk = sss.ss_store_sk
    WHERE sss.total_store_sales IS NOT NULL
),
SalesAnalysis AS (
    SELECT 
        tc.c_first_name,
        tc.c_last_name,
        hs.s_store_name,
        hs.total_store_sales,
        tc.total_sales,
        tc.order_count,
        CASE 
            WHEN tc.total_sales > hs.total_store_sales THEN 'Higher Sales'
            WHEN tc.total_sales < hs.total_store_sales THEN 'Lower Sales'
            ELSE 'Equal Sales'
        END AS sales_comparison
    FROM TopCustomers tc
    FULL OUTER JOIN HighPerformingStores hs ON tc.sales_rank = hs.store_rank
    WHERE tc.total_sales IS NOT NULL OR hs.total_store_sales IS NOT NULL
)
SELECT 
    sa.c_first_name,
    sa.c_last_name,
    sa.s_store_name,
    sa.total_sales,
    sa.total_store_sales,
    sa.sales_comparison
FROM SalesAnalysis sa
WHERE sa.sales_comparison IS NOT NULL
ORDER BY sa.total_sales DESC, sa.total_store_sales DESC;
