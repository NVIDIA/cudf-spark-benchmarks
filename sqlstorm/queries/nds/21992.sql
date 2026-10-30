
WITH CustomerReturns AS (
    SELECT 
        sr_return_quantity,
        sr_return_amt,
        sr_return_tax,
        sr_return_amt_inc_tax,
        sr_store_sk,
        sr_item_sk,
        ROW_NUMBER() OVER (PARTITION BY sr_store_sk ORDER BY sr_return_amt DESC) AS rn
    FROM store_returns
    WHERE sr_return_quantity IS NOT NULL
),
TopStores AS (
    SELECT 
        sr_store_sk, 
        SUM(sr_return_amt) AS total_return_amt
    FROM CustomerReturns
    WHERE rn <= 5
    GROUP BY sr_store_sk
    HAVING SUM(sr_return_amt) > (SELECT AVG(sr_return_amt) FROM CustomerReturns)
),
ItemsWithDiscount AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales_price,
        SUM(ws_coupon_amt) AS total_discount
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY ws_item_sk
),
FinalReport AS (
    SELECT 
        s.s_store_name,
        i.i_item_desc,
        COALESCE(t.total_return_amt, 0) AS total_returns,
        COALESCE(id.total_sales_price, 0) AS total_sales,
        COALESCE(id.total_discount, 0) AS total_discount,
        CASE 
            WHEN COALESCE(t.total_return_amt, 0) > 0 THEN 
                100.0 * COALESCE(id.total_discount, 0) / NULLIF(COALESCE(id.total_sales_price, 0), 0)
            ELSE 0
        END AS discount_percentage
    FROM store s
    LEFT JOIN TopStores t ON s.s_store_sk = t.sr_store_sk
    JOIN item i ON i.i_item_sk IN (SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand > 0)
    LEFT JOIN ItemsWithDiscount id ON i.i_item_sk = id.ws_item_sk
    WHERE s.s_country = 'USA'
)
SELECT 
    f.s_store_name,
    f.i_item_desc,
    f.total_returns,
    f.total_sales,
    f.total_discount,
    CASE 
        WHEN f.total_sales > 0 THEN 'Sales Above Zero'
        ELSE 'No Sales'
    END AS sales_status,
    COALESCE(f.discount_percentage, 0) AS calculated_discount_percentage,
    RANK() OVER (ORDER BY f.total_sales DESC) AS sales_rank
FROM FinalReport f
WHERE f.discount_percentage IS NOT NULL
ORDER BY f.discount_percentage DESC, f.total_sales DESC
LIMIT 10;
