WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= '1996-01-01' 
      AND o.o_orderdate < '1997-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        COUNT(ps.ps_partkey) AS total_parts
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 10000
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 50000
),
SupplierOrderStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(li.l_orderkey) AS total_orders,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
        AVG(li.l_quantity) AS avg_quantity
    FROM supplier s
    JOIN lineitem li ON s.s_suppkey = li.l_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
FinalJoin AS (
    SELECT 
        so.s_name,
        so.total_orders,
        so.total_sales,
        hu.total_spent
    FROM SupplierOrderStats so
    JOIN HighValueCustomers hu ON so.total_orders > 10
)
SELECT 
    fj.s_name,
    fj.total_orders,
    fj.total_sales,
    fj.total_spent,
    CASE 
        WHEN fj.total_sales > 100000 THEN 'High Performance'
        ELSE 'Normal Performance'
    END AS performance_rating
FROM FinalJoin fj
LEFT JOIN region r ON r.r_regionkey = (
    SELECT n.n_regionkey 
    FROM nation n 
    WHERE n.n_nationkey = (
        SELECT c.c_nationkey 
        FROM customer c 
        WHERE c.c_custkey = (SELECT MIN(c_custkey) FROM customer)
    )
)
WHERE r.r_name IS NOT NULL
ORDER BY fj.total_sales DESC
LIMIT 10;