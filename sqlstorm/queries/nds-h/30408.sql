WITH  CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
), 
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    ORDER BY total_spent DESC
    LIMIT 10
), 
ProductAvailability AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    cu.c_name,
    COALESCE(o.total_order_value, 0) AS total_order_value,
    pa.p_name,
    pa.total_available,
    ROW_NUMBER() OVER (ORDER BY total_order_value DESC) AS customer_rank
FROM TopCustomers cu
LEFT JOIN (
    SELECT 
        co.c_custkey,
        SUM(co.o_totalprice) AS total_order_value
    FROM CustomerOrders co
    WHERE co.order_rank = 1
    GROUP BY co.c_custkey
) o ON cu.c_custkey = o.c_custkey
JOIN ProductAvailability pa ON 1=1
WHERE pa.total_available IS NOT NULL
ORDER BY customer_rank, pa.total_available DESC
LIMIT 5;
