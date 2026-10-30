WITH DetailedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        CONCAT('Manufacturer: ', p.p_mfgr, ', Brand: ', p.p_brand, ', Type: ', p.p_type) AS part_details
    FROM part p
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.total_orders,
        c.total_spent,
        RANK() OVER (ORDER BY c.total_spent DESC) AS rank
    FROM CustomerOrders c
)
SELECT 
    dp.part_details,
    tc.c_name,
    tc.total_orders,
    tc.total_spent
FROM DetailedParts dp
JOIN lineitem l ON l.l_partkey = dp.p_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN TopCustomers tc ON o.o_custkey = tc.c_custkey
WHERE tc.rank <= 10
ORDER BY tc.total_spent DESC, dp.p_partkey;
