
WITH  SalesCTE AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY
        ws_item_sk
),
CustomerReturns AS (
    SELECT
        sr_item_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_tax) AS total_return_tax
    FROM
        store_returns
    GROUP BY
        sr_item_sk
),
CustomerDemo AS (
    SELECT
        c.c_customer_sk,
        d.cd_gender,
        d.cd_marital_status,
        SUM(ws_net_profit) AS customer_profit
    FROM
        customer AS c
    JOIN
        customer_demographics AS d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, d.cd_gender, d.cd_marital_status
)
SELECT
    s.ws_item_sk,
    s.total_quantity,
    s.total_profit,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_return_amt, 0) AS total_return_amt,
    COALESCE(r.total_return_tax, 0) AS total_return_tax,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_profit
FROM
    SalesCTE AS s
LEFT JOIN
    CustomerReturns AS r ON s.ws_item_sk = r.sr_item_sk
JOIN
    CustomerDemo AS cd ON cd.customer_profit > 1000
ORDER BY
    s.total_profit DESC, s.ws_item_sk;
