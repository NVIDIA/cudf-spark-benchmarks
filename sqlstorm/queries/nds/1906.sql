
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
CustomerAddress AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ReturnStatistics AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
FinalStats AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.total_orders,
        rc.total_spent,
        ca.ca_city,
        ca.ca_state,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_value, 0) AS total_return_value,
        CASE 
            WHEN rc.total_spent > 1000 THEN 'High Value'
            WHEN rc.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_segment
    FROM 
        RankedCustomers rc
    JOIN 
        CustomerAddress ca ON rc.c_customer_sk = ca.c_customer_sk
    LEFT JOIN 
        ReturnStatistics rs ON rc.c_customer_sk = rs.sr_customer_sk
)
SELECT 
    fs.c_customer_sk,
    fs.c_first_name,
    fs.c_last_name,
    fs.total_orders,
    fs.total_spent,
    fs.ca_city,
    fs.ca_state,
    fs.total_returns,
    fs.total_return_value,
    fs.customer_value_segment
FROM 
    FinalStats fs
WHERE 
    fs.total_spent > (SELECT AVG(total_spent) FROM RankedCustomers) 
    AND fs.total_orders > (SELECT AVG(total_orders) FROM RankedCustomers)
ORDER BY 
    fs.total_spent DESC, 
    fs.total_orders DESC;
