
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
CustomerAddresses AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        c.c_customer_sk
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
),
SalesSummary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT 
                d.d_date_sk 
            FROM 
                date_dim d 
            WHERE 
                d.d_year = 2023
        )
    GROUP BY 
        ws.ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ss.total_profit,
        ss.total_sales,
        ss.total_quantity
    FROM 
        RankedCustomers rc
    LEFT JOIN 
        CustomerAddresses ca ON rc.c_customer_sk = ca.c_customer_sk
    LEFT JOIN 
        SalesSummary ss ON rc.c_customer_sk = ss.ws_bill_customer_sk
    WHERE 
        rc.purchase_rank = 1 OR ss.total_profit > 1000
)
SELECT 
    *,
    COALESCE(total_profit, 0) AS adjusted_profit,
    CASE 
        WHEN total_sales IS NULL THEN 'No Sales'
        ELSE CAST(total_sales AS STRING)
    END AS sales_status
FROM 
    FinalReport
WHERE 
    ca_city IS NOT NULL
ORDER BY 
    adjusted_profit DESC, 
    c_last_name ASC;
