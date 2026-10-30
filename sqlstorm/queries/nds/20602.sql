
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(ss.ss_net_paid_inc_tax), 0) AS total_store_sales,
        COALESCE(SUM(ws.ws_net_paid_inc_tax), 0) AS total_web_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transaction_count,
        COUNT(DISTINCT ws.ws_order_number) AS web_transaction_count
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
),
SalesSummary AS (
    SELECT 
        c.c_customer_id AS customer_id,
        CASE 
            WHEN total_store_sales > total_web_sales THEN 'Store'
            WHEN total_web_sales > total_store_sales THEN 'Web'
            ELSE 'Equal'
        END AS sales_channel,
        total_store_sales,
        total_web_sales,
        store_transaction_count,
        web_transaction_count
    FROM CustomerSales c
),
Demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(*) AS demographic_count
    FROM customer_demographics cd
    INNER JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
RankedSales AS (
    SELECT 
        ss.sales_channel,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_credit_rating,
        d.demographic_count,
        RANK() OVER (PARTITION BY ss.sales_channel ORDER BY SUM(ss.total_store_sales + ss.total_web_sales) DESC) AS sales_rank
    FROM SalesSummary ss
    CROSS JOIN Demographics d
    GROUP BY ss.sales_channel, d.cd_gender, d.cd_marital_status, d.cd_credit_rating, d.demographic_count
)
SELECT 
    sales_channel,
    cd_gender,
    cd_marital_status,
    cd_credit_rating,
    demographic_count,
    sales_rank
FROM RankedSales
WHERE sales_rank <= 10
ORDER BY sales_channel, sales_rank;
