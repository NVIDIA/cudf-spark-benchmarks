WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type
),
HighCostParts AS (
    SELECT 
        rp.p_partkey, 
        rp.p_name, 
        rp.total_cost
    FROM 
        RankedParts rp
    WHERE 
        rp.rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    co.c_name, 
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS net_sales, 
    hp.total_cost AS high_cost_part_total
FROM 
    CustomerOrders co
JOIN 
    orders o ON co.c_custkey = o.o_custkey
JOIN 
    lineitem li ON o.o_orderkey = li.l_orderkey
JOIN 
    HighCostParts hp ON li.l_partkey = hp.p_partkey
WHERE 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    co.c_name, hp.total_cost
ORDER BY 
    net_sales DESC, order_count DESC
LIMIT 10;