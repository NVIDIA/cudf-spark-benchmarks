
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, p.p_partkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderstatus,
        COUNT(l.l_orderkey) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_orderstatus
)
SELECT 
    r.s_name AS supp_name,
    h.c_name AS high_value_customer,
    SUM(od.total_revenue) AS total_order_revenue,
    MAX(od.o_orderdate) AS last_order_date,
    AVG(od.item_count) AS avg_items_per_order
FROM RankedSuppliers r
FULL OUTER JOIN HighValueCustomers h ON r.s_suppkey = h.c_custkey
JOIN OrderDetails od ON od.o_orderkey = r.s_suppkey
WHERE r.total_cost IS NOT NULL OR h.customer_rank <= 10
GROUP BY r.s_name, h.c_name
HAVING SUM(od.total_revenue) > 10000
ORDER BY total_order_revenue DESC;
