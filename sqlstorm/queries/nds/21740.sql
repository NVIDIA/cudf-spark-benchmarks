
WITH  demographic_info AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count,
        ROW_NUMBER() OVER(PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS rn
    FROM 
        customer_demographics
), 
sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        demographic_info di ON ws.ws_bill_cdemo_sk = di.cd_demo_sk
    WHERE 
        di.rn <= 5 AND 
        di.cd_purchase_estimate > 1000
    GROUP BY 
        ws.ws_item_sk
),
return_summary AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
), 
inventory_info AS (
    SELECT 
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        COALESCE(rs.total_returns, 0) AS total_returns,
        SUM(ss.total_quantity_sold) OVER (PARTITION BY inv.inv_item_sk) AS total_sold
    FROM 
        inventory inv
    LEFT JOIN 
        return_summary rs ON inv.inv_item_sk = rs.sr_item_sk
    LEFT JOIN 
        sales_summary ss ON inv.inv_item_sk = ss.ws_item_sk
)
SELECT 
    ii.inv_item_sk,
    ii.inv_quantity_on_hand,
    ii.total_sold,
    ii.total_returns,
    CASE 
        WHEN ii.inv_quantity_on_hand IS NULL THEN 'OUT OF STOCK'
        WHEN ii.inv_quantity_on_hand < (ii.total_sold - ii.total_returns) THEN 'LOW STOCK'
        ELSE 'IN STOCK'
    END AS stock_status,
    CONCAT(
        'Item ', ii.inv_item_sk, ' has ', 
        ii.inv_quantity_on_hand, ' units available: ', 
        CASE 
            WHEN ii.inv_quantity_on_hand = 0 THEN 'Non-available!'
            ELSE 'Available for purchase.'
        END
    ) AS availability_details
FROM 
    inventory_info ii
WHERE 
    ii.inv_quantity_on_hand IS NOT NULL
ORDER BY 
    ii.inv_item_sk;
