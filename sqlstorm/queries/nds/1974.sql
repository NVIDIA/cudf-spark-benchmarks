
WITH CustomerReturns AS (
    SELECT
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt_inc_tax) AS total_returned_amount,
        COUNT(DISTINCT wr_order_number) AS total_returns
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
TopCustomers AS (
    SELECT
        cr.wr_returning_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate BETWEEN 0 AND 5000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 5001 AND 15000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_estimate_band,
        cr.total_returned_quantity,
        cr.total_returned_amount,
        cr.total_returns
    FROM CustomerReturns cr
    JOIN customer c ON cr.wr_returning_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cr.total_returned_quantity > 10
),
TopPromotions AS (
    SELECT
        ws.ws_promo_sk,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN TopCustomers tc ON ws.ws_bill_customer_sk = tc.wr_returning_customer_sk
    GROUP BY ws.ws_promo_sk
    HAVING SUM(ws.ws_net_profit) > 10000
),
SalesData AS (
    SELECT
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_sales_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales_value
    FROM catalog_sales cs
    JOIN TopPromotions tp ON cs.cs_promo_sk = tp.ws_promo_sk
    GROUP BY cs.cs_item_sk
),
RankedSales AS (
    SELECT
        sd.cs_item_sk,
        sd.total_sales_quantity,
        sd.total_sales_value,
        RANK() OVER (ORDER BY sd.total_sales_value DESC) AS sales_rank
    FROM SalesData sd
)
SELECT
    r.cs_item_sk,
    r.total_sales_quantity,
    r.total_sales_value,
    r.sales_rank,
    COALESCE(i.i_product_name, 'Unknown') AS product_name,
    COALESCE(i.i_current_price, 0) AS current_price
FROM RankedSales r
LEFT JOIN item i ON r.cs_item_sk = i.i_item_sk
WHERE r.sales_rank <= 10
ORDER BY r.sales_rank;
