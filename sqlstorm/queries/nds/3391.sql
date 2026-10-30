
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS order_count,
        MAX(d.d_date) AS last_purchase_date
    FROM
        customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rank
    FROM
        CustomerSales
),
RelevantReturns AS (
    SELECT
        cr_returning_customer_sk,
        SUM(cr_return_amount) AS total_returned
    FROM
        catalog_returns
    GROUP BY
        cr_returning_customer_sk
),
FinalReport AS (
    SELECT
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.total_sales,
        COALESCE(rr.total_returned, 0) AS total_returned,
        tc.last_purchase_date
    FROM
        TopCustomers tc
    LEFT JOIN RelevantReturns rr ON tc.c_customer_sk = rr.cr_returning_customer_sk
    WHERE
        tc.rank <= 100
)
SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    f.total_sales,
    f.total_returned,
    f.last_purchase_date,
    CASE 
        WHEN f.total_sales - f.total_returned < 0 THEN 'Net Loss'
        ELSE 'Net Profit'
    END AS financial_status,
    CONCAT(
        'Customer ', c.c_first_name, ' ', c.c_last_name, 
        ' has total sales of ', f.total_sales, 
        ' and total returns of ', f.total_returned
    ) AS sales_summary
FROM
    FinalReport f
JOIN customer c ON f.c_customer_sk = c.c_customer_sk
WHERE
    c.c_current_addr_sk IS NOT NULL
ORDER BY
    f.total_sales DESC, f.last_purchase_date DESC;
