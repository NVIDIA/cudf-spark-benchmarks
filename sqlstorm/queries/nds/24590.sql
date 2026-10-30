
WITH  CustomerSpend AS (
    SELECT c.c_customer_sk, 
           SUM(ws.ws_net_paid) AS total_spent, 
           DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS spend_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_ship_date_sk IS NOT NULL
    GROUP BY c.c_customer_sk
),
MaxSpent AS (
    SELECT MAX(total_spent) AS max_spent FROM CustomerSpend 
),
FilteredCustomers AS (
    SELECT cs.c_customer_sk, cs.total_spent
    FROM CustomerSpend cs 
    JOIN MaxSpent ms ON cs.total_spent >= ms.max_spent * 0.5
    WHERE cs.spend_rank <= 10
),
SalesSummary AS (
    SELECT ws.ws_ship_date_sk, 
           COUNT(DISTINCT ws.ws_order_number) AS order_count,
           SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    GROUP BY ws.ws_ship_date_sk
),
DateRange AS (
    SELECT d_date_sk, d_date
    FROM date_dim 
    WHERE d_date BETWEEN '2023-01-01' AND '2023-12-31'
),
Recovery AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_net_paid_inc_tax) AS total_revenue, 
           warehouse.w_warehouse_name
    FROM web_sales ws 
    JOIN warehouse ON ws.ws_warehouse_sk = warehouse.w_warehouse_sk
    GROUP BY ws.ws_item_sk, warehouse.w_warehouse_name
    HAVING SUM(ws.ws_net_paid_inc_tax) IS NOT NULL
),
AggregateReturns AS (
    SELECT sr_reason_sk,
           COUNT(*) AS total_returns, 
           SUM(sr_return_amt_inc_tax) AS total_returned,
           SUM(sr_return_quantity) AS total_quantity
    FROM store_returns 
    WHERE sr_returned_date_sk BETWEEN 
          (SELECT MIN(d_date_sk) FROM DateRange) AND 
          (SELECT MAX(d_date_sk) FROM DateRange)
    GROUP BY sr_reason_sk
)
SELECT fc.c_customer_sk,
       fc.total_spent,
       ss.order_count,
       ss.total_sales,
       ar.total_returns,
       ar.total_returned,
       ar.total_quantity,
       COALESCE(r.r_reason_desc, 'No reason') AS return_reason
FROM FilteredCustomers fc
LEFT JOIN SalesSummary ss ON ss.ws_ship_date_sk IN 
                             (SELECT d_date_sk FROM DateRange)
LEFT JOIN AggregateReturns ar ON ar.sr_reason_sk = 
                                 (SELECT MIN(sr_reason_sk) FROM AggregateReturns)
LEFT JOIN reason r ON ar.sr_reason_sk = r.r_reason_sk
WHERE fc.total_spent > 0 
ORDER BY fc.total_spent DESC, ss.order_count DESC 
LIMIT 20;
