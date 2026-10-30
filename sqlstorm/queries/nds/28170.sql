
WITH AddressComponents AS (
    SELECT 
        ca_address_sk,
        CONCAT(
            COALESCE(ca_street_number, ''), ' ', 
            COALESCE(ca_street_name, ''), ' ', 
            COALESCE(ca_street_type, ''), ', ', 
            COALESCE(ca_city, ''), ', ', 
            COALESCE(ca_state, ''), ' ', 
            COALESCE(ca_zip, ''), ' - ', 
            COALESCE(ca_country, '')
        ) AS full_address
    FROM customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count,
        CONCAT(cd_gender, ' - ', cd_marital_status, ' - ', cd_education_status) AS demographic_profile
    FROM customer_demographics
),
DateDimensions AS (
    SELECT 
        d_date_sk,
        d_date,
        d_day_name,
        d_month_seq,
        d_year,
        CONCAT(d_day_name, ', ', d_month_seq, ' ', d_year) AS formatted_date
    FROM date_dim
),
AggregatedData AS (
    SELECT 
        ca.ca_address_sk,
        ca.full_address,
        cd.demographic_profile,
        dd.formatted_date,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM AddressComponents ca
    JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN DateDimensions dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        ca.ca_address_sk, 
        ca.full_address, 
        cd.demographic_profile, 
        dd.formatted_date
)
SELECT 
    full_address,
    demographic_profile,
    formatted_date,
    total_orders,
    total_profit,
    CASE 
        WHEN total_profit > 1000 THEN 'High Profit'
        WHEN total_profit BETWEEN 500 AND 1000 THEN 'Moderate Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM AggregatedData
ORDER BY total_profit DESC;
