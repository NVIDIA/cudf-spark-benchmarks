
WITH SalesData AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_paid_inc_tax) AS average_order_value,
        COUNT(DISTINCT ws_web_page_sk) AS unique_web_pages
    FROM
        web_sales
    JOIN
        customer ON ws_bill_customer_sk = c_customer_sk
    JOIN
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE
        cd_gender = 'F'
        AND ws_net_profit > 1000
        AND c_birth_year BETWEEN 1975 AND 1995
        AND ws_sold_date_sk BETWEEN 2458922 AND 2458940
    GROUP BY
        ws_bill_customer_sk
)
SELECT
    ca_city,
    COUNT(DISTINCT c_customer_sk) AS customer_count,
    SUM(total_net_profit) AS city_total_net_profit,
    AVG(total_orders) AS avg_orders_per_customer,
    AVG(average_order_value) AS avg_order_value
FROM
    SalesData
JOIN
    customer ON SalesData.ws_bill_customer_sk = c_customer_sk
JOIN
    customer_address ON c_current_addr_sk = ca_address_sk
GROUP BY
    ca_city
HAVING
    COUNT(DISTINCT c_customer_sk) > 10
ORDER BY
    city_total_net_profit DESC
LIMIT 10;
