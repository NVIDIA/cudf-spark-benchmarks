
WITH  CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM CustomerOrders c
    JOIN orders o ON c.o_orderkey = o.o_orderkey
    WHERE c.order_rank <= 5 
    GROUP BY c.c_custkey, c.c_name
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name
    FROM SupplierDetails s
    WHERE s.supplier_value > (
        SELECT AVG(supplier_value)
        FROM SupplierDetails
    )
),
OrderLineStats AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS returns_count
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT DISTINCT 
    c.c_name AS customer_name,
    SUM(o.o_totalprice) AS total_order_value,
    COALESCE(NULLIF(s.s_name, ''), 'Unknown Supplier') AS supplier_name,
    ol.revenue,
    ol.returns_count
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN HighValueSuppliers s ON ps.ps_suppkey = s.s_suppkey
JOIN OrderLineStats ol ON ol.l_orderkey = o.o_orderkey
WHERE c.c_acctbal > (
        SELECT AVG(c2.c_acctbal)
        FROM customer c2
        WHERE c2.c_mktsegment = c.c_mktsegment
    )
GROUP BY c.c_name, s.s_name, ol.revenue, ol.returns_count
HAVING SUM(o.o_totalprice) > 10000
ORDER BY total_order_value DESC
LIMIT 50;
