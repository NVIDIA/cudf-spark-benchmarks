WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(sr_return_quantity), 0) AS total_store_returns,
        COALESCE(SUM(wr_return_quantity), 0) AS total_web_returns
    FROM 
        customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
PromotionalSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_web_profit,
        SUM(cs_net_profit) AS total_catalog_profit
    FROM 
        web_sales ws
    JOIN catalog_sales cs ON ws.ws_order_number = cs.cs_order_number AND ws.ws_item_sk = cs.cs_item_sk
    WHERE 
        ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2001)
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_credit_rating = 'Good' THEN 'High'
            WHEN cd.cd_credit_rating = 'Bad' THEN 'Low'
            ELSE 'Medium'
        END AS credit_tier
    FROM 
        customer_demographics cd
)

SELECT 
    cr.c_first_name,
    cr.c_last_name,
    cr.total_store_returns,
    cr.total_web_returns,
    COALESCE(ps.total_web_profit, 0) AS total_web_profit,
    COALESCE(ps.total_catalog_profit, 0) AS total_catalog_profit,
    cd.cd_gender,
    cd.credit_tier
FROM 
    CustomerReturns cr
JOIN 
    PromotionalSales ps ON cr.c_customer_sk = ps.ws_bill_customer_sk
JOIN 
    CustomerDemographics cd ON cr.c_customer_sk = cd.cd_demo_sk
WHERE 
    (cr.total_store_returns + cr.total_web_returns) > (
        SELECT AVG(total_store_returns + total_web_returns) 
        FROM CustomerReturns 
        WHERE total_store_returns IS NOT NULL OR total_web_returns IS NOT NULL
    )
AND 
    (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
ORDER BY 
    total_web_profit DESC
LIMIT 100;