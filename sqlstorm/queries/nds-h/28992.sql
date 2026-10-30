WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, s.s_name, COUNT(ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_partkey, p.p_name, s.s_name
)
SELECT 
    sd.s_name AS supplier_name,
    cd.c_name AS customer_name,
    psi.p_name AS part_name,
    sd.part_count AS total_parts_supplied,
    cd.order_count AS total_orders_placed,
    CONCAT('Supplier: ', sd.s_name, ', Customer: ', cd.c_name, ', Part: ', psi.p_name) AS summary
FROM SupplierDetails sd
JOIN CustomerOrders cd ON sd.s_nationkey = cd.c_custkey
JOIN PartSupplierInfo psi ON sd.s_suppkey = psi.p_partkey
WHERE sd.part_count > 1 AND cd.order_count > 0
ORDER BY sd.s_name, cd.c_name;
