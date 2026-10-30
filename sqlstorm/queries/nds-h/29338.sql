
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS brand_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        cust.c_custkey,
        cust.c_name,
        cust.order_count,
        cust.total_spent,
        ROW_NUMBER() OVER (ORDER BY cust.total_spent DESC) AS customer_rank
    FROM 
        CustomerOrders cust
    WHERE 
        cust.total_spent > 5000
)
SELECT 
    rp.p_name,
    rp.brand_rank,
    cvc.c_name,
    cvc.total_spent
FROM 
    RankedParts rp
JOIN 
    HighValueCustomers cvc ON rp.brand_rank = 1
WHERE 
    rp.total_supply_cost > (SELECT AVG(total_supply_cost) FROM RankedParts)
ORDER BY 
    rp.total_supply_cost DESC, cvc.total_spent DESC;
