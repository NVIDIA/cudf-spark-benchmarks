WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_nationkey
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
),
OrderLineItems AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY o.o_orderkey
)
SELECT 
    sd.s_name, 
    sd.nation_name, 
    COUNT(DISTINCT co.c_custkey) AS number_of_customers,
    SUM(oli.total_order_value) AS total_value_of_orders,
    sd.avg_supply_cost
FROM SupplierDetails sd
JOIN partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN CustomerOrders co ON ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#23' LIMIT 1)
JOIN OrderLineItems oli ON co.o_orderkey = oli.o_orderkey
GROUP BY sd.s_name, sd.nation_name, sd.avg_supply_cost
ORDER BY total_value_of_orders DESC, number_of_customers DESC
LIMIT 10;