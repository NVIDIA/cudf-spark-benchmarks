
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        DENSE_RANK() OVER (ORDER BY SUM(ws_sales_price * ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_sales,
        sd.total_orders,
        ci.i_item_desc,
        ci.i_current_price,
        ci.i_category AS item_category,
        ROW_NUMBER() OVER (PARTITION BY ci.i_category ORDER BY sd.total_sales DESC) AS category_rank
    FROM 
        SalesData sd
    INNER JOIN 
        item ci ON sd.ws_item_sk = ci.i_item_sk
    WHERE 
        sd.sales_rank <= 100
),
Returns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_amt) AS total_return_amount,
        COUNT(wr_order_number) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
)
SELECT 
    ti.ws_item_sk,
    ti.i_item_desc,
    ti.item_category,
    ti.total_sales,
    ti.total_orders,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_returns, 0) AS total_returns,
    (ti.total_sales - COALESCE(r.total_return_amount, 0)) AS net_sales,
    CASE 
        WHEN ti.total_orders > 0 THEN (ti.total_sales - COALESCE(r.total_return_amount, 0)) / ti.total_orders
        ELSE NULL 
    END AS avg_sales_per_order
FROM 
    TopItems ti
LEFT JOIN 
    Returns r ON ti.ws_item_sk = r.wr_item_sk
WHERE 
    ti.category_rank <= 10
ORDER BY 
    net_sales DESC;
