WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_returned_date_sk) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM store_returns
    WHERE sr_returned_date_sk IS NOT NULL
    GROUP BY sr_customer_sk
),
ItemSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid_inc_tax) AS total_sales_value
    FROM web_sales
    GROUP BY ws_item_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_value, 0) AS total_return_value
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE c.c_birth_year < 1980 
),
TopItems AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        isales.total_quantity_sold,
        isales.total_sales_value
    FROM item i
    JOIN ItemSales isales ON i.i_item_sk = isales.ws_item_sk
    WHERE isales.total_quantity_sold > 100 
),
ReturnedItems AS (
    SELECT 
        si.si_item_sk,
        SUM(si.si_return_quantity) AS total_returned_quantity,
        SUM(si.si_return_amount) AS total_returned_value
    FROM (
        SELECT 
            sr_item_sk AS si_item_sk,
            sr_return_quantity AS si_return_quantity,
            sr_return_amt_inc_tax AS si_return_amount
        FROM store_returns
        UNION ALL
        SELECT 
            wr_item_sk AS si_item_sk,
            wr_return_quantity AS si_return_quantity,
            wr_return_amt_inc_tax AS si_return_amount
        FROM web_returns
    ) si
    GROUP BY si.si_item_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.cd_marital_status,
    SUM(ri.total_returned_quantity) AS total_returned_quantity,
    SUM(ri.total_returned_value) AS total_returned_value,
    i.i_item_desc,
    i.i_current_price
FROM HighValueCustomers c
LEFT JOIN ReturnedItems ri ON c.c_customer_sk = ri.si_item_sk
JOIN TopItems i ON ri.si_item_sk = i.i_item_sk
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    c.cd_gender, 
    c.cd_marital_status, 
    i.i_item_desc, 
    i.i_current_price
HAVING SUM(ri.total_returned_quantity) > 0
ORDER BY total_returned_value DESC
LIMIT 10;