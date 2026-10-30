
WITH AddressCounts AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerCounts AS (
    SELECT 
        cd_marital_status,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_marital_status
),
SalesByState AS (
    SELECT 
        a.ca_state,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        customer_address a ON ws.ws_bill_addr_sk = a.ca_address_sk
    GROUP BY 
        a.ca_state
),
FinalBenchmark AS (
    SELECT 
        ac.ca_state,
        ac.address_count,
        cc.customer_count,
        COALESCE(sbs.total_sales, 0) AS total_sales
    FROM 
        AddressCounts ac
    JOIN 
        CustomerCounts cc ON 1 = 1
    LEFT JOIN 
        SalesByState sbs ON ac.ca_state = sbs.ca_state
    ORDER BY 
        ac.address_count DESC, 
        cc.customer_count DESC
)

SELECT 
    ca_state, 
    address_count, 
    customer_count, 
    total_sales
FROM 
    FinalBenchmark
WHERE 
    total_sales > 0
ORDER BY 
    address_count ASC, 
    total_sales DESC;
