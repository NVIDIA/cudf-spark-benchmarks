WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation, s.s_address, s.s_phone, s.s_acctbal, 
           SUM(ps.ps_availqty) AS total_avail_qty,
           COUNT(DISTINCT p.p_partkey) AS parts_supplied,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name, s.s_address, s.s_phone, s.s_acctbal
),
OrderStats AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_orders, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT sd.s_name, sd.nation, sd.s_address, sd.s_phone, sd.s_acctbal, sd.total_avail_qty, 
       sd.parts_supplied, sd.total_supply_cost, os.total_orders, os.order_count
FROM SupplierDetails sd
LEFT JOIN OrderStats os ON sd.s_suppkey = os.c_custkey
WHERE LENGTH(sd.s_name) > 10 AND sd.total_supply_cost > 1000
ORDER BY sd.total_supply_cost DESC, os.total_orders DESC;
