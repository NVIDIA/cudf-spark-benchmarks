
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        ws_item_sk,
        total_orders,
        total_sales
    FROM 
        SalesCTE
    WHERE 
        rank <= 10
),
Returns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returns,
        SUM(cr_return_amount) AS total_return_amt
    FROM 
        catalog_returns
    WHERE 
        cr_order_number IS NOT NULL
    GROUP BY 
        cr_item_sk
),
ItemReturns AS (
    SELECT 
        ti.ws_item_sk,
        ti.total_orders,
        ti.total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.total_return_amt, 0) AS total_return_amt,
        CASE 
            WHEN COALESCE(r.total_return_amt, 0) > ti.total_sales THEN 'High Return Risk'
            ELSE 'Normal'
        END AS return_risk
    FROM 
        TopItems ti
    LEFT JOIN 
        Returns r ON ti.ws_item_sk = r.cr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ir.total_orders,
    ir.total_sales,
    ir.total_returns,
    ir.total_return_amt,
    ir.return_risk,
    (ir.total_sales - ir.total_return_amt) AS net_sales,
    CASE 
        WHEN ir.total_returns > 0 THEN ir.total_returns / ir.total_orders 
        ELSE 0 
    END AS return_rate
FROM 
    item i
JOIN 
    ItemReturns ir ON i.i_item_sk = ir.ws_item_sk
WHERE 
    i.i_current_price > (SELECT AVG(i_current_price) FROM item) 
ORDER BY 
    return_rate DESC
LIMIT 20
OFFSET 5;
