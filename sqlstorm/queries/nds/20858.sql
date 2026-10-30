
WITH SalesData AS (
    SELECT 
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_sales_price,
        SUM(ss.ss_net_profit) OVER (PARTITION BY ss.ss_item_sk ORDER BY ss.ss_sold_date_sk) AS cumulative_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_item_sk ORDER BY ss.ss_sold_date_sk DESC) AS rank
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2021) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2021)
),
ReturnData AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_item_sk
),
FilteredSales AS (
    SELECT 
        sd.ss_item_sk,
        sd.ss_quantity,
        sd.cumulative_net_profit,
        rd.total_returns,
        rd.total_return_amount,
        CASE 
            WHEN rd.total_returns IS NULL THEN 'No Returns'
            WHEN rd.total_returns > 0 AND sd.ss_quantity > 10 THEN 'High Quantity with Returns'
            ELSE 'Normal Sales'
        END AS sales_status
    FROM 
        SalesData sd
    LEFT JOIN 
        ReturnData rd ON sd.ss_item_sk = rd.sr_item_sk
    WHERE 
        sd.rank <= 5
)
SELECT 
    f.ss_item_sk,
    f.ss_quantity,
    f.cumulative_net_profit,
    COALESCE(f.total_returns, 0) AS total_returns,
    COALESCE(f.total_return_amount, 0.00) AS total_return_amount,
    f.sales_status
FROM 
    FilteredSales f
ORDER BY 
    f.cumulative_net_profit DESC, 
    f.ss_item_sk;
