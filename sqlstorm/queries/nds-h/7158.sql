
WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_retailprice, ps.ps_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
), HighValueOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, c.c_nationkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > (
        SELECT AVG(o1.o_totalprice) 
        FROM orders o1 
        WHERE o1.o_orderdate >= '1995-01-01'
    )
), LineItems AS (
    SELECT l.l_orderkey, l.l_quantity, l.l_extendedprice, l.l_discount, l.l_returnflag, l.l_partkey
    FROM lineitem l
    JOIN HighValueOrders hvo ON l.l_orderkey = hvo.o_orderkey
)
SELECT 
    sv.s_suppkey, 
    sv.s_name, 
    SUM(li.l_quantity) AS total_quantity, 
    SUM(li.l_extendedprice) AS total_extended_price,
    AVG(li.l_discount) AS avg_discount,
    COUNT(DISTINCT hvo.o_orderkey) AS order_count,
    r.r_name AS region
FROM SupplierParts sv
JOIN LineItems li ON sv.p_partkey = li.l_partkey
JOIN nation n ON sv.s_suppkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN HighValueOrders hvo ON li.l_orderkey = hvo.o_orderkey
WHERE li.l_returnflag = 'N'
GROUP BY sv.s_suppkey, sv.s_name, r.r_name
ORDER BY total_extended_price DESC
LIMIT 10;
