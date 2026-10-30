WITH RankedSuppliers AS (
    SELECT 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING SUM(o.o_totalprice) > 10000
),
NationSales AS (
    SELECT 
        n.n_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY n.n_name
),
CombinedData AS (
    SELECT 
        r.r_name,
        COALESCE(ns.total_sales, 0) AS total_sales,
        COALESCE(rv.total_spent, 0) AS total_spent,
        ROW_NUMBER() OVER (ORDER BY COALESCE(ns.total_sales, 0) DESC) as region_rank
    FROM region r
    LEFT JOIN NationSales ns ON r.r_name = ns.n_name
    LEFT JOIN (SELECT hc.c_custkey, hc.total_spent FROM HighValueCustomers hc) rv ON rv.c_custkey = (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_acctbal IS NOT NULL 
        ORDER BY c.c_acctbal DESC 
        LIMIT 1
    )
)
SELECT 
    cd.r_name,
    cd.total_sales,
    cd.total_spent,
    cd.region_rank,
    CASE
        WHEN cd.total_sales = 0 THEN 'No Sales'
        WHEN cd.total_spent = 0 THEN 'No High Value Customers'
        ELSE 'Active'
    END AS sales_status
FROM CombinedData cd
WHERE cd.region_rank <= 5
ORDER BY cd.total_sales DESC, cd.total_spent DESC;
