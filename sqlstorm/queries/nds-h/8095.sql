WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ps.ps_partkey,
        ps.ps_supplycost
    FROM RankedSuppliers s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.rank <= 5
), HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderdate
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
), CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN HighValueOrders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    c.c_name AS customer_name,
    c.order_count AS number_of_orders,
    c.total_spent AS total_spent,
    s.s_name AS supplier_name,
    s.ps_supplycost AS supplier_cost
FROM CustomerOrderSummary c
JOIN TopSuppliers s ON c.order_count > 0
ORDER BY c.total_spent DESC, s.ps_supplycost ASC
LIMIT 10;
