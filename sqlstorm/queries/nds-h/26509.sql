WITH SupplierAvgPrices AS (
    SELECT s.s_suppkey, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
FilteredSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_phone, s.s_acctbal, s.s_comment, sap.avg_supplycost
    FROM supplier s
    JOIN SupplierAvgPrices sap ON s.s_suppkey = sap.s_suppkey
    WHERE sap.avg_supplycost > (SELECT AVG(ps_supplycost) FROM partsupp)
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT fs.s_name, fs.s_address, fs.s_phone, co.c_name, co.order_count, co.total_spent
FROM FilteredSuppliers fs
JOIN CustomerOrders co ON fs.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'Germany')
ORDER BY co.total_spent DESC, fs.avg_supplycost ASC
LIMIT 10;
