WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, COUNT(DISTINCT ps.ps_partkey) AS part_count,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
SalesBySupplier AS (
    SELECT s.s_suppkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales_by_supplier
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.total_sales,
    r.rank,
    ss.s_name,
    ss.part_count,
    ss.total_supply_cost,
    cv.c_name,
    cv.total_spent,
    COALESCE(sbs.total_sales_by_supplier, 0) AS total_sales_by_supplier
FROM RankedOrders r
LEFT JOIN SupplierStats ss ON r.o_orderkey = ss.s_suppkey
LEFT JOIN HighValueCustomers cv ON ss.part_count > 5 AND cv.total_spent > 5000
LEFT JOIN SalesBySupplier sbs ON ss.s_suppkey = sbs.s_suppkey
WHERE r.rank <= 10
ORDER BY r.total_sales DESC, ss.total_supply_cost ASC;