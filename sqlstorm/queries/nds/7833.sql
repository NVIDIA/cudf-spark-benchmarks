
WITH SalesData AS (
    SELECT 
        ss.ss_sold_date_sk AS sales_date,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_sales_price) AS total_sales,
        AVG(ss.ss_net_profit) AS avg_net_profit,
        cd.cd_gender,
        ca.ca_state
    FROM store_sales ss
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY cd.cd_gender, ca.ca_state, ss.ss_sold_date_sk
),
RankedSales AS (
    SELECT 
        sales_date,
        total_quantity,
        total_sales,
        avg_net_profit,
        cd_gender,
        ca_state,
        RANK() OVER (PARTITION BY ca_state ORDER BY total_sales DESC) AS sales_rank
    FROM SalesData
)
SELECT 
    sales_date,
    total_quantity,
    total_sales,
    avg_net_profit,
    cd_gender,
    ca_state
FROM RankedSales
WHERE sales_rank <= 10
ORDER BY ca_state, total_sales DESC;
