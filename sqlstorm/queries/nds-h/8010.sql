
WITH SupplierDetails AS (
    SELECT s.s_name, s.s_acctbal, n.n_name AS nation_name, r.r_name AS region_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE s.s_acctbal > 5000
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice > 1000
),
LineItemDetails AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price
    FROM lineitem l
    GROUP BY l.l_orderkey
)

SELECT 
    sd.s_name, 
    sd.nation_name, 
    sd.region_name, 
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    AVG(co.o_totalprice) AS avg_order_value,
    SUM(l.total_line_price) AS total_line_item_value
FROM SupplierDetails sd
LEFT JOIN CustomerOrders co ON sd.s_name = (
    SELECT s.s_name 
    FROM partsupp ps 
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey 
    WHERE ps.ps_partkey IN (
        SELECT p.p_partkey 
        FROM part p 
        WHERE p.p_size < 20
    )
    LIMIT 1
) 
LEFT JOIN LineItemDetails l ON co.o_orderkey = l.l_orderkey
GROUP BY sd.s_name, sd.nation_name, sd.region_name
HAVING COUNT(DISTINCT co.o_orderkey) > 5
ORDER BY total_orders DESC, avg_order_value DESC;
