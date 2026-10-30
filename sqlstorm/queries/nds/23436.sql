
WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        ss_sold_date_sk,
        ss_quantity,
        ss_net_profit,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY ss_net_profit DESC) AS profit_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
ReturnCounts AS (
    SELECT 
        sr_store_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
),
SalesWithReturns AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_profit) AS total_profit,
        COALESCE(rc.total_returns, 0) AS return_count,
        CASE 
            WHEN COALESCE(rc.total_returns, 0) = 0 THEN 'No Returns' 
            ELSE 'Returns Present' 
        END AS return_status
    FROM 
        RankedSales ss
    LEFT JOIN 
        ReturnCounts rc ON ss.ss_store_sk = rc.sr_store_sk
    GROUP BY 
        ss.ss_store_sk, rc.total_returns
)
SELECT 
    swr.ss_store_sk,
    swr.total_profit,
    swr.return_count,
    swr.return_status,
    CASE 
        WHEN swr.total_profit IS NULL THEN 'Profit Data Missing' 
        ELSE 'Profit Data Available' 
    END AS profit_data_status,
    (SELECT 
        COUNT(DISTINCT cd_demo_sk) 
     FROM 
        customer_demographics 
     WHERE 
        cd_marital_status = 'S' 
        AND cd_credit_rating IN ('Good', 'Excellent') 
        AND cd_purchase_estimate > (
            SELECT AVG(cd_purchase_estimate) FROM customer_demographics
        )
    ) AS single_good_customers_count
FROM 
    SalesWithReturns swr
ORDER BY 
    swr.total_profit DESC
LIMIT 10;
