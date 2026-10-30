
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM web_sales
),
AggregatedReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        COUNT(DISTINCT wr_returning_customer_sk) AS unique_returning_customers
    FROM web_returns
    GROUP BY wr_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_buy_potential,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        COALESCE(SUM(sr.sr_return_amt), 0) AS total_returns
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name,
        cd.cd_gender, cd.cd_marital_status, hd.hd_buy_potential
),
TopProducts AS (
    SELECT 
        r.wr_item_sk,
        r.total_returns,
        p.i_product_name,
        RANK() OVER (ORDER BY r.total_returns DESC) AS return_rank
    FROM AggregatedReturns r
    JOIN item p ON r.wr_item_sk = p.i_item_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.hd_buy_potential,
    COALESCE(rs.ws_quantity, 0) AS total_items_purchased,
    COALESCE(ROUND((cs.total_profit - cs.total_returns) / NULLIF(cs.total_profit, 0) * 100, 2), 0) AS profit_loss_ratio,
    tp.i_product_name,
    tp.total_returns AS returns_of_top_product
FROM CustomerStats cs
LEFT JOIN RankedSales rs ON cs.c_customer_sk = rs.ws_item_sk
LEFT JOIN TopProducts tp ON tp.return_rank = 1
WHERE 
    (cs.total_profit > 1000 OR cs.hd_buy_potential IS NOT NULL)
    AND (cs.cd_gender IS NULL OR cs.cd_gender = 'F')
ORDER BY profit_loss_ratio DESC, total_items_purchased DESC;
