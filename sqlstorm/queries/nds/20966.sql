
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS sales_rank,
        DENSE_RANK() OVER (ORDER BY ws_sales_price ASC) AS price_rank,
        SUM(ws_net_profit) OVER (PARTITION BY ws_item_sk) AS total_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL 
        AND ws_sales_price > 0
        AND ws_net_profit IS NOT NULL
),
CustomerWithDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate IS NOT NULL THEN cd.cd_purchase_estimate
            ELSE 0 
        END AS purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ReturnsSummary AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    cs.cs_item_sk,
    cs.cs_sales_price AS catalog_sales_price,
    ws.ws_sales_price AS web_sales_price,
    ws.total_net_profit,
    cd.cd_gender,
    cd.purchase_estimate,
    COALESCE(rs.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(rs.total_return_amt, 0) AS total_return_amt,
    ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_ext_sales_price DESC) AS item_rank
FROM
    catalog_sales cs
LEFT JOIN 
    RankedSales ws ON cs.cs_item_sk = ws.ws_item_sk AND ws.sales_rank = 1
LEFT JOIN 
    CustomerWithDemographics cd ON cs.cs_bill_customer_sk = cd.c_customer_sk
LEFT JOIN 
    ReturnsSummary rs ON cs.cs_item_sk = rs.sr_item_sk
WHERE 
    (ws.ws_sales_price IS NULL OR ws.ws_sales_price > 100)
    AND (cd.purchase_estimate BETWEEN 1000 AND 5000 OR cd.purchase_estimate IS NULL)
ORDER BY 
    cs.cs_item_sk, cd.cd_gender DESC, ws.total_net_profit DESC;
