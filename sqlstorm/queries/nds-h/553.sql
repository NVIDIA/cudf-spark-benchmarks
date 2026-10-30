WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_per_brand
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
), 
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.n_name AS supplier_nation,
    SUM(CASE WHEN rp.p_partkey IS NOT NULL THEN rp.p_retailprice ELSE 0 END) AS total_retail_price,
    AVG(cs.total_spent) AS avg_customer_spent,
    MAX(ss.total_parts) AS max_parts_supplied
FROM 
    RankedParts rp
LEFT JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation r ON s.s_nationkey = r.n_nationkey
LEFT JOIN 
    CustomerOrders cs ON s.s_suppkey = cs.c_custkey
LEFT JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
WHERE 
    rp.rank_per_brand <= 10 
GROUP BY 
    r.n_name
HAVING 
    SUM(CASE WHEN rp.p_partkey IS NULL THEN 1 ELSE 0 END) = 0 
ORDER BY 
    total_retail_price DESC;