
WITH SalesData AS (
    SELECT
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        cd.cd_gender,
        ca.ca_state
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE
        ws.ws_sold_date_sk IN (
            SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 3
        )
),
AggregateData AS (
    SELECT
        sd.ca_state,
        sd.cd_gender,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY sd.ca_state ORDER BY SUM(sd.ws_net_profit) DESC) AS profit_rank
    FROM
        SalesData sd
    GROUP BY
        sd.ca_state, sd.cd_gender
),
FilteredData AS (
    SELECT
        ad.ca_state,
        ad.cd_gender,
        ad.total_quantity,
        ad.total_profit
    FROM
        AggregateData ad
    WHERE
        ad.profit_rank <= 3
)

SELECT
    fd.ca_state,
    fd.cd_gender,
    fd.total_quantity,
    fd.total_profit,
    CASE 
        WHEN fd.total_profit IS NULL THEN 'No Profit Recorded'
        WHEN fd.total_profit > 1000 THEN 'High Profit'
        ELSE 'Standard Profit'
    END AS profit_level
FROM
    FilteredData fd
ORDER BY
    fd.ca_state, fd.total_profit DESC
;
