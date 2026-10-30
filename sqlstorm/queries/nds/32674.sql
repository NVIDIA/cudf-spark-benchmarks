
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales 
    GROUP BY 
        ws_sold_date_sk
    HAVING 
        SUM(ws_net_profit) > 10000
), 
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
    HAVING 
        AVG(ws.ws_sales_price) > 50
), 
HighIncomeCustomers AS (
    SELECT
        h.hd_demo_sk,
        h.hd_income_band_sk,
        CASE 
            WHEN ib.ib_lower_bound IS NULL THEN 'Unknown'
            ELSE CONCAT('$', ib.ib_lower_bound, ' - $', ib.ib_upper_bound)
        END AS income_band
    FROM 
        household_demographics h
    LEFT JOIN 
        income_band ib ON h.hd_income_band_sk = ib.ib_income_band_sk
), 
ReturnStats AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), 
FinalStats AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_profit,
        cs.total_orders,
        rs.total_returns,
        rs.total_return_amount,
        CASE 
            WHEN rs.total_returns IS NULL THEN 'No Returns'
            ELSE 'Has Returns'
        END AS return_status
    FROM 
        CustomerStats cs
    LEFT JOIN 
        ReturnStats rs ON cs.c_customer_sk = rs.sr_customer_sk
)

SELECT 
    f.c_customer_sk,
    f.total_profit,
    f.total_orders,
    f.total_returns,
    f.total_return_amount,
    f.return_status,
    s.total_net_profit AS highest_profit
FROM 
    FinalStats f
JOIN 
    SalesCTE s ON f.total_profit = s.total_net_profit
ORDER BY 
    f.total_profit DESC, f.total_orders ASC;
