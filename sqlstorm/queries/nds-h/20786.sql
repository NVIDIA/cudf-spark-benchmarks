
WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
), 
SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        CASE 
            WHEN SUM(ps.ps_supplycost) = 0 THEN NULL 
            ELSE SUM(ps.ps_supplycost) / COUNT(DISTINCT ps.ps_suppkey) 
        END AS avg_cost_per_supplier
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), 
NationCustomer AS (
    SELECT 
        n.n_nationkey, 
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        nation n 
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_nationkey
)
SELECT 
    r.r_name, 
    COALESCE(nc.customer_count, 0) AS total_customers,
    rp.p_name, 
    rp.p_retailprice AS highest_price_per_mfgr,
    ss.part_count,
    ss.total_avail_qty
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    NationCustomer nc ON n.n_nationkey = nc.n_nationkey
LEFT JOIN 
    RankedParts rp ON rp.rn = 1
LEFT JOIN 
    SupplierStats ss ON ss.part_count > 10
WHERE 
    EXISTS (SELECT 1 
            FROM lineitem l 
            WHERE l.l_orderkey IN (SELECT o.o_orderkey 
                                    FROM orders o 
                                    WHERE o.o_orderstatus = 'O'))
    AND (rp.p_retailprice > 100 OR ss.avg_supply_cost IS NOT NULL);
