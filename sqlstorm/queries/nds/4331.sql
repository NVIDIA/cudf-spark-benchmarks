
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450000 AND 2450500
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
),
FinalReport AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        SUM(rs.ws_sales_price) AS total_sales,
        SUM(tc.total_returns) AS total_customer_returns,
        CASE 
            WHEN SUM(rs.ws_net_profit) IS NULL THEN 0
            ELSE SUM(rs.ws_net_profit) 
        END AS net_profit
    FROM 
        TopCustomers tc
    LEFT JOIN 
        web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        RankedSales rs ON ws.ws_item_sk = rs.ws_item_sk AND rs.profit_rank = 1
    GROUP BY 
        tc.c_customer_sk, tc.c_first_name, tc.c_last_name
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.total_sales,
    f.total_customer_returns,
    f.net_profit,
    CASE 
        WHEN f.net_profit > 1000 THEN 'High Profit'
        WHEN f.net_profit > 100 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    FinalReport f
WHERE 
    f.total_sales > (SELECT AVG(total_sales) FROM FinalReport)
ORDER BY 
    f.net_profit DESC;
