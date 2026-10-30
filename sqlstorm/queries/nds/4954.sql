
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY c.c_current_addr_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk
),
TopCustomers AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales
    FROM
        CustomerSales cs
    WHERE
        cs.sales_rank <= 5
),
ReturnsData AS (
    SELECT
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt) AS total_returned,
        COUNT(sr.sr_ticket_number) AS return_count
    FROM
        store_returns sr
    GROUP BY
        sr.sr_customer_sk
),
NetCustomerTransactions AS (
    SELECT
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        COALESCE(tc.total_sales, 0) - COALESCE(rd.total_returned, 0) AS net_sales
    FROM
        TopCustomers tc
    LEFT JOIN
        ReturnsData rd ON tc.c_customer_sk = rd.sr_customer_sk
)
SELECT
    nct.c_customer_sk,
    nct.c_first_name,
    nct.c_last_name,
    nct.net_sales,
    CASE 
        WHEN nct.net_sales > 1000 THEN 'High Value Customer'
        WHEN nct.net_sales > 500 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_segment
FROM
    NetCustomerTransactions nct
ORDER BY
    nct.net_sales DESC;
