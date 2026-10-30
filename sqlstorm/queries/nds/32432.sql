
WITH  SalesCTE AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
CustomerPurchaseStats AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_spent,
        MAX(ws_sold_date_sk) AS last_purchase_date
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk
),
HighValueCustomers AS (
    SELECT
        cps.c_customer_sk,
        cps.total_orders,
        cps.total_spent,
        cps.last_purchase_date,
        ROW_NUMBER() OVER (ORDER BY cps.total_spent DESC) AS customer_rank
    FROM
        CustomerPurchaseStats cps
    WHERE
        cps.total_spent IS NOT NULL
        AND cps.total_spent > (SELECT AVG(total_spent) FROM CustomerPurchaseStats)
),
ItemReturns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned
    FROM
        store_returns
    GROUP BY
        sr_item_sk
)

SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(SUM(ws.ws_quantity), 0) AS total_sold,
    COALESCE(ir.total_returned, 0) AS total_returned,
    COALESCE(SUM(ws.ws_quantity) - COALESCE(ir.total_returned, 0), 0) AS net_sales,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers
FROM 
    item i
LEFT JOIN 
    web_sales ws ON i.i_item_sk = ws.ws_item_sk
LEFT JOIN 
    ItemReturns ir ON i.i_item_sk = ir.sr_item_sk
LEFT JOIN 
    HighValueCustomers hvc ON ws.ws_bill_customer_sk = hvc.c_customer_sk
LEFT JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE 
    i.i_current_price > 20.00
    AND (hvc.customer_rank IS NULL OR hvc.customer_rank <= 100)
GROUP BY 
    i.i_item_sk, i.i_item_id, i.i_item_desc, ir.total_returned
ORDER BY 
    net_sales DESC
LIMIT 10;
