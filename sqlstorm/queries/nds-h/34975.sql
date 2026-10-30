
WITH  PriceRanking AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        DENSE_RANK() OVER (ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), 
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_availqty) AS available_quantity
    FROM partsupp ps 
    GROUP BY ps.ps_partkey
)
SELECT 
    co.c_name,
    pr.p_name,
    pr.p_retailprice,
    CASE 
        WHEN co.order_count > 5 THEN 'High Value Customer' 
        WHEN co.order_count IS NULL THEN 'No Orders' 
        ELSE 'Regular Customer' 
    END AS customer_type,
    COALESCE(sa.available_quantity, 0) AS available_quantity,
    RANK() OVER (PARTITION BY COALESCE(co.total_spent, 0) ORDER BY pr.price_rank) AS customer_rank
FROM 
    CustomerOrders co
LEFT JOIN 
    region r ON co.c_custkey = r.r_regionkey
INNER JOIN 
    supplier s ON r.r_regionkey = s.s_nationkey
LEFT JOIN 
    PriceRanking pr ON s.s_suppkey = pr.p_partkey
LEFT JOIN 
    SupplierAvailability sa ON sa.ps_partkey = pr.p_partkey
WHERE 
    pr.p_retailprice > 100 
    OR co.order_count IS NULL
ORDER BY 
    co.total_spent DESC NULLS LAST, 
    customer_rank ASC;
