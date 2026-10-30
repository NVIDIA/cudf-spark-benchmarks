
WITH CustomerOrderSummary AS (
    SELECT
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_paid_inc_tax
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
        AND cd.cd_gender = 'F'
        AND (cd.cd_purchase_estimate IS NULL OR cd.cd_purchase_estimate > 1000)
    GROUP BY c.c_customer_id
),
TopStores AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_net_profit) AS total_store_profit,
        ROW_NUMBER() OVER (ORDER BY SUM(ss.ss_net_profit) DESC) AS store_rank
    FROM store s
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_id
    HAVING SUM(ss.ss_net_profit) > 0
),
ProductReturns AS (
    SELECT
        ir.item_returned_sk,
        SUM(ir.return_quantity) AS total_return_quantity,
        SUM(ir.return_amount) AS total_return_amount
    FROM (
        SELECT 
            cr.cr_item_sk AS item_returned_sk,
            cr.cr_return_quantity AS return_quantity,
            cr.cr_return_amount AS return_amount
        FROM catalog_returns cr
        WHERE cr.cr_return_quantity IS NOT NULL
        UNION ALL
        SELECT 
            wr.wr_item_sk AS item_returned_sk,
            wr.wr_return_quantity AS return_quantity,
            wr.wr_return_amt AS return_amount
        FROM web_returns wr
        WHERE wr.wr_return_quantity IS NOT NULL
    ) ir
    GROUP BY ir.item_returned_sk
),
ProductPerformance AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_sales_price) AS total_sales_value,
        COALESCE(NULLIF(SUM(pr.total_return_quantity), 0), 1) AS total_return_quantity,
        SUM(ws.ws_quantity) / NULLIF(SUM(pr.total_return_quantity), 0) AS sales_to_return_ratio
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN ProductReturns pr ON i.i_item_sk = pr.item_returned_sk
    GROUP BY i.i_item_id, i.i_product_name
)
SELECT 
    cos.c_customer_id,
    ts.s_store_id,
    pp.i_item_id,
    pp.total_sales_quantity,
    pp.total_sales_value,
    pp.sales_to_return_ratio,
    CASE 
        WHEN pp.sales_to_return_ratio > 10 THEN 'Excellent'
        WHEN pp.sales_to_return_ratio BETWEEN 5 AND 10 THEN 'Good'
        ELSE 'Needs Improvement'
    END AS performance_category
FROM CustomerOrderSummary cos
JOIN TopStores ts ON ts.store_rank <= 10
JOIN ProductPerformance pp ON pp.total_sales_quantity > 100
WHERE cos.total_net_profit > 10000
ORDER BY cos.total_orders DESC, ts.total_store_profit DESC;
