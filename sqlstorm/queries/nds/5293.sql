
WITH CustomerCounts AS (
    SELECT 
        ca_state, 
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(cd_dep_count) AS total_dependencies,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_address AS ca
    JOIN customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY ca_state
),
SalesData AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity
    FROM web_sales AS ws
    JOIN date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
StoreSalesData AS (
    SELECT 
        s.s_store_name,
        SUM(ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM store_sales AS ss
    JOIN store AS s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY s.s_store_name
)
SELECT 
    cc.ca_state,
    cc.customer_count,
    cc.total_dependencies,
    cc.avg_purchase_estimate,
    sd.d_year,
    sd.d_month_seq,
    sd.total_sales,
    sd.total_quantity,
    ssd.s_store_name,
    ssd.total_store_sales,
    ssd.total_transactions
FROM CustomerCounts AS cc
JOIN SalesData AS sd ON cc.customer_count > 1000
LEFT JOIN StoreSalesData AS ssd ON sd.total_sales > 10000
ORDER BY cc.ca_state, sd.d_year, sd.d_month_seq, ssd.total_store_sales DESC
LIMIT 100;
