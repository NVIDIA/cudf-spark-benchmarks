
WITH RankedCustomers AS (
    SELECT c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name,
           cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate,
           RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as purchase_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT ws.ws_bill_customer_sk, SUM(ws.ws_sales_price) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
      AND ws.ws_sold_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY ws.ws_bill_customer_sk
),
AddressDetails AS (
    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state, COUNT(c.c_customer_sk) AS num_customers
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
),
ReturnsSummary AS (
    SELECT sr.sr_customer_sk, SUM(sr.sr_return_amt) AS total_returned,
           COUNT(DISTINCT sr.sr_ticket_number) AS return_count
    FROM store_returns sr
    GROUP BY sr.sr_customer_sk
),
FinalReport AS (
    SELECT rc.c_customer_id, rc.c_first_name, rc.c_last_name, rc.purchase_rank,
           sd.total_sales, sd.order_count, ad.num_customers,
           COALESCE(rs.total_returned, 0) AS total_returned,
           CASE 
               WHEN sd.total_sales > 1000 THEN 'High Value'
               WHEN sd.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
               ELSE 'Low Value'
           END AS value_category
    FROM RankedCustomers rc
    LEFT JOIN SalesData sd ON rc.c_customer_sk = sd.ws_bill_customer_sk
    LEFT JOIN AddressDetails ad ON rc.c_customer_sk = ad.ca_address_sk
    LEFT JOIN ReturnsSummary rs ON rc.c_customer_sk = rs.sr_customer_sk
    WHERE rc.purchase_rank <= 10
      AND ad.num_customers > 5
)
SELECT fr.*, 
       CASE
           WHEN fr.total_returned IS NULL OR fr.total_returned = 0 THEN 'No Returns'
           ELSE 'Has Returns'
       END AS return_status
FROM FinalReport fr
WHERE (fr.total_sales > 0 OR fr.order_count > 0)
ORDER BY fr.total_sales DESC, fr.purchase_rank;
