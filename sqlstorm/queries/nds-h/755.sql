WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        DENSE_RANK() OVER (ORDER BY s.s_acctbal DESC) AS rank_acctbal
    FROM supplier s
    WHERE s.s_acctbal > 1000
),
OrdersWithTotal AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_orderdate
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.total_revenue) AS avg_order_value
    FROM customer c
    LEFT JOIN OrdersWithTotal o ON c.c_custkey = o.o_orderkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        cust.c_custkey, 
        cust.c_name, 
        cust.order_count,
        cust.avg_order_value
    FROM CustomerOrderStats cust
    WHERE cust.avg_order_value > 5000
)
SELECT 
    hvc.c_custkey,
    hvc.c_name,
    COALESCE(s.rank_acctbal, 0) AS supplier_rank,
    hvc.order_count,
    hvc.avg_order_value
FROM HighValueCustomers hvc
LEFT JOIN RankedSuppliers s ON hvc.c_custkey = s.s_suppkey
WHERE hvc.order_count > 2
  AND (hvc.avg_order_value IS NOT NULL OR s.rank_acctbal IS NOT NULL)
ORDER BY hvc.avg_order_value DESC, supplier_rank ASC;
