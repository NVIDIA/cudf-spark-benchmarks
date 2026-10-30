
WITH SalesData AS (
    SELECT 
        ws.ws_ship_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        ca.ca_state
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
      AND ca.ca_state IN ('CA', 'TX', 'NY')
    GROUP BY ws.ws_ship_date_sk, ca.ca_state
),
ReturnData AS (
    SELECT 
        wr.wr_returned_date_sk,
        SUM(wr.wr_return_quantity) AS total_returned_quantity,
        SUM(wr.wr_return_amt) AS total_return_amount,
        ca.ca_state
    FROM web_returns wr
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN date_dim dd ON wr.wr_returned_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
      AND ca.ca_state IN ('CA', 'TX', 'NY')
    GROUP BY wr.wr_returned_date_sk, ca.ca_state
)
SELECT 
    sd.ws_ship_date_sk,
    sd.total_quantity,
    sd.total_sales,
    COALESCE(rd.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(rd.total_return_amount, 0) AS total_return_amount,
    sd.ca_state
FROM SalesData sd
LEFT JOIN ReturnData rd ON sd.ws_ship_date_sk = rd.wr_returned_date_sk AND sd.ca_state = rd.ca_state
ORDER BY sd.ws_ship_date_sk, sd.ca_state;
