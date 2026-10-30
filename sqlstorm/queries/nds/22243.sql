
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number, 
        ws.ws_item_sk, 
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rn,
        COALESCE(ws.ws_quantity, 0) AS quantity,
        COALESCE(ws.ws_ext_discount_amt, 0) AS ext_discount,
        CASE 
            WHEN ws.ws_sales_price > 50 THEN 'Expensive'
            WHEN ws.ws_sales_price BETWEEN 20 AND 50 THEN 'Moderate'
            ELSE 'Cheap'
        END AS price_category
    FROM 
        web_sales ws
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk 
    WHERE 
        c.c_birth_year IS NOT NULL 
        AND (c.c_birth_month IS NULL OR c.c_birth_month BETWEEN 1 AND 6)
),
return_metrics AS (
    SELECT 
        wr.wr_order_number,
        SUM(wr.wr_return_quantity) AS total_returns,
        AVG(wr.wr_return_amt) AS avg_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_order_number
),
final_results AS (
    SELECT 
        r.ws_order_number, 
        r.ws_item_sk,
        r.ws_sales_price,
        r.quantity,
        r.ext_discount,
        r.price_category,
        COALESCE(rt.total_returns, 0) AS total_returns,
        COALESCE(rt.avg_return_amt, 0) AS avg_return_amt
    FROM 
        ranked_sales r
    LEFT JOIN 
        return_metrics rt ON r.ws_order_number = rt.wr_order_number
    WHERE 
        r.rn <= 5
)
SELECT 
    f.ws_order_number, 
    f.ws_item_sk, 
    f.ws_sales_price, 
    f.quantity, 
    f.ext_discount, 
    f.price_category, 
    f.total_returns,
    CASE
        WHEN f.avg_return_amt < f.ws_sales_price THEN 'Lower Return'

        WHEN f.avg_return_amt IS NULL AND f.ws_sales_price > 0 THEN 'No Returns Yet'
        ELSE 'Higher Return'
    END AS return_status
FROM 
    final_results f
ORDER BY 
    f.ws_order_number, 
    f.ws_sales_price DESC;
