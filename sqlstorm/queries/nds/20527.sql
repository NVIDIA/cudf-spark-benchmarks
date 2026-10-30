
WITH RankedItems AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY i.i_current_price DESC) AS price_rank,
        AVG(ws.ws_net_profit) OVER (PARTITION BY i.i_category) AS avg_category_profit
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        i.i_rec_end_date IS NULL 
        AND (ws.ws_net_profit > 0 OR ws.ws_net_profit IS NULL)
), 
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
), 
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        CASE 
            WHEN cd_marital_status = 'M' THEN 'Married'
            ELSE 'Single'
        END AS marital_status,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status
), 
SalesAnalysis AS (
    SELECT 
        i.i_item_sk,
        SUM(s.ws_quantity) AS total_sold_quantity,
        SUM(s.ws_net_profit) AS total_net_profit
    FROM 
        web_sales s
    JOIN 
        item i ON s.ws_item_sk = i.i_item_sk
    WHERE 
        s.ws_sold_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        i.i_item_sk
)
SELECT 
    r.i_item_sk,
    r.i_item_id,
    r.i_item_desc,
    r.price_rank,
    r.avg_category_profit,
    COALESCE(cr.return_count, 0) AS return_count,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    cd.marital_status,
    cd.customer_count,
    sa.total_sold_quantity,
    sa.total_net_profit,
    CASE 
        WHEN sa.total_net_profit IS NULL THEN 'No Sales'
        WHEN sa.total_net_profit < r.avg_category_profit THEN 'Below Average'
        ELSE 'Above Average'
    END AS performance_category
FROM 
    RankedItems r
LEFT JOIN 
    CustomerReturns cr ON r.i_item_sk = cr.sr_item_sk
LEFT JOIN 
    CustomerDemographics cd ON cd.cd_demo_sk = r.i_item_sk  
LEFT JOIN 
    SalesAnalysis sa ON r.i_item_sk = sa.i_item_sk
WHERE 
    r.price_rank <= 5 
    AND (r.avg_category_profit IS NOT NULL OR sa.total_net_profit IS NULL)
ORDER BY 
    r.avg_category_profit DESC, 
    r.i_item_id ASC;
