WITH SupplierDetails AS (
    SELECT s.s_name, s.s_address, n.n_name AS nation_name, p.p_name, p.p_brand, p.p_type, ps.ps_availqty
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
),
DistinctCounts AS (
    SELECT DISTINCT sd.s_name, sd.nation_name, COUNT(DISTINCT co.o_orderkey) AS order_count, COUNT(DISTINCT sd.p_name) AS part_count
    FROM SupplierDetails sd
    LEFT JOIN CustomerOrders co ON sd.s_name = co.c_name
    GROUP BY sd.s_name, sd.nation_name
)
SELECT s_name, nation_name, order_count, part_count
FROM DistinctCounts
WHERE order_count > 0
ORDER BY part_count DESC, order_count DESC;
