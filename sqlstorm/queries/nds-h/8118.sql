WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank_by_balance
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 10000
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        n.n_name AS nation
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE c.c_acctbal > 50000
),
AggregatedLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(*) AS line_item_count
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    r.s_name AS supplier_name,
    r.s_acctbal,
    h.c_name AS customer_name,
    h.nation AS customer_nation,
    a.total_sales,
    a.line_item_count
FROM RankedSuppliers r
JOIN HighValueCustomers h ON r.rank_by_balance <= 3
JOIN orders o ON h.c_custkey = o.o_custkey
JOIN AggregatedLineItems a ON o.o_orderkey = a.l_orderkey
WHERE a.total_sales > 100000
ORDER BY r.s_acctbal DESC, a.total_sales DESC;
