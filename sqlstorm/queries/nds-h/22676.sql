
WITH RecursiveSales AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM
        customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        c.c_custkey, c.c_name
),
TopCustomerSpend AS (
    SELECT
        rs.c_custkey,
        rs.c_name,
        rs.total_sales
    FROM
        RecursiveSales rs
    WHERE
        rs.sales_rank <= 10
),
SupplierDetails AS (
    SELECT
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE
        p.p_retailprice > 100
    GROUP BY
        ps.ps_suppkey
),
EnhancedCustomerOrders AS (
    SELECT
        c.c_custkey,
        COALESCE(MAX(o.o_totalprice - o.o_totalprice * 0.15), 0) AS adjusted_total,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus = 'O'
    GROUP BY
        c.c_custkey
)
SELECT 
    tc.c_name,
    tc.total_sales,
    ec.order_count,
    ss.total_supply_cost,
    CASE 
        WHEN ec.adjusted_total IS NULL THEN 'No Orders'
        ELSE 'Orders Available'
    END AS order_status
FROM 
    TopCustomerSpend tc
FULL OUTER JOIN EnhancedCustomerOrders ec ON tc.c_custkey = ec.c_custkey
LEFT JOIN SupplierDetails ss ON tc.c_custkey = CAST(SUBSTRING(CAST(ss.ps_suppkey AS STRING), 1, 3) AS INTEGER)
WHERE 
    (tc.total_sales > 5000 OR ss.total_supply_cost IS NOT NULL)
ORDER BY 
    tc.total_sales DESC, ec.order_count DESC
LIMIT 20;
