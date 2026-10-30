
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231
),
TotalReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
ButterflyEffect AS (
    SELECT 
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(COALESCE(cu.cd_purchase_estimate, 0)) AS total_estimated_spending,
        AVG(COALESCE(cu.cd_dep_count, 0)) AS avg_dependents
    FROM customer_address ca
    JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cu ON c.c_current_cdemo_sk = cu.cd_demo_sk
    WHERE 
        ca.ca_state IN ('CA', 'NY') 
        AND (cu.cd_marital_status = 'M' OR cu.cd_gender = 'F')
    GROUP BY 
        ca.ca_city
),
FinalResults AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_quantity,
        r.ws_sales_price,
        r.ws_net_profit,
        tr.total_returns,
        tr.total_return_amount,
        b.ca_city AS city,
        b.customer_count,
        b.total_estimated_spending,
        b.avg_dependents
    FROM 
        RankedSales r
    LEFT JOIN TotalReturns tr ON r.ws_item_sk = tr.cr_item_sk
    JOIN ButterflyEffect b ON r.ws_item_sk IN (SELECT i.i_item_sk FROM item i WHERE i.i_category = 'Electronics') 
    WHERE 
        r.profit_rank = 1
)
SELECT 
    f.ws_item_sk,
    f.ws_order_number,
    f.ws_quantity,
    f.ws_sales_price,
    f.ws_net_profit,
    COALESCE(f.total_returns, 0) AS total_returns,
    COALESCE(f.total_return_amount, 0) AS total_return_amount,
    f.city,
    f.customer_count,
    f.total_estimated_spending,
    f.avg_dependents
FROM 
    FinalResults f
WHERE 
    f.ws_net_profit > 1000
ORDER BY 
    f.ws_net_profit DESC;
