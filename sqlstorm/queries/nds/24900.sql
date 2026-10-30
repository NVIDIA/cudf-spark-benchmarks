WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS RankPrice,
        RANK() OVER (PARTITION BY ws.ws_ship_mode_sk ORDER BY ws.ws_net_profit DESC) AS RankProfit,
        COALESCE(ws.ws_net_paid_inc_ship_tax, 0) AS TotalPaid
    FROM 
        web_sales ws
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status IS NOT NULL
        AND (cd.cd_gender = 'M' OR cd.cd_gender IS NULL)
),
HighProfitItems AS (
    SELECT 
        ws_item_sk, 
        COUNT(*) AS SalesCount
    FROM 
        RankedSales 
    WHERE 
        RankProfit <= 5
    GROUP BY 
        ws_item_sk
),
SignificantReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS TotalReturns,
        SUM(sr_return_amt_inc_tax) AS TotalReturnAmount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
    HAVING 
        SUM(sr_return_quantity) > 10
)
SELECT 
    i.i_item_id,
    COALESCE(h.SalesCount, 0) AS SalesCount,
    COALESCE(s.TotalReturns, 0) AS TotalReturns,
    COALESCE(s.TotalReturnAmount, 0) AS TotalReturnAmount,
    (COALESCE(h.SalesCount, 0) - COALESCE(s.TotalReturns, 0)) AS NetSales,
    CASE 
        WHEN (COALESCE(h.SalesCount, 0) - COALESCE(s.TotalReturns, 0)) > 100 THEN 'High Performer'
        WHEN (COALESCE(h.SalesCount, 0) - COALESCE(s.TotalReturns, 0)) BETWEEN 50 AND 100 THEN 'Medium Performer'
        ELSE 'Low Performer' 
    END AS PerformanceCategory
FROM 
    item i
LEFT JOIN 
    HighProfitItems h ON i.i_item_sk = h.ws_item_sk
LEFT JOIN 
    SignificantReturns s ON i.i_item_sk = s.sr_item_sk
WHERE 
    i.i_current_price IS NOT NULL
    AND i.i_rec_start_date <= cast('2002-10-01' as date)
    AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date >= cast('2002-10-01' as date))
ORDER BY 
    NetSales DESC,
    PerformanceCategory ASC
LIMIT 50 OFFSET 0;