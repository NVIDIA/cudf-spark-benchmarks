
WITH  CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '1996-01-01'
),
OrderLineItems AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
),
TopCustomers AS (
    SELECT co.c_custkey, co.c_name, SUM(oli.total_amount) AS total_spent
    FROM CustomerOrders co
    JOIN OrderLineItems oli ON co.o_orderkey = oli.o_orderkey
    WHERE co.rn = 1
    GROUP BY co.c_custkey, co.c_name
    HAVING SUM(oli.total_amount) > 10000
)
SELECT tc.c_name, tc.c_custkey, COUNT(DISTINCT o.o_orderkey) AS order_count,
       MAX(oli.total_amount) AS max_order_amount, 
       SUM(oli.total_amount) AS total_spent,
       RANK() OVER (ORDER BY SUM(oli.total_amount) DESC) AS spending_rank
FROM TopCustomers tc
JOIN orders o ON tc.c_custkey = o.o_custkey
LEFT JOIN OrderLineItems oli ON o.o_orderkey = oli.o_orderkey
GROUP BY tc.c_name, tc.c_custkey
ORDER BY total_spent DESC
LIMIT 10;
