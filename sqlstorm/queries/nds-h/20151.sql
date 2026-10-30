
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 15
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        AVG(s.s_acctbal) AS avg_acct_bal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
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
RegionNations AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    rp.p_name,
    rp.p_retailprice,
    ss.total_supply_cost,
    cs.order_count,
    cs.total_spent,
    rn.nation_count
FROM 
    RankedParts rp
LEFT JOIN 
    SupplierStats ss ON rp.p_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_suppkey IN (
            SELECT s.s_suppkey 
            FROM supplier s 
            WHERE s.s_acctbal > 1000
        )
    )
LEFT JOIN 
    CustomerOrders cs ON cs.order_count > 0
FULL OUTER JOIN 
    RegionNations rn ON rn.nation_count IS NOT NULL
WHERE 
    rp.price_rank <= 5
    AND (ss.total_supply_cost IS NULL OR ss.total_supply_cost < 500)
ORDER BY 
    rp.p_retailprice DESC
LIMIT 10 OFFSET 10;
