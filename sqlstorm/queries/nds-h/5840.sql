
WITH CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, c.total_spent, ROW_NUMBER() OVER (ORDER BY c.total_spent DESC) AS rank
    FROM CustomerOrders c
    WHERE c.total_spent > 10000
),
HighValueItems AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
)
SELECT tc.c_name AS top_customer, hvi.p_name AS high_value_item, hvi.total_supply_value
FROM TopCustomers tc
JOIN HighValueItems hvi ON tc.rank <= 10
ORDER BY hvi.total_supply_value DESC, tc.total_spent DESC;
