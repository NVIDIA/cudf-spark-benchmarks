WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        COUNT(DISTINCT p.p_partkey) AS product_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS lineitem_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_orderstatus
),
NationCustomerStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(c.c_acctbal) AS total_acctbal
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    rs.n_name,
    rs.customer_count,
    rs.total_acctbal,
    ss.total_supplycost,
    ss.product_count,
    od.total_revenue,
    od.lineitem_count
FROM NationCustomerStats rs
LEFT JOIN SupplierStats ss ON ss.total_supplycost > 100000.00
LEFT JOIN OrderDetails od ON od.lineitem_count > 10
ORDER BY rs.customer_count DESC, ss.product_count DESC, od.total_revenue DESC
LIMIT 100;
