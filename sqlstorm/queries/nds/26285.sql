
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        COALESCE(cd.cd_dep_count, 0) AS dependent_count,
        COALESCE(cd.cd_dep_employed_count, 0) AS employed_dependents,
        COALESCE(cd.cd_dep_college_count, 0) AS college_dependents
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesStats AS (
    SELECT 
        ss_customer_sk,
        COUNT(DISTINCT ss_ticket_number) AS total_sales,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_quantity) AS total_quantity_sold
    FROM 
        store_sales
    GROUP BY 
        ss_customer_sk
),
ReturnStats AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
FinalStats AS (
    SELECT 
        cs.full_name,
        cs.ca_city,
        cs.ca_state,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.total_net_paid, 0) AS total_net_paid,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount,
        cs.dependent_count,
        cs.employed_dependents,
        cs.college_dependents
    FROM 
        CustomerStats cs
    LEFT JOIN 
        SalesStats ss ON cs.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        ReturnStats rs ON cs.c_customer_sk = rs.sr_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    total_sales,
    total_net_paid,
    total_returns,
    total_return_amount,
    dependent_count,
    employed_dependents,
    college_dependents
FROM 
    FinalStats
WHERE 
    total_sales > 5
ORDER BY 
    total_net_paid DESC, total_sales DESC;
