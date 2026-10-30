WITH SupplierCost AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerOrders AS (
    SELECT c.c_custkey, COUNT(DISTINCT o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
ProductSales AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY l.l_partkey
),
RankedSuppliers AS (
    SELECT sc.s_suppkey, sc.total_cost, ROW_NUMBER() OVER (ORDER BY sc.total_cost DESC) AS rank
    FROM SupplierCost sc
),
RankedCustomers AS (
    SELECT co.c_custkey, co.order_count, co.total_spent, ROW_NUMBER() OVER (ORDER BY co.total_spent DESC) AS rank
    FROM CustomerOrders co
),
RankedProducts AS (
    SELECT ps.l_partkey, ps.total_sales, ROW_NUMBER() OVER (ORDER BY ps.total_sales DESC) AS rank
    FROM ProductSales ps
)
SELECT rs.s_suppkey, rc.c_custkey, rp.l_partkey, rs.total_cost, rc.order_count, rc.total_spent, rp.total_sales
FROM RankedSuppliers rs
JOIN RankedCustomers rc ON rc.rank <= 10
JOIN RankedProducts rp ON rp.rank <= 10
WHERE rs.rank <= 10
ORDER BY rs.total_cost DESC, rc.total_spent DESC, rp.total_sales DESC;