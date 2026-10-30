
WITH RankedWebSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rank_sales
    FROM web_sales
), 
TotalReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt) AS total_returned_amt
    FROM web_returns
    GROUP BY wr_item_sk
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city
    FROM customer c 
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE cd.cd_marital_status = 'M'
), 
SalesAndReturns AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_sales_price,
        COALESCE(t.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(t.total_returned_amt, 0) AS total_returned_amt
    FROM RankedWebSales r 
    LEFT JOIN TotalReturns t ON r.ws_item_sk = t.wr_item_sk
    WHERE r.rank_sales = 1
)

SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.ca_city,
    COALESCE(sa.ws_sales_price, 0) AS highest_sales_price,
    sa.total_returned_quantity,
    sa.total_returned_amt
FROM CustomerDetails cs
LEFT JOIN SalesAndReturns sa ON cs.c_customer_sk = sa.ws_order_number
WHERE sa.total_returned_quantity > 5 
  OR cs.ca_city IS NOT NULL
ORDER BY cs.c_last_name, cs.c_first_name;
