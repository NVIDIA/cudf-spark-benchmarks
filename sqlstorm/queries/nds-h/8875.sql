WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS rnk
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderstatus = 'O'
), HighValueLineItems AS (
    SELECT li.l_orderkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_value
    FROM lineitem li
    JOIN RankedOrders ro ON li.l_orderkey = ro.o_orderkey
    WHERE ro.rnk <= 10
    GROUP BY li.l_orderkey
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '1997-01-01'
    GROUP BY c.c_custkey, c.c_name
), CombinedData AS (
    SELECT ho.l_orderkey, ho.total_value, co.order_count, co.total_spent
    FROM HighValueLineItems ho
    JOIN CustomerOrders co ON ho.l_orderkey = co.c_custkey
)
SELECT co.c_custkey, co.c_name, cd.total_value, cd.order_count, cd.total_spent
FROM CustomerOrders co
JOIN CombinedData cd ON co.c_custkey = cd.l_orderkey
ORDER BY cd.total_spent DESC, cd.total_value DESC;