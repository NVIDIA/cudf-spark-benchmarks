
WITH RankedParts AS (
    SELECT 
        p_partkey,
        p_name,
        p_brand,
        p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p_brand ORDER BY p_retailprice DESC) AS rn
    FROM 
        part
    WHERE 
        p_retailprice IS NOT NULL AND p_size BETWEEN 10 AND 30
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
HighSpendingCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        cs.total_spent,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank
    FROM 
        customer c
    JOIN 
        CustomerStats cs ON c.c_custkey = cs.c_custkey
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerStats)
),
SupplierRegion AS (
    SELECT 
        s.s_suppkey,
        n.n_name AS nation_name,
        n.n_regionkey,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, n.n_name, n.n_regionkey
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) > 5
)
SELECT 
    p.p_name,
    p.p_retailprice,
    r.nation_name,
    r.supplied_parts,
    cc.c_name AS high_spender_name,
    cc.total_spent AS spender_amount,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_lineitem_value
FROM 
    RankedParts p
LEFT JOIN 
    SupplierRegion r ON p.p_brand = COALESCE(LEFT(r.nation_name, 1), 'Z')  
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    HighSpendingCustomers cc ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cc.c_custkey)
WHERE 
    (p.p_retailprice BETWEEN 50 AND 200 OR p.p_name LIKE '%Widget%')
    AND r.supplied_parts IS NOT NULL
GROUP BY 
    p.p_name, p.p_retailprice, r.nation_name, r.supplied_parts, cc.c_name, cc.total_spent
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 0 
    AND SUM(l.l_discount) IS NULL  
ORDER BY 
    total_lineitem_value DESC;
