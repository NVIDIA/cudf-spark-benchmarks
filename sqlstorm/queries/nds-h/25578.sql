WITH RankedLines AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l_tax,
        l_returnflag,
        l_linestatus,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS rn,
        RANK() OVER (PARTITION BY l.l_orderkey, l.l_returnflag ORDER BY l.l_quantity DESC) AS rnk_quantity
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
PartSupplierCount AS (
    SELECT 
        ps.ps_partkey,
        COUNT(*) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        ps.supplier_count
    FROM 
        part p
    JOIN 
        PartSupplierCount ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > (
            SELECT AVG(p2.p_retailprice) FROM part p2
            WHERE p2.p_size BETWEEN 10 AND 30
        ) AND 
        ps.supplier_count > 5
)
SELECT 
    rl.l_orderkey, 
    rl.l_partkey, 
    rl.l_quantity, 
    rp.p_name, 
    rl.rn, 
    rl.rnk_quantity
FROM 
    RankedLines rl
JOIN 
    FilteredParts rp ON rl.l_partkey = rp.p_partkey
WHERE 
    rl.rnk_quantity = 1
ORDER BY 
    rl.l_orderkey, 
    rl.l_partkey;