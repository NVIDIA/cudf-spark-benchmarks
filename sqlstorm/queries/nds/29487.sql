
WITH AddressStats AS (
    SELECT 
        ca_state, 
        COUNT(*) AS total_addresses, 
        SUM(CASE WHEN ca_city LIKE '%town%' THEN 1 ELSE 0 END) AS town_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDetails AS (
    SELECT 
        cd_gender, 
        COUNT(DISTINCT c_customer_id) AS total_customers
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
SalesData AS (
    SELECT 
        ws_ship_date_sk, 
        SUM(ws_sales_price) AS total_sales, 
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
),
ReturnStats AS (
    SELECT 
        sr_reason_sk, 
        COUNT(*) AS total_returns, 
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_reason_sk
),
FinalBenchmark AS (
    SELECT 
        a.ca_state,
        a.total_addresses,
        a.town_count,
        a.avg_street_name_length,
        c.cd_gender,
        c.total_customers,
        s.total_sales,
        s.total_profit,
        r.total_returns,
        r.avg_return_quantity
    FROM 
        AddressStats a
    JOIN 
        CustomerDetails c ON 1=1
    JOIN 
        SalesData s ON 1=1
    JOIN 
        ReturnStats r ON 1=1
)
SELECT 
    ca_state,
    total_addresses,
    town_count,
    avg_street_name_length,
    cd_gender,
    total_customers,
    total_sales,
    total_profit,
    total_returns,
    avg_return_quantity
FROM 
    FinalBenchmark;
