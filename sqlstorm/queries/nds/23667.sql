
WITH Sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        SUM(ws_ext_discount_amt) AS total_ext_discount,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank_per_item
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        ws_item_sk
), 
Inventory_check AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM 
        inventory
    WHERE 
        inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    GROUP BY 
        inv_item_sk
),
Customer_segment AS (
    SELECT 
        cd_demo_sk,
        COUNT(c_customer_sk) AS customer_count,
        MAX(cd_credit_rating) AS highest_credit_rating
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE 
        cd_marital_status = 'M' AND cd_gender = 'F'
    GROUP BY 
        cd_demo_sk
),
Return_summary AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_return_quantity) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(sd.total_quantity, 0) AS total_sold,
    COALESCE(sd.total_net_paid, 0) AS total_revenue,
    COALESCE(ic.total_quantity_on_hand, 0) AS quantity_on_hand,
    COALESCE(rs.total_returns, 0) AS total_returns,
    CASE 
        WHEN COALESCE(ic.total_quantity_on_hand, 0) < (COALESCE(sd.total_quantity, 0) / NULLIF(sd.total_quantity, 0)) * 2 THEN 'Restock needed'
        ELSE 'Stock sufficient'
    END AS stock_status,
    cs.customer_count,
    cs.highest_credit_rating
FROM 
    item i
LEFT JOIN 
    Sales_data sd ON i.i_item_sk = sd.ws_item_sk
LEFT JOIN 
    Inventory_check ic ON i.i_item_sk = ic.inv_item_sk
LEFT JOIN 
    Return_summary rs ON i.i_item_sk = rs.sr_item_sk
LEFT JOIN 
    Customer_segment cs ON cs.cd_demo_sk IN (SELECT c_current_cdemo_sk FROM customer WHERE c_current_addr_sk IS NOT NULL)
WHERE 
    i.i_current_price > 0
ORDER BY 
    total_revenue DESC
LIMIT 10;
