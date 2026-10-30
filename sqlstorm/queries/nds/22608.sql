
WITH RecursiveSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS total_quantity,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS net_profit_moving_avg,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk IS NOT NULL
),
AddressCounts AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT ca.ca_address_sk) AS address_count
    FROM customer_address ca
    GROUP BY ca.ca_state
    HAVING COUNT(DISTINCT ca.ca_address_sk) > 5
),
SelectedItems AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_current_price,
        i.i_item_desc,
        CASE 
            WHEN i.i_current_price > 50 THEN 'Expensive'
            WHEN i.i_current_price BETWEEN 20 AND 50 THEN 'Moderate'
            ELSE 'Cheap'
        END AS price_category
    FROM item i
    WHERE i.i_current_price IS NOT NULL
),
Returns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM store_returns sr
    GROUP BY sr.sr_item_sk
),
CombinedData AS (
    SELECT 
        si.i_item_sk,
        si.i_item_id,
        si.price_category,
        COALESCE(rs.total_quantity, 0) AS total_sales_quantity,
        COALESCE(rs.net_profit_moving_avg, 0) AS avg_net_profit,
        COALESCE(r.total_returns, 0) AS returns,
        CASE 
            WHEN r.total_return_amount > 1000 THEN 'High Returns'
            WHEN r.total_return_amount BETWEEN 100 AND 1000 THEN 'Moderate Returns'
            ELSE 'Low Returns'
        END AS return_category
    FROM SelectedItems si
    LEFT JOIN RecursiveSales rs ON si.i_item_sk = rs.ws_item_sk AND rs.rn = 1
    LEFT JOIN Returns r ON si.i_item_sk = r.sr_item_sk
),
FinalSelection AS (
    SELECT 
        ac.ca_state,
        cd.i_item_id,
        cd.price_category,
        SUM(cd.total_sales_quantity) AS total_sales,
        AVG(cd.avg_net_profit) AS avg_net_profit,
        SUM(cd.returns) AS total_returns,
        MAX(cd.return_category) AS highest_return_category
    FROM CombinedData cd
    INNER JOIN AddressCounts ac ON ac.address_count > 10 
    GROUP BY ac.ca_state, cd.i_item_id, cd.price_category
)
SELECT 
    fs.ca_state,
    fs.i_item_id,
    fs.price_category,
    fs.total_sales,
    fs.avg_net_profit,
    fs.total_returns,
    fs.highest_return_category
FROM FinalSelection fs
WHERE fs.total_sales > (SELECT AVG(total_sales) FROM FinalSelection)
ORDER BY fs.total_sales DESC;
