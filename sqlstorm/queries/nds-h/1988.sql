WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty) DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.order_count,
        co.total_spent
    FROM 
        customer c
    JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    WHERE 
        co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
),
PartSupply AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(ss.total_availqty, 0) AS total_available,
        ss.avg_supplycost,
        (p.p_retailprice - ss.avg_supplycost) AS price_difference
    FROM 
        part p
    LEFT JOIN 
        SupplierStats ss ON p.p_partkey = ss.s_suppkey
)
SELECT 
    psp.p_partkey,
    psp.p_name,
    psp.total_available,
    psp.price_difference,
    COALESCE(hvc.c_name, 'N/A') AS high_value_customer_name,
    hvc.order_count
FROM 
    PartSupply psp
LEFT JOIN 
    HighValueCustomers hvc ON psp.p_partkey = hvc.c_custkey
WHERE 
    psp.total_available > 0 
    AND (psp.price_difference < 5 OR psp.price_difference IS NULL)
ORDER BY 
    psp.price_difference DESC, psp.total_available ASC;
