
WITH SalesSummary AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk, ws_item_sk
),
CustomerAddress AS (
    SELECT
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) AS rn
    FROM
        customer_address
),
ReturnSummary AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM
        store_returns
    GROUP BY
        sr_item_sk
),
TopSales AS (
    SELECT
        ss_item_sk,
        ss_ticket_number,
        ss_sold_date_sk,
        ss_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY ss_net_profit DESC) AS top_rank
    FROM
        store_sales
    WHERE
        ss_net_profit IS NOT NULL
)
SELECT
    cs.c_first_name,
    cs.c_last_name,
    ws.ws_sold_date_sk,
    item.i_product_name,
    COALESCE(sales.total_quantity, 0) AS total_quantity,
    COALESCE(sales.total_sales, 0) AS total_sales,
    COALESCE(returns.total_returned, 0) AS total_returned,
    COALESCE(returns.total_return_amount, 0) AS total_return_amount,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM
    customer cs
JOIN
    web_sales ws ON cs.c_customer_sk = ws.ws_bill_customer_sk
JOIN
    item ON ws.ws_item_sk = item.i_item_sk
LEFT JOIN
    SalesSummary sales ON ws.ws_item_sk = sales.ws_item_sk 
    AND ws.ws_sold_date_sk = sales.ws_sold_date_sk
LEFT JOIN
    ReturnSummary returns ON ws.ws_item_sk = returns.sr_item_sk
LEFT JOIN
    CustomerAddress ca ON cs.c_current_addr_sk = ca.ca_address_sk
WHERE
    (sales_rank <= 5 OR sales_rank IS NULL)
    AND (total_returned < 10 OR total_returned IS NULL)
ORDER BY
    ws.ws_sold_date_sk DESC,
    total_sales DESC;
