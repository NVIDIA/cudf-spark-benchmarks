WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerSales AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    c.c_name,
    COALESCE(cs.total_sales, 0) AS total_sales,
    COALESCE(cs.order_count, 0) AS order_count,
    s.s_name,
    ss.total_supply_cost,
    ss.unique_parts,
    CASE 
        WHEN cs.total_sales IS NULL THEN 'No Sales'
        WHEN cs.total_sales > 10000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM customer c
LEFT JOIN CustomerSales cs ON c.c_custkey = cs.c_custkey
LEFT JOIN supplier s ON s.s_nationkey = c.c_nationkey
LEFT JOIN SupplierStats ss ON s.s_suppkey = ss.s_suppkey
WHERE c.c_acctbal > 1000
AND (cs.total_sales > 500 OR cs.total_sales IS NULL)
ORDER BY customer_type DESC, total_sales DESC
LIMIT 100;
