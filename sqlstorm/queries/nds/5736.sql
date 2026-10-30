WITH TotalSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458849 AND 2459513 
    GROUP BY 
        ws_bill_customer_sk
), 
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_dep_count,
        cd_dep_employed_count
    FROM 
        customer_demographics
    WHERE 
        cd_demo_sk IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales WHERE ws_net_profit > 100)
), 
CustomerAddress AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country
    FROM 
        customer_address
    WHERE 
        ca_city IN ('New York', 'Los Angeles', 'Chicago')
), 
RankedSales AS (
    SELECT 
        ts.ws_bill_customer_sk,
        ts.total_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY ts.total_profit DESC) AS city_rank
    FROM 
        TotalSales ts
    JOIN 
        CustomerDemographics cd ON ts.ws_bill_customer_sk = cd.cd_demo_sk
    JOIN 
        CustomerAddress ca ON ts.ws_bill_customer_sk = ca.ca_address_sk
)
SELECT 
    city_rank,
    ws_bill_customer_sk,
    total_profit,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_dep_count,
    cd_dep_employed_count,
    ca_city,
    ca_state
FROM 
    RankedSales
WHERE 
    city_rank <= 3
ORDER BY 
    ca_city, total_profit DESC;